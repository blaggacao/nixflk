final: prev: {

  __dontExport = true;

  nix = prev.nix.overrideAttrs (o: { doCheck = false; patches = (o.patches or [ ]) ++ [

      # fixes nested `inputs.<name>.follows` syntax
      (prev.fetchpatch {
        name = "fix-follows.diff";
        url = "https://github.com/CitadelCore/nix/commit/cfef23c040c950222b3128b9da464d9fe6810d79.diff";
        sha256 = "sha256-KpYSX/k7FQQWD4u4bUPFOUlPV4FyfuDy4OhgDm+bkx0=";
      })

      # enable flakes by default (hey, this is a flakes first thing)
      ./enable-flakes.patch

    ];
  });

}
