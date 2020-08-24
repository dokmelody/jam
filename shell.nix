# Nix dependencies for developing DokMelody-Jam
#
# NOTE: Nix has no good support for Java and Maven,
# so it will install Maven and then Maven will install in ``~/.m2`` directory
# following the Java approach and not the Nix-way.

with import <nixpkgs> {};

runCommand "dummy" {
     buildInputs = [
       haskellPackages.lentil
       wget

       jdk11_headless
       maven
    ];
} ""
