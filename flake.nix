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

        lib' = qik.lib.${system}.haskell.mk {
          tool = pkgs: with pkgs; [ zlib ];
          name = "lib";
          root = ./.;
        };
      in rec {
        lib = rec {
          colors = {
            default           = 0;
            aqua              = 1752220;
            darkAqua          = 1146986;
            green             = 5763719;
            darkGreen         = 2067276;
            blue              = 3447003;
            darkBlue          = 2123412;
            purple            = 10181046;
            darkPurple        = 7419530;
            luminousVividPink = 15277667;
            darkVividPink     = 11342935;
            gold              = 15844367;
            darkGold          = 12745742;
            orange            = 15105570;
            darkOrange        = 11027200;
            red               = 15548997;
            darkRed           = 10038562;
            grey              = 9807270;
            darkGrey          = 9936031;
            darkerGrey        = 8359053;
            lightGrey         = 12370112;
            navy              = 3426654;
            darkNavy          = 2899536;
            yellow            = 16776960;
            white             = 16777215;
            greyple           = 10070709;
            black             = 2303786;
            darkButNotBlack   = 2895667;
            notQuiteBlack     = 2303786;
            blurple           = 5793266;
            discordYellow     = 16705372;
            fuchsia           = 15418782;
          };

          embed = { authorName  ? ""
                  , authorUrl   ? ""
                  , title       ? ""
                  , url         ? ""
                  , fields      ? []
                  , footerText  ? ""
                  , description
                  }: {
                    inherit authorName authorUrl title fields footerText description url;
                  };
        };

        mk  = { name, bot }: pkgs.stdenv.mkDerivation {
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

          makeWrapper ${lib'}/bin/lib "$out/bin/${name}" \
                      --run "cd \"$out/bin\""
          '';
        };

        devShells.default = lib'.env;
      });
}
