{ self, pkgs }:
let
  inherit (self.inputs) nixos;
  inherit (self.nixosConfigurations.NixOS.config.lib) testModule specialArgs;

  mkTest =
    let
      nixosTesting =
        (import "${nixos}/nixos/lib/testing-python.nix" {
          inherit (pkgs.stdenv.hostPlatform) system;
          inherit specialArgs;
          inherit pkgs;
          extraConfigurations = [
            testModule
          ];
        });
    in
    test:
    let
      loadedTest =
        if builtins.typeOf test == "path"
        then import test
        else test;
      calledTest =
        if pkgs.lib.isFunction loadedTest
        then pkgs.callPackage loadedTest { }
        else loadedTest;
    in
    nixosTesting.makeTest calledTest;
in
{
  profilesTest = mkTest {
    name = "profiles";

    machine = { suites, ... }: {
      imports = suites.allProfiles ++ suites.allUsers;
    };

    testScript = ''
      machine.systemctl("is-system-running --wait")
    '';
  };

  homeTest = self.homeConfigurations."nixos@NixOS".home.activationPackage;

}

