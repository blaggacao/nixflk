{
  description = "blaggacao's DevOS.";

  inputs =
    {
      nixos.url = "nixpkgs/release-21.05";
      digga.url = "github:divnix/digga/da-temp-combined-branch";
      digga.inputs.nixpkgs.follows = "nixos";
      digga.inputs.nixlib.follows = "nixos";
      deploy.follows = "digga/deploy"; # should go into bud
      bud.url = "github:divnix/bud";
      bud.inputs.nixpkgs.follows = "nixos";
      bud.inputs.devshell.follows = "digga/devshell";
      home.url = "github:nix-community/home-manager";
      home.inputs.nixpkgs.follows = "nixos";
      nixos-hardware.url = "github:nixos/nixos-hardware";

      nix.url = "github:nixos/nix";
      nix.inputs.nixpkgs.follows = "digga/blank";
    };

  outputs = { self, digga, deploy, nix, ... }:

    digga.lib.mkFlake {

      inherit self;

      channelsConfig = { allowUnfree = true; };
      channels.nixos = { overlays = [ deploy.overlay nix.overlay (import ./patches/nix) ]; };

      nixos.hostDefaults.channelName = "nixos";

      devshell = ./devshell;

    };

}
