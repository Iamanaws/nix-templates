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

      rawTemplates = {
        default.path = ./default;
        php.path = ./php;
        python.path = ./python;
        react-native-android.path = ./react-native-android;
      };
    in
    {
      formatter = forSystems ({ pkgs }: pkgs.nixfmt-tree);
      templates = nixpkgs.lib.mapAttrs (
        name: value:
        let
          importedFlake = builtins.tryEval (import (value.path + /flake.nix));
          flakeDesc = nixpkgs.lib.attrByPath [ "value" "description" ] null importedFlake;
          baseAttrs = {
            welcomeText = ''
              # Getting started
              - Run `nix develop`
            '';
            description = "No description provided";
          } // value;
        in
        baseAttrs
        // (nixpkgs.lib.optionalAttrs (flakeDesc != null) {
          description = flakeDesc;
        })
      ) rawTemplates;

      defaultTemplate = self.templates.default;
    };
}
