{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib) types;
  caddyConf = config.programs.caddy;

  caddyfilePath =
    if caddyConf.config.path != null then
      caddyConf.config.path
    else
      "${config.home.homeDirectory}/.config/caddy/Caddyfile";

  launchScript =
    let
      script = pkgs.writeShellScriptBin "caddy-launch" ''
        set -e
        exec ${lib.getExe caddyConf.package} run --config ${caddyfilePath}
      '';
    in
    lib.getExe script;
in
{
  options.programs.caddy = {
    enable = lib.mkEnableOption "Caddy";
    package = lib.mkPackageOption pkgs "caddy" { };
    config = {
      path = lib.mkOption {
        type = types.nullOr (
          types.oneOf [
            types.path
            types.str
          ]
        );
        default = null;
        description = "Path of config file";
      };
      text = lib.mkOption {
        type = types.nullOr types.lines;
        default = null;
        description = "Content of config path. If specified, the Caddyfile will be written to .config/caddy/Caddyfile";
      };
    };
  };

  config = lib.mkIf caddyConf.enable {
    assertions = [
      {
        assertion = caddyConf.config.text != caddyConf.config.path;
        message = "programs.caddy.config.path conflicts with programs.caddy.config.text";
      }
    ];

    home.packages = [ caddyConf.package ];

    home.file = lib.mkIf (caddyConf.config.text != null) {
      ".config/caddy/Caddyfile".text = caddyConf.config.text;
    };

    launchd.agents.caddy = {
      enable = true;
      config = {
        ProgramArguments = [ launchScript ];

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
