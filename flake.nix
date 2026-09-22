{
  description = "Home manager module for Caddy";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
  };

  outputs = { ... }: {
    homeModules.caddy = import ./modules;
  };
}
