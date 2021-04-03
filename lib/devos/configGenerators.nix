{ lib, ... }: let

  # Conventions, where applicable:
  # - last argument is direct input from the user flake


  /**
  Synopsis: mkHomeConfigurations _nixosConfigurations_

  Recursively collect the subdirs of _path_ containing a default.nix into attrs.
  This sets a contract, eliminating ambiguity for _default.nix_ living under the
  profile directory.
  **/
  mkHomeConfigurations = nixosConfigurations:
  let
    f = hostname: config:
      let
        f' = user: v:
          lib.nameValuePair "${user}@${hostname}" v
      in
        lib.mapAttrs' f' config.config.system.build.homes;

    hmConfigs = lib.mapAttrs f nixosConfigurations;
  in
    lib.foldl lib.recursiveUpdate {} (lib.attrValues hmConfigs);


  /**
  Synopsis: mkDeployConfigurations _deploy_ _nixosConfigurations_

  Generate the `nodes` attribute expected by deploy-rs
  from nixosConfigurations.
  **/
  mkDeployConfigurations = deploy: nixosConfigurations:
  let
    f = hostname: config:
      {
        inherit hostname;
        profiles.system = {
          user = "root";
          path = deploy.lib.x86_64-linux.activate.nixos config;
        };
      };
  in
    lib.mapAttrs f nixosConfigurations;


  /**
  Synopsis: mkNixosConfigurations _specialArgs_ _modules_ _hosts_

  Generate the nixosConfigurations from host configuriguration
  files while passing devos modules and specialArgs to the module
  system.
  **/
  mkNixosConfigurations = specialArgs: modules: hosts:
  let hosts =
    let
      f = hostName: file: lib.nixosSystemPlus {
        inherit specialArgs;
        system = "x86_64-linux"; # TODO
        modules =
          modules //
          {
             require = [ file ];
    
             networking = { inherit hostName; };
    
             _module.args = {
               hosts = let
                 f = _: host: host.config;
                 otherHosts = removeAttrs hosts [ hostName ];
               in builtins.mapAttrs f otherHosts;
                 
             };
          } //
          {
          # lib = { inherit specialArgs; };
          # lib.testModule = {
          #   imports = builtins.attrValues modules;
          # };
          };
      };
    in builtins.mapAttrs f hosts;
  in hosts;
