# nix-stylish-haskell-check

[![Actions Status](https://github.com/xc-jp/nix-stylish-haskell-check/workflows/Test/badge.svg)](https://github.com/xc-jp/nix-stylish-haskell-check/actions)
![BSD3 license](https://img.shields.io/badge/license-BSD3-blue.svg)

Easily check that your Haskell files pass stylish-haskell.

`nix-stylish-haskell-check` exports a Nix function that produces a derivation
that successfully compiles if your input Haskell files all fit the code-style
enforced by `stylish-haskell`.

This is convenient to use in CI to make sure your Haskell files are all
formatted correctly.

## Usage

If you have a Haskell project that is built with Nix, it is easy to import
and use `nix-stylish-haskell-check`:

```nix
with import <nixpkgs> {};

let
  # This is an example Haskell project.  You should replace this with a
  # derivation for the Haskell project you want to check the syntax for.
  my-haskell-package =
    haskellPackages.callCabal2nix
      "my-haskell-package"
      /some/path/to/my-haskell-project
      {};

  # Import the source code for nix-stylish-haskell-check.  You MUST update the
  # commit ID in the `url`, as well as the `sha256` for the version of
  # nix-stylish-haskell-check you want to use.
  nix-stylish-haskell-check-src = builtins.fetchTarball {
    url = "https://github.com/xc-jp/nix-stylish-haskell-check/archive/fd415652b1946465c3577490d913351627f6e556.tar.gz";
    sha256 = "1wirxi4s680hkf969a0njxgmhvbkvl8x5wb83j9wxi0k7qp55y81";
  };

  # Import the source for nix-stylish-haskell-check, and pass it the
  # stylish-haskell config file for your project.  Passing the stylish-haskell
  # config file is not strictly needed, but it is often necessary if you
  # use various language pragmas in your Haskell files.
  #
  # The `builtins.path` function is used because of a limitation in Nix of
  # using paths that start with a period.
  nix-stylish-haskell-check = import nix-stylish-haskell-check-src {
    stylish-haskell-conf-file = builtins.path {
      name = "stylish-haskell.yaml";
      path = /some/path/to/my-haskell-project/.stylish-haskell.yaml;
    };
  };
in

nix-stylish-haskell-check.stylish-haskell-check my-haskell-package
```

## Errors

When using `nix-stylish-haskell-check`, if your input Haskell source code does
not fit the style enforced by `stylish-haskell`, you will get errors like the
following:

```console
$ nix-build ./my-stylish-haskell-check-example.nix
building '/nix/store/97sbsfpdax4ck2lllp4ln2y88f8j08fa-stylish-haskell-for-example-haskell-proj-bad.txt.drv'...
stylish-haskell diff for example-haskell-proj-bad in /nix/store/jmq344mx8lfz0s7452m1q0b4bmsd35h5-example-haskell-proj-bad/Main.hs:
    --- /nix/store/jmq344mx8lfz0s7452m1q0b4bmsd35h5-example-haskell-proj-bad/Main.hs    1970-01-01 00:00:01.000000000 +0000
    +++ /build/stylish-haskell-res.hs   2020-03-24 05:28:29.271286895 +0000
    @@ -2,7 +2,7 @@

    -import Data.Conduit (Conduit   )
    +import Data.Conduit (Conduit)

     main :: IO ()
     main = putStrLn "Hello, Haskell!"

Error, found stylish-haskell problems for example-haskell-proj-bad.
builder for '/nix/store/97sbsfpdax4ck2lllp4ln2y88f8j08fa-stylish-haskell-for-example-haskell-proj-bad.txt.drv' failed with exit code 1
```

If your input Haskell source code already meets the style enforced by
`stylish-haskell`, the build will succeed as expected.
