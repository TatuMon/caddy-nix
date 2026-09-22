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
  };
}
