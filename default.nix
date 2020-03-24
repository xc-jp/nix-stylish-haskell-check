
{
  # This is a path to your project-wide .stylish-haskell.yaml file.  If you
  # don't pass it, then the default stylish-haskell configuration is used.
  #
  # Note that the stylish-haskell configuration file is normally called
  # .stylish-haskell.yaml, but with Nix it is not possible to create a path to
  # a file that starts with a period.  Instead, you can use the `builtins.path`
  # function:
  #
  # ```
  # builtins.path {
  #   name = "stylish-haskell.yaml";
  #   path = /some/path/to/haskell/project/.stylish-haskell.yaml;
  # }
  # ```
  stylish-haskell-conf-file ? null
, # Function used to clean the source of a derivation.
  #
  # This function takes a derivation as input, and returns a derivation
  # as output.
  #
  # The returned derivation should contain the .hs source files that
  # you want to run `stylish-haskell` on.
  #
  # If you don't pass this argument, it will be set at the following:
  #
  # ```
  # haskellPkg: haskellPkg.src
  # ```
  source-cleaner ? null
, # stylish-haskell derivation to use.  If this is null, we get the
  # stylish-haskell executable from a recent version of nixpkgs.
  stylish-haskell ? null
, # Nixpkgs to use to get various helper functions.
  nixpkgs ?
    # nixpkgs master as of 2020-03-18.
    let nixpkgs-src = builtins.fetchTarball {
          url = "https://github.com/NixOS/nixpkgs/archive/52ee55fe0f760368cb492bb3922f15ae3365005a.tar.gz";
          sha256 = "15hxjl60ax8h0ar8ls9vl3rpzp1ba58ay8jp47s1dxj202p7sjbn";
        };
    in import nixpkgs-src {}
, lib ? nixpkgs.lib
}:

assert isNull stylish-haskell || lib.isDerivation stylish-haskell;
assert isNull source-cleaner || lib.isFunction source-cleaner;

let

  # The real stylish-haskell binary for us to use.
  stylish-haskell-real =
    if isNull stylish-haskell
    then nixpkgs.stylish-haskell
    else stylish-haskell;

  # The real source cleaning function.
  source-cleaner-real = drv:
    if isNull source-cleaner
    then drv.src
    else source-cleaner drv;

  # Command line argument to pass to `stylish-haskell` to specify the
  # config file.
  config-file-argument =
    if isNull stylish-haskell-conf-file
    then ""
    else ''-c "${stylish-haskell-conf-file}"'';

  inherit (nixpkgs) linkFarmFromDrvs runCommand;
in
rec {
  # This is the nixpkgs we are using.  Normally this won't be used, but it is
  # helpful for the tests in this repo.
  inherit nixpkgs;

  # Run stylish-haskell for a single Haskell package.
  #
  # The derivation passed as an argument should contain
  # .hs files that you want to run through `stylish-haskell`.
  #
  # If `stylish-haskell` recommends changes, the derivation will
  # fail to build.  If `stylish-haskell` doesn't recommend any
  # changes, the derivation will successfully build.
  stylish-haskell-check = drv:
    let
      name = drv.pname or drv.name;

      cleaned-source = source-cleaner-real drv;
    in
    runCommand
      "stylish-haskell-for-${name}.txt"
      { nativeBuildInputs = [ stylish-haskell-real ]; }
      ''
        echo "--- Running stylish-haskell for ${name}"

        # This is a flag that gets set to 1 when stylish-haskell finds a
        # difference with our source code.
        foundStylishHaskellDiff=0

        # Loop over all the .hs files for this Haskell package.
        while IFS= read -r -d "" filename; do

          # Run stylish-haskell on the Haskell file.
          stylish-haskell ${config-file-argument} \
              "$filename" > "$TEMP/stylish-haskell-res.hs"

          # Check to see if stylish-haskell recommended any changes to the
          # underlying Haskell file.
          if ! diff --unified "$filename" "$TEMP/stylish-haskell-res.hs" > \
              "$TEMP/stylish-haskell-res.diff" ; then

            # Set the flag saying that stylish-haskell found a change, so this
            # build should fail.
            foundStylishHaskellDiff=1

            echo "stylish-haskell diff for ${name} in $filename:" | \
                tee -a "$out"

            # Make sure to indent the diff output so it doesn't trigger a
            # buildkite collapsable section.
            sed -e 's/^/    /' "$TEMP/stylish-haskell-res.diff" | \
                tee -a "$out"
            echo | tee -a "$out"
          fi

        done < <(find "${cleaned-source}" -name "*.hs" -print0)
        if [[ $foundStylishHaskellDiff -eq 0 ]]; then
          echo "Success, stylish-haskell found no differences for ${name}." | \
              tee -a "$out"
        else
          echo "Error, found stylish-haskell problems for ${name}." | \
              tee -a "$out"
          exit 1
        fi
      '';

  # Run `stylish-haskell` for a list of Haskell packages.
  #
  # Return a single derivation that succeeds if all the stylish-haskell checks
  # pass.
  #
  # This is convenient to call from CI.
  stylish-haskell-checks = drvs:
    linkFarmFromDrvs "stylish-haskell-checks" (map stylish-haskell-check drvs);
}
