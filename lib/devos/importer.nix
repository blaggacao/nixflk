{ lib, ... }: let

  mkProfileSet = prefix: name: { default = "${prefix}/${name}"; }
  unpackProfileSet = profile: profile.default;

in {

  /**
  Synopsis: mkSuites { users, profiles, userProfiles } _suites_

  Render suites from a suite declaration in the form:

  { users, profiles, userProfiles, ... }:
  {
    system = with profiles; rec {
      base = [ users.nixos users.root ];
    };
    user = with userProfiles; rec {
      base = [ direnv git ];
    };
  }
  **/
  mkSuites = { users, profiles, userProfiles }: suitesDeclaration:
  let
    suites = suitesDeclaration {
      inherit users profiles userProfiles;
    };

    systemSuites = suites.system;
    userSuites = suites.user;

    allUserProfiles =
      let defaults = lib.collect (x: x ? default) userProfiles;
      in map (x: x.default) defaults;

    allProfiles =
      let defaults = lib.collect (x: x ? default) profiles;
      in map (x: x.default) defaults;

    allUsers =
      let defaults = lib.collect (x: x ? default) users;
      in map (x: x.default) defaults;

    f = _: v:
      map unpackProfileSet v
  in
    {
      system = lib.mapAttrs f systemSuites // {
        inherit allProfiles allUsers;
      };
      user = lib.mapAttrs f userSuites // {
        inherit allUserProfiles;
      };
    }


  /**
  Synopsis: mkProfiles _path_

  Recursively collect the subdirs of _path_ containing a default.nix into attrs.
  This sets a contract, eliminating ambiguity for _default.nix_ living under the
  profile directory.

  Example:
  let profiles = mkProfiles ./profiles; in
  assert profiles ? core.default; 0
  **/
  mkProfiles = dir:
  let
    imports =
      let
        files = lib.safeReadDir dir;

        p = n: v:
          v == "directory"
          && n != "profiles";
      in
        lib.filterAttrs p files;

    f = n: _:
      lib.optionalAttrs
        (lib.pathExists "${dir}/${n}/default.nix")
        (mkProfileSet dir n)
      // mkProfiles "${dir}/${n}";
  in
    lib.mapAttrs f imports;


  /**
  Synopsis: mkHosts _path_

  Collect nix files from path and map them to theit names, where names
  awe their basenames stripped of the .nix suffix.
  **/
  mkHosts = dir:
  let
    imports =
      let
        files = lib.safeReadDir dir;

        p = n: v:
          n != "default.nix"
          && lib.hasSuffix ".nix" n
          && v == "regular"
      in
        lib.filterAttrs p files;

    f = n: _: let
      name = lib.removeSuffix ".nix" n;
    in lib.nameValuePair (name) n;
  in
    lib.mapAttrs' f imports;

};
