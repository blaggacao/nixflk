{ lib, utils, deploy, ... }:
let
  inherit (dev) os;
in

_: { self, ... } @ args:
let

  cfg = (lib.mkFlake.evalOldArgs { inherit args; }).config;

  multiPkgs = os.mkPkgs { inherit (cfg) extern overrides; };

  outputs = {
    nixosConfigurations = os.mkHosts {
      inherit self multiPkgs;
      inherit (cfg) extern suites overrides;
      dir = cfg.hosts;
    };

    homeConfigurations = os.mkHomeConfigurations;

    nixosModules = cfg.modules;

    homeModules = cfg.userModules;

    overlay = cfg.packages;
    inherit (cfg) overlays;

    deploy.nodes = os.mkNodes deploy self.nixosConfigurations;
  };

  systemOutputs = utils.lib.eachDefaultSystem (system:
    let
      pkgs = multiPkgs.${system};
      pkgs-lib = lib.pkgs-lib.${system};
      # all packages that are defined in ./pkgs
      legacyPackages = os.mkPackages { inherit pkgs; };
    in
    {
      checks = pkgs-lib.tests.mkChecks {
        inherit (self.deploy) nodes;
        hosts = self.nixosConfigurations;
        homes = self.homeConfigurations;
      };

      inherit legacyPackages;
      packages = lib.filterPackages system legacyPackages;

      devShell = pkgs-lib.shell;
    });
in
outputs // systemOutputs

