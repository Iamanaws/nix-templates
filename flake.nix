{
  description = "A collection of flake templates";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      forSystems =
        f: nixpkgs.lib.genAttrs systems (system: f { pkgs = import nixpkgs { inherit system; }; });
    in
    {
      formatter = forSystems ({ pkgs }: pkgs.nixfmt-tree);
      templates = {

        default = {
          path = ./default;
          description = "Standard flake";
        };

        php = {
          path = ./php;
          description = "PHP template";
          welcomeText = ''
            # Getting started
            - Run `nix develop`
          '';
        };

        python = {
          path = ./python;
          description = "Python template";
          welcomeText = ''
            # Getting started
            - Run `nix develop`
          '';
        };

        react-native-android = {
          path = ./react-native-android;
          description = "Minimal React Native Android Dev Environment";
          welcomeText = ''
            # Getting started
            - Run `nix develop`
          '';
        };
      };

      defaultTemplate = self.templates.default;

    };
}
