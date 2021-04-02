{
  description = "A highly structured configuration database.";

  inputs =
    {
      nixos.url = "nixpkgs/nixos-unstable";
      override.url = "nixpkgs";
      devos.url = "path:./lib"; # TODO: outfactor into separate repo
      devos.inputs = {
        nixpkgs.follows = "override";
        deploy.inputs = {
          flake-compat.follows = "flake-compat";
          naersk.follows = "naersk";
          nixpkgs.follows = "override";
        };
      };

      ci-agent = {
        url = "github:hercules-ci/hercules-ci-agent";
        inputs = { nix-darwin.follows = "darwin"; flake-compat.follows = "flake-compat"; nixos-20_09.follows = "nixos"; nixos-unstable.follows = "override"; };
      };
      darwin.url = "github:LnL7/nix-darwin";
      darwin.inputs.nixpkgs.follows = "override";
      flake-compat.url = "github:BBBSnowball/flake-compat/pr-1";
      flake-compat.flake = false;
      naersk.url = "github:nmattia/naersk";
      naersk.inputs.nixpkgs.follows = "override";
      nixos-hardware.url = "github:nixos/nixos-hardware";
      home-manager.url = "github:nix-community/home-manager";
      home-manager.inputs.nixpkgs.follows = "nixos";

      pkgs.url = "path:./pkgs";
      pkgs.inputs.nixpkgs.follows = "nixos";
    };

    outputs = inputs@{ self, devos, nixos, nur, ... }:
      devos.lib.mkFlake {
        inherit self;
        hosts = ./hosts;
        packages = import ./pkgs;
        suites = import ./suites;
        extern = import ./extern;
        overrides = import ./overrides;
        overlays = ./overlays;
        profiles = ./profiles;
        userProfiles = ./users/profiles;
        modules = import ./modules/module-list.nix;
        userModules = import ./users/modules/module-list.nix;
      } // {
        defaultTemplate = self.templates.flk;
        templates.flk.path = ./.;
        templates.flk.description = "flk template";
        templates.mkflake.path =
          let
            excludes = [ "lib" "tests" "cachix" "nix" "theme" ".github" "bors.toml" "cachix.nix" ];
            filter = path: type: ! builtins.elem (baseNameOf path) excludes;
          in
            builtins.filterSource filter ./.;
        templates.mkflake.description = "template with necessary folders for mkFlake usage";
      };

}
