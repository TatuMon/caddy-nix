{
  config,
  pkgs,
  lib,
  ...
}:
let
  caddyConf = config.programs.caddy;
in
{
  options.programs.caddy = {
    enable = lib.mkEnableOption "Caddy";
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.caddy;
      description = "Caddy package to install.";
    };
    configFile = lib.mkOption {
      type = lib.types.nullOr lib.types.lines;
      default = null;
      description = "Contents of the Caddyfile.";
    };
  };

  config = lib.mkIf caddyConf.enable {
    home.packages = [ caddyConf.package ];

    home.file = lib.mkIf (caddyConf.configFile != null) {
      ".config/caddy/Caddyfile".text = caddyConf.configFile;
    };

    launchd.agents.caddy = lib.mkIf config.launchd.enable {
      enable = true;

      config = {
        ProgramArguments = [
          "${caddyConf.package}/bin/caddy"
          "run"
          "--config"
          "${config.home.homeDirectory}/.config/caddy/Caddyfile"
        ];

        RunAtLoad = true;
        KeepAlive = true;
      };
    };

    systemd.user.services.caddy = lib.mkIf config.systemd.user.enable {
      Unit = {
        Description = "Caddy Web Server";
        After = [ "network.target" ];
      };

      Service = {
        ExecStart = "${caddyConf.package}/bin/caddy run --config ${config.home.homeDirectory}/.config/caddy/Caddyfile";
        ExecReload = "${caddyConf.package}/bin/caddy reload --config ${config.home.homeDirectory}/.config/caddy/Caddyfile";
        Restart = "on-failure";
      };

      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };
}
