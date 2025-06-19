{
  description = "OpenHands: Code Less, Make More - A Nix flake for reproducible development and deployment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    poetry2nix = {
      url = "github:nix-community/poetry2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];

      perSystem = { config, self', inputs', pkgs, system, ... }: {
        packages = {
          # Default package is the OpenHands launcher
          default = self'.packages.openhands;

          # OpenHands launcher - improved version with poetry2nix roadmap
          openhands = pkgs.writeShellScriptBin "openhands" ''
            echo "🚀 OpenHands Nix Launcher"
            echo ""
            echo "Current status: Hybrid Nix + Poetry setup"
            echo "Roadmap: Full poetry2nix integration (in progress)"
            echo ""
            echo "For best compatibility, use the development environment:"
            echo "  nix develop"
            echo "  poetry install"
            echo "  poetry run python -m openhands.server"
            echo ""
            echo "This provides:"
            echo "  ✅ Reproducible system dependencies (via Nix)"
            echo "  ✅ Exact Python dependencies (via Poetry)"
            echo "  🔄 Working towards: Full Nix dependency management (via poetry2nix)"
            echo ""
          '';
        };

        # Development shell - back to working version
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # Python development
            python312
            poetry

            # Node.js for frontend
            nodejs_20

            # Development tools
            git
            docker
            pre-commit

            # Linting and formatting
            black
            ruff
            mypy

            # Other useful tools
            curl
            jq
          ];

          shellHook = ''
            echo "🚀 Welcome to OpenHands development environment!"
            echo "📦 Python $(python --version)"
            echo "📦 Node.js $(node --version)"
            echo "📦 npm $(${pkgs.nodejs_20}/bin/npm --version)"
            echo ""
            echo "Current setup: Hybrid Nix + Poetry (working towards poetry2nix)"
            echo ""
            echo "Available commands:"
            echo "  poetry install - Install Python dependencies"
            echo "  poetry run python -m openhands.server - Run OpenHands"
            echo "  cd frontend && ${pkgs.nodejs_20}/bin/npm install - Install frontend dependencies"
            echo "  pre-commit install - Set up git hooks"
            echo "  nix run .#fmt - Format code"
            echo ""
            echo "Next steps for full Nixification:"
            echo "  🔄 poetry2nix integration (resolving dependency conflicts)"
            echo "  🔄 Frontend build pipeline"
            echo "  🔄 Container generation"
            echo ""

            # Set up environment variables
            export PYTHONPATH="$PWD:$PYTHONPATH"
          '';
        };

        # Apps for easy running
        apps = {
          default = self'.apps.openhands;

          openhands = {
            type = "app";
            program = "${self'.packages.openhands}/bin/openhands";
          };

          # Formatter app
          fmt = {
            type = "app";
            program = "${pkgs.black}/bin/black";
          };
        };

        # Checks for CI
        checks = {
          # Check that packages build
          build-check = self'.packages.openhands;

          # Check formatting (disabled for now)
          # format-check = pkgs.runCommand "format-check" {
          #   buildInputs = with pkgs; [ black ruff ];
          # } ''
          #   cd ${./.}
          #   black --check .
          #   ruff check .
          #   touch $out
          # '';
        };
      };

      # NixOS module (will be implemented in a separate file)
      flake.nixosModules.openhands = import ./nix/modules/openhands.nix;
    };
}
