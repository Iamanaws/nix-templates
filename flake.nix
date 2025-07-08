{
  description = "A collection of flake templates";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

  outputs =
    { self, nixpkgs }:
    let
      forSystems =
        f:
        nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed (
          system: f { pkgs = import nixpkgs { inherit system; }; }
        );

      defaultWelcomeText = ''
        # Getting started
        - Run `nix develop`
      '';

      rawTemplates = {
        default = {
          path = ./default;
          description = "Standard flake";
        };

        php = {
          path = ./php;
          description = "PHP template";
        };

        python = {
          path = ./python;
          description = "Python template";
        };

        react-native-android = {
          path = ./react-native-android;
          description = "Minimal React Native Android Dev Environment";
        };
      };
    in
    {
      formatter = forSystems ({ pkgs }: pkgs.nixfmt-tree);
      templates = nixpkgs.lib.mapAttrs (
        name: value:
        value
        // {
          welcomeText = if (value ? welcomeText) then value.welcomeText else defaultWelcomeText;
        }
      ) rawTemplates;

      defaultTemplate = self.templates.default;

    };
}
