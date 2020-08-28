# Nix dependencies for developing DokMelody-Jam
#
with import <nixpkgs> {};

# NOTE: install only Racket, then other Racket packages will be installed in the Racket way
# using raco and working on local directories.

runCommand "dummy" {
     buildInputs = [
       haskellPackages.lentil
       wget

       racket
    ];
} ""
