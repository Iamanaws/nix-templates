{
  description = "Standard flake";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

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
        f:
        nixpkgs.lib.genAttrs systems (
          system:
          f {
            pkgs = import nixpkgs {
              inherit system;
              config.allowUnfree = false;
            };
          }
        );

      commonPackages =
        pkgs: with pkgs; [
        ];
    in
    {
      formatter = forSystems ({ pkgs }: pkgs.nixfmt-tree);

      packages = forSystems (
        { pkgs }:
        {
          default = pkgs.buildEnv {
            paths = commonPackages pkgs;
          };
        }
      );

      devShells = forSystems (
        { pkgs }:
        {
          default = pkgs.mkShellNoCC {
            packages = commonPackages pkgs;
          };
        }
      );
    };
}
