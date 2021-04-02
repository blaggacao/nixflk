{
  description = "DevOS environment configuriguration library.";

  inputs =
    {
      deploy.url = "github:serokell/deploy-rs";
      deploy.inputs = {
        utils.follows = "flake-utils";
      };
      devshell.url = "github:numtide/devshell";
      flake-utils.url = "github:numtide/flake-utils";
      
    }

  outputs = { self, nixpkgs, deploy, devshell, flake-utils, ... }: let

    inherit (nixpkgs) lib;

    jobs = {
      test = import ./tests {
        inherit (self) lib;
        inherit (nixpkgs) pkgs;
      };
      doc = import ./docs { 
        inherit (self) lib;
        inherit (nixpkgs) pkgs;
      };
      updateTemplateRepos = import ./jobs/updateTemplateRepos.nix {
        inherit (self) rev;
        inherit (nixpkgs) pkgs;
        repos = [
          "github.com/divnix/devenv"
          "github.com/divnix/bizenv"
        ];
      };
    };


  in {

    lib = lib.extend (final: prev:

      {
        attrs = import ./attrs.nix { lib = prev; } // prev.attrs;
        lists = import ./lists.nix { lib = prev; } // prev.lists;
        strings = import ./strings.nix { lib = prev; } // prev.strings;

        nixosSystemPlus = import ./nixos-system-plus {
          lib = final;
          inherit deploy, flake-utils;
        }; # takes non-syntactic-sugar parts of current mkHosts

        devos = import ./devos.nix { lib = final; }; # let's keep all the lightweight devos sugar in a single file
      }

      //

      with final; { # TODO: wisely choose what to top-level-export to consumers
        inherit (attrs)
          mapFilterAttrs
          genAttrs'
          safeReadDir
          pathsToImportedAttrs
          concatAttrs
          filterPackages;
        inherit (lists)
          pathsIn;
        inherit (strings)
          rgxToString;

        inherit nixosSystemPlus;

        inherit (devos)
          mkFlake
          mkHosts
          mkNodes
          mkSuites;
      }

    );

    checks.x86_64-linux.tests = jobs.test;
    htmlDocs = jobs.doc; # output and/or serve docbook static page

  };

}
