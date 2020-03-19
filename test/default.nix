
# These are the normal tests that are all expected to succeed.

let
  nix-stylish-haskell-check = import ../default.nix;

  nixpkgs = (nix-stylish-haskell-check {}).nixpkgs;

  example-haskell-package =
    nixpkgs.haskellPackages.callCabal2nix
      "example-haskell-proj"
      ./example-haskell-proj
      {};

  stylish-haskell-funcs-for-example =
    nix-stylish-haskell-check {
      stylish-haskell-conf-file = builtins.path {
        name = "stylish-haskell.yaml";
        path = ./example-haskell-proj/.stylish-haskell.yaml;
      };
    };
in

stylish-haskell-funcs-for-example.stylish-haskell-checks
  [ example-haskell-package ]
