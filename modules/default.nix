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
    package = lib.mkPackageOption pkgs "caddy" { };
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

    launchd.agents.caddy = {
      enable = true;
      config = {
        ProgramArguments = [
          "${caddyConf.package}/bin/caddy"
          "run"
          "--config"
          "${config.home.homeDirectory}/.config/caddy/Caddyfile"
        ];

        KeepAlive = {
          Crashed = false;
          SuccessfulExit = false;
        };
        RunAtLoad = true;
        ProcessType = "Background";
        StandardOutPath = "${config.home.homeDirectory}/Library/Logs/caddy/stdout";
        StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/caddy/stderr";
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
