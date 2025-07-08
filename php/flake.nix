{
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

      mkPhp =
        pkgs:
        pkgs.php.buildEnv {
          extensions = (
            pe:
            pe.enabled
            ++ (with pe.all; [
              # mongodb
              # redis
              # xdebug
            ])
          );
          extraConfig = ''
            # xdebug.mode=debug
            # xdebug.client_host=127.0.0.1
            # xdebug.client_port=9003
          '';
        };

      commonPackages =
        pkgs: with pkgs; [
          (mkPhp pkgs)
          (with (mkPhp pkgs).packages; [
            composer
          ])
          # nodejs
          # mongodb-ce
          # mongosh
          # redis
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
