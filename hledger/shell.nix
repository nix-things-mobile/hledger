# The additional modules below have large dependencies and are therefore
# disabled by default. You can activate them by passing arguments to nix-shell,
# e.g.:
#
#    nix-shell --arg release true
#
# This will provide you with a shell where the `postgrest-release-*` scripts
# are available.
#
# We highly recommend that use the PostgREST binary cache by installing cachix
# (https://app.cachix.org/) and running `cachix use postgrest`.
{ docker ? false
, memory ? false
, release ? false
}:
let
  hledger =
    import ./default.nix;

  pkgs =
    hledger.pkgs;

  lib =
    pkgs.lib;

  toolboxes =
    [
      hledger.cabalTools
      hledger.devTools
      hledger.nixpkgsTools
      hledger.style
      hledger.tests
      hledger.withTools
    ]
    ++ lib.optional docker hledger.docker
    ++ lib.optional memory hledger.memory
    ++ lib.optional release hledger.release;

in
lib.overrideDerivation hledger.env (
  base: {
    buildInputs =
      base.buildInputs ++ [
        pkgs.cabal-install
        pkgs.cabal2nix
        pkgs.postgresql
        hledger.hsie.bin
      ]
      ++ toolboxes;

    shellHook =
      ''
        source ${pkgs.bashCompletion}/etc/profile.d/bash_completion.sh
        source ${hledger.hsie.bashCompletion}

      ''
      + builtins.concatStringsSep "\n" (
        builtins.map (bashCompletion: "source ${bashCompletion}") (
          builtins.concatLists (builtins.map (toolbox: toolbox.bashCompletion) toolboxes)
        )
      );
  }
)
