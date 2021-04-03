{ lib, flake-utils, deploy }:
let
  mkFlake = { self, ... } @ args:
      # TODO: pipe args through importers
    mkFlake' args;

  mkFlake' =
    {
      self
      , name
      , nixos
      , overlay
      , preOverlays ? [ ]
      , systems ? [ "x86_64-linux" ]
      , shell ? null
      , config ? { allowUnfree = true; }

      # internal & external module declarations
      , nixosModules ? [ ]
      , extraNixosModules ? [ ]
      , extraSpecialArgs ? { }
      , homeModules ? [ ]
      , extraHomeModules ? [ ]
      , extraHomeSpecialArgs ? { }
      # , devShellModules

      # applied devos environment configuriguration
      , profiles
      , users
      , userProfiles
      , suites
      , hosts

      # backports from alternate channel
      , nixos' ? null
      , backportPkgs ? pkgs: final: prev: { }
      , backportModules ? [ ]
      , disabledModules ? [ ]
    }:
    let

      preOverlays_ =
        preOverlays
        ++
        [
          final: prev: let
            system = prev.stdenv.hostPlatform;
            # system = prev.stdenv.buildPlatform;
          in
            {
              # add checks by conforming to simpleFlake checks api
              "{$name}".checks =
                let

                  tests =
                    lib.optionalAttrs
                      (system  == "x86_64-linux")
                      (
                        import "${self}/tests" { inherit self; pkgs = prev; }
                      );


                  deployChecks =
                    deploy.lib.${system}.deployChecks
                      {
                        nodes = let
                          p = n: _:
                            self.nixosConfigurations.${n}.config.nixpkgs.system == system;
                        in lib.filterAttrs p self.deploy.nodes;
                      };

                in tests // deployChecks;

              # add backports from nixos'
              "{$name}".backports = # TODO: pros & cons of namespacing with `backports`
                let

                  nixosPkgs' = import nixos' {
                    inherit system config;
                    overlay = [ ];
                  };

                in backportPkgs nixosPkgs' final prev
            }

        ]

      # produces `packages`, `legacyPackages` & `devShell` - but also a multi pkgs
      outputs' = flake-utils.lib.simpleFlake' { # TODO: re-export pkgs in fork
        inherit
          self
          name
          systems
          overlay
          shell
          config
          ;
        preOverlays = preOverlays_;
        nixpkgs = nixos;
      };
      outputs = outputs'.flake;
      pkgs = outputs'.pkgs;

      # re-exports according to the devos sharing model
      exports = {
        inherit
          nixosModules
          homeModules
          # devShellModules
          overlay
          ;
      };

      configs = {
        nixosConfigurations = let

          specialArgs =
            {
              suites = suites.system;
              modulesPath' = "${nixos'}/nixos/modules";
            }
            // extraSpecialArgs;

          modules' =
            builtins.attrValues self.nixosModules
            ++ extraNixosModules;

          hmSpecialArgs' =
            {
              suites = suites.user;
            };
            // extraHomeSpecialArgs;

          hmModules' =
            builtins.attrValues self.homeModules
            ++ extraHomeModules;

          modules = [

            {
              _module.args = {
                inherit self;
              };
            }

            {
              nixpkgs.pkgs = lib.mkDefault pkgs.${config.nixpkgs.system};
              hardware.enableRedistributableFirmware = lib.mkDefault true;
            }

            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;

                extraSpecialArgs = hmSpecialArgs';
                sharedModules = hmModules';
              };
            }
   
            {
              nix.extraOptions = ''
                experimental-features = flakes nix-command ca-references ca-derivations
              '';
              nix.registry = {
                self.flake = inputs.self;
                nixos.flake = inputs.nixos;
                override.flake = inputs.override;
              };
            }

            { config, ... }: {
              system.configurationRevision = lib.mkIf (self ? rev) self.rev;
            }

            { modulesPath', ... }: {
              disabledModules = backportModules ++ disabledModules;
              imports = let
                f = path: "${modulesPath'}/${path}"
              in map f backportModules;
            };

          ] ++ modules';

        in lib.mkNixosConfigurations specialArgs modules hosts;
    
        homeConfigurations = lib.mkHomeConfigurations self.nixosConfigurations;
        deploy = {
          nodes = lib.mkDeployConfigurations deploy self.nixosConfigurations;
        };
      };
    
    in
     outputs // exports // configs
  };
in {
  inherit mkFlake mkFlake';
}
