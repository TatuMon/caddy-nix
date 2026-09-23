# caddy-nix
Home-manager flake to configure [Caddy](https://caddyserver.com)

> ⚠️ Keep in mind that this project is mainly about experimenting on flakes and Nix in general.

> Errors are expected, so tips, suggestions, and advice are welcome!

## Usage
#### Home manager's flake.nix
```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    caddy-nix = {
      url = "github:TatuMon/caddy-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # ...
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      caddy-nix,
      ...
    }:
    let
      pkgs = import nixpkgs {
        system = "aarch64-darwin";
        config.allowUnfree = true;
      };
    in
    {
      homeConfigurations.tatumon = home-manager.lib.homeManagerConfiguration {
        pkgs = pkgs;
        extraSpecialArgs = {
          inherit caddy-nix;
          # ...
        };
        modules = [
          ./home.nix
          ./caddy
          # ...
        ];
      };
    };
}
```

### caddy module
```nix
{ caddy-nix, config, ... }:
{
  imports = [
    caddy-nix.homeModules.caddy
  ];

  # Example using agenix for private configurations
  # age.secrets = {
  #   "caddy/caddyfile" = {
  #     file = ./../secrets/caddyfile.age;
  #   };
  # };

  programs.caddy = {
    enable = true;
    # config.path = config.age.secrets."caddy/caddyfile".path;
    config.text = ''
      https://myhost {
        tls internal
        reverse_proxy [::1]:30000
      }
    ''
  };
}
```
