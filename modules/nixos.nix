{flake}: ({
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.degoog;
in {
  options = {
    services.degoog = {
      enable = lib.mkEnableOption "Enable Degoog, a Search engine aggregator with a comprehensive plugin/extension system";

      package = lib.mkPackageOption flake.packages.${pkgs.system} "degoog" {};

      port = lib.mkOption {
        type = lib.types.ints.u16;
        default = 4444;
        description = "Port to run the service on";
      };

      enableWizard = lib.mkEnableOption "Enable startup wizard";

      distrustProxy = lib.mkEnableOption "Trust incoming reverse proxy connections";

      publicInstance = lib.mkEnableOption "Whether this is a public Degoog instance";

      user = lib.mkOption {
        type = lib.types.str;
        default = "degoog";
        description = "User account under which Degoog runs.";
      };

      group = lib.mkOption {
        type = lib.types.str;
        default = "degoog";
        description = "Group under which Degoog runs.";
      };

      dataDir = lib.mkOption {
        type = lib.types.path;
        default = "/var/lib/degoog";
        description = ''
          Base data directory.
        '';
      };

      environmentFile = lib.mkOption {
        type = lib.types.path;
        description = ''
          Path to environment file
          Used to for example set the password to the settings page:
          ```
            DEGOOG_SETTINGS_PASSWORDS='password'
          ```
          For more options please refer to https://degoog-org.github.io/docs/env.html
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    systemd = {
      tmpfiles.settings.degoog = {
        ${cfg.dataDir}."d" = {
          mode = "700";
          inherit (cfg) user group;
        };
      };

      services.degoog = {
        description = "Search engine aggregator with a comprehensive plugin/extension system";
        after = ["network-online.target"];
        wants = ["network-online.target"];
        wantedBy = ["multi-user.target"];

        path = with pkgs; [git curl-impersonate];

        environment = {
          DEGOOG_PORT = toString cfg.port;
          DEGOOG_DATA_DIR = toString cfg.dataDir;
          DEGOOG_WIZARD =
            if cfg.enableWizard
            then "true"
            else "false";
          DEGOOG_DISTRUST_PROXY = toString cfg.distrustProxy;
          DEGOOG_PUBLIC_INSTANCE = toString cfg.publicInstance;
          BUN_INSTALL_CACHE_DIR = "/tmp/bun";
          BUN_RUNTIME_TRANSPILER_CACHE_PATH = "0";
        };

        # Service config mostly copied from the Jellyfin service file: https://github.com/NixOS/nixpkgs/blob/nixos-unstable/nixos/modules/services/misc/jellyfin.nix
        serviceConfig = {
          Type = "simple";

          User = cfg.user;
          Group = cfg.group;
          UMask = "0077";

          WorkingDirectory = cfg.dataDir;
          ExecStart = lib.getExe cfg.package;
          Restart = "on-failure";
          TimeoutSec = 15;

          NoNewPrivileges = true;
          SystemCallArchitectures = "native";
          RestrictAddressFamilies = [
            "AF_INET"
            "AF_INET6"
          ];
          RestrictNamespaces = !config.boot.isContainer;
          RestrictRealtime = true;
          RestrictSUIDSGID = true;
          ProtectControlGroups = !config.boot.isContainer;
          ProtectSystem = "strict";
          ProtectHostname = true;
          ProtectKernelLogs = !config.boot.isContainer;
          ProtectKernelModules = !config.boot.isContainer;
          ProtectKernelTunables = !config.boot.isContainer;
          ProtectClock = true;
          ProtectProc = "noaccess";
          ProcSubset = "pid";
          ProtectHome = true;
          CapabilityBoundingSet = [
            "~CAP_NET_(BIND_SERVICE|BROADCAST|RAW)"
            "~CAP_AUDIT_*"
            "~CAP_SYS_ADMIN"
            "~CAP_NET_ADMIN"
            "~CAP_SYS_PACCT"
            "~CAP_SYS_PTRACE"
            "~CAP_KILL"
            "~CAP_(DAC_*|FOWNER|IPC_OWNER)"
            "~CAP_LINUX_IMMUTABLE"
            "~CAP_IPC_LOCK"
            "~CAP_BPF"
            "~CAP_SYS_TTY_CONFIG"
            "~CAP_SYS_BOOT"
            "~CAP_SYS_CHROOT"
            "~CAP_BLOCK_SUSPEND"
            "~CAP_LEASE"
            "~CAP_(CHOWN|FSETID|SETFCAP)"
            "~CAP_SET(UID|GID|PCAP)"
            "~CAP_MAC_*"
          ];
          LockPersonality = true;
          PrivateTmp = !config.boot.isContainer;
          PrivateDevices = true;
          PrivateUsers = true;
          RemoveIPC = true;
          ReadWritePaths = [cfg.dataDir];

          SystemCallFilter = [
            "~@clock"
            "~@aio"
            "~@chown"
            "~@cpu-emulation"
            "~@debug"
            "~@keyring"
            "~@memlock"
            "~@module"
            "~@mount"
            "~@obsolete"
            "~@privileged"
            "~@raw-io"
            "~@reboot"
            "~@setuid"
            "~@swap"
            "~@resources"
          ];
          SystemCallErrorNumber = "EPERM";
        };
      };
    };

    users.users = lib.mkIf (cfg.user == "degoog") {
      degoog = {
        inherit (cfg) group;
        isSystemUser = true;
      };
    };

    users.groups = lib.mkIf (cfg.group == "degoog") {
      degoog = {};
    };
  };
})
