{
  description = "OpenHands: Code Less, Make More - A Nix flake for reproducible development and deployment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];

      perSystem = { config, self', inputs', pkgs, system, ... }: {
        packages = {
          # Default package will be the combined OpenHands application
          default = self'.packages.openhands;

          # Development launcher script
          openhands = pkgs.writeShellScriptBin "openhands" ''
            echo "🚀 OpenHands Development Launcher"
            echo "This is a development version. For production, use poetry or pip install."
            echo ""
            echo "To run OpenHands in development mode:"
            echo "1. nix develop"
            echo "2. poetry install"
            echo "3. poetry run python -m openhands.server"
            echo ""
            echo "Or use the development environment directly:"
            echo "nix develop --command bash -c 'poetry install && poetry run python -m openhands.server'"
          '';
        };

        # Development shell
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

            # Testing
            python312Packages.pytest

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
            echo "Available commands:"
            echo "  poetry install    - Install Python dependencies"
            echo "  cd frontend && ${pkgs.nodejs_20}/bin/npm install - Install frontend dependencies"
            echo "  pre-commit install - Set up git hooks"
            echo "  nix run .#openhands - Run OpenHands"
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
