{
  description = "declarative response based discord bots with nix";

  inputs      = {
    qik.url         = "github:indypaige/qik";
    nixpkgs.url     = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs     = { self, nixpkgs, flake-utils, qik, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        lib  = qik.lib.${system}.haskell.mk {
          tool = pkgs: with pkgs; [ zlib ];
          name = "lib";
          root = ./.;
        };
      in rec {
        mk = { name, bot }: pkgs.stdenv.mkDerivation {
          inherit name;

          src = self;

          nativeBuildInputs = [
            pkgs.makeWrapper
          ];

          buildPhase = ''
          mkdir -p $out/bin

          printf '%s\n' \
                 ${pkgs.lib.escapeShellArg (builtins.toJSON bot)} \
                 > "$out/bin/obj.json"

          makeWrapper ${lib}/bin/lib "$out/bin/bot" \
                      --run "cd \"$out/bin\""
          '';
        };

        devShells.default = lib.env;
      });
}
