{
  inputs = {
      nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = {self, nixpkgs}:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      pkgs = forAllSystems (system: nixpkgs.legacyPackages.${system});
    in {
      packages = forAllSystems (system: {
        default = pkgs.${system}.poetry2nix.mkPoetryApplication {
          projectDir = self;
          preferWheels = true;
          postInstall = ''
            mkdir -p $out/share/fish/vendor_completions.d
            _BREW_TOOLS_COMPLETE=fish_source $out/bin/brew_tools > $out/share/fish/vendor_completions.d/brew_tools.fish
          '';
        };
      });

      overlays.default = (final: prev: {
        brew-tools = self.packages.${final.system}.default;
      });

      devShells = forAllSystems (system: {
        default = pkgs.${system}.mkShellNoCC {
          packages = with pkgs.${system}; ([
            (poetry2nix.mkPoetryEnv {
              projectDir = self;
              preferWheels = true;
            })
            poetry
            nodePackages.pyright
          ]);
        };
      });
    };
}
