with import <nixpkgs> {};

haskellPackages.callCabal2nix "dbus-listen" ./. {}
