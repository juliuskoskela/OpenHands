{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.openhands;

  # Create configuration file
  configFile = pkgs.writeText "openhands-config.toml" ''
    [core]
    workspace_base = "${cfg.workspaceDir}"
    persist_sandbox = ${if cfg.persistSandbox then "true" else "false"}
    run_as_openhands = ${if cfg.runAsOpenHands then "true" else "false"}
    sandbox_container_image = "${cfg.sandboxImage}"

    ${optionalString (cfg.model != null) ''
    [llm]
    model = "${cfg.model}"
    ''}

    ${optionalString (cfg.apiKey != null) ''
    api_key = "${cfg.apiKey}"
    ''}

    ${optionalString (cfg.githubToken != null) ''
    [github]
    token = "${cfg.githubToken}"
    ''}

    ${optionalString (cfg.gitlabToken != null) ''
    [gitlab]
    token = "${cfg.gitlabToken}"
    ''}

    ${optionalString (cfg.giteaToken != null && cfg.giteaHost != null) ''
    [gitea]
    token = "${cfg.giteaToken}"
    host = "${cfg.giteaHost}"
    ''}

    ${cfg.extraConfig}
  '';

  # Environment variables
  envVars = {
    OPENHANDS_CONFIG_FILE = configFile;
    WORKSPACE_BASE = cfg.workspaceDir;
  } // optionalAttrs (cfg.githubToken != null) {
    GITHUB_TOKEN = cfg.githubToken;
  } // optionalAttrs (cfg.gitlabToken != null) {
    GITLAB_TOKEN = cfg.gitlabToken;
  } // optionalAttrs (cfg.giteaToken != null) {
    GITEA_TOKEN = cfg.giteaToken;
  } // optionalAttrs (cfg.giteaHost != null) {
    GITEA_BASE_URL = cfg.giteaHost;
  } // cfg.extraEnv;

in {
  options.services.openhands = {
    enable = mkEnableOption "OpenHands AI software engineer";

    package = mkOption {
      type = types.package;
      default = pkgs.openhands or (throw "OpenHands package not available. Please add the OpenHands flake to your system inputs.");
      description = "The OpenHands package to use.";
    };

    user = mkOption {
      type = types.str;
      default = "openhands";
      description = "User account under which OpenHands runs.";
    };

    group = mkOption {
      type = types.str;
      default = "openhands";
      description = "Group under which OpenHands runs.";
    };

    port = mkOption {
      type = types.port;
      default = 3000;
      description = "Port on which OpenHands listens.";
    };

    host = mkOption {
      type = types.str;
      default = "127.0.0.1";
      description = "Host address on which OpenHands listens. Use 0.0.0.0 to listen on all interfaces.";
    };

    workspaceDir = mkOption {
      type = types.path;
      default = "/var/lib/openhands/workspace";
      description = "Directory where OpenHands stores workspace files.";
    };

    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/openhands";
      description = "Directory where OpenHands stores its data.";
    };

    model = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "gpt-4";
      description = "Default LLM model to use.";
    };

    apiKey = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "API key for the LLM provider. Consider using a secrets management solution.";
    };

    githubToken = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "GitHub personal access token for repository access.";
    };

    gitlabToken = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "GitLab personal access token for repository access.";
    };

    giteaToken = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Gitea personal access token for repository access.";
    };

    giteaHost = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "https://gitea.example.com";
      description = "Gitea instance base URL.";
    };

    persistSandbox = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to persist the sandbox container between sessions.";
    };

    runAsOpenHands = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to run as the openhands user inside the sandbox.";
    };

    sandboxImage = mkOption {
      type = types.str;
      default = "ghcr.io/all-hands-ai/runtime:0.42.0-nikolaik";
      description = "Docker image to use for the sandbox environment.";
    };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      description = "Additional configuration to append to the config file.";
    };

    extraEnv = mkOption {
      type = types.attrsOf types.str;
      default = {};
      description = "Additional environment variables to set.";
    };

    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to open the firewall for the OpenHands port.";
    };
  };

  config = mkIf cfg.enable {
    # Create user and group
    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
      home = cfg.dataDir;
      createHome = true;
      description = "OpenHands service user";
    };

    users.groups.${cfg.group} = {};

    # Create directories
    systemd.tmpfiles.rules = [
      "d '${cfg.dataDir}' 0755 ${cfg.user} ${cfg.group} - -"
      "d '${cfg.workspaceDir}' 0755 ${cfg.user} ${cfg.group} - -"
    ];

    # Systemd service
    systemd.services.openhands = {
      description = "OpenHands AI Software Engineer";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      environment = envVars;

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = cfg.dataDir;
        ExecStart = "${cfg.package}/bin/openhands --host ${cfg.host} --port ${toString cfg.port}";
        Restart = "always";
        RestartSec = 10;

        # Security settings
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ReadWritePaths = [ cfg.dataDir cfg.workspaceDir ];

        # Allow access to Docker socket if needed
        SupplementaryGroups = [ "docker" ];
      };

      # Ensure Docker is available if using default sandbox
      requires = mkIf (hasInfix "docker" cfg.sandboxImage || hasInfix "ghcr.io" cfg.sandboxImage) [ "docker.service" ];
      after = mkIf (hasInfix "docker" cfg.sandboxImage || hasInfix "ghcr.io" cfg.sandboxImage) [ "docker.service" ];
    };

    # Open firewall if requested
    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [ cfg.port ];

    # Ensure Docker is enabled if using Docker-based sandbox
    virtualisation.docker.enable = mkIf (hasInfix "docker" cfg.sandboxImage || hasInfix "ghcr.io" cfg.sandboxImage) true;

    # Add user to docker group if Docker is enabled
    users.users.${cfg.user}.extraGroups = mkIf config.virtualisation.docker.enable [ "docker" ];
  };
}
