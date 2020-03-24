# These are negative tests.  They are expected to fail.

let
  nix-stylish-haskell-check = import ../default.nix;

  nixpkgs = (nix-stylish-haskell-check {}).nixpkgs;

  example-haskell-package-bad =
    nixpkgs.haskellPackages.callCabal2nix
      "example-haskell-proj-bad"
      ./example-haskell-proj-bad
      {};

  stylish-haskell-funcs-for-bad-example =
    nix-stylish-haskell-check {
      stylish-haskell-conf-file = builtins.path {
        name = "stylish-haskell.yaml";
        path = ./example-haskell-proj-bad/.stylish-haskell.yaml;
      };
    };
in

stylish-haskell-funcs-for-bad-example.stylish-haskell-checks
  [ example-haskell-package-bad ]
