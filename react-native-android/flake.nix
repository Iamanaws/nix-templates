{
  description = "Minimal React Native Android Dev Environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    android.url = "github:tadfisher/android-nixpkgs/stable";
  };

  outputs =
    {
      self,
      nixpkgs,
      android,
    }:
    let
      systems = [
        "x86_64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      forSystems =
        f:
        nixpkgs.lib.genAttrs systems (
          system:
          let
            pkgs = import nixpkgs {
              inherit system;
              config = {
                allowUnfree = true;
                android_sdk.accept_license = true;
              };
            };

            jdk = pkgs.jdk17;

            buildToolsVersion = "35.0.0";
            ndkVersion = "26.1.10909125";

            androidSdk = android.sdk.${system} (
              sdkPackages:
              let
                buildTools = "build-tools-${builtins.replaceStrings [ "." ] [ "-" ] buildToolsVersion}";
                ndk = "ndk-${builtins.replaceStrings [ "." ] [ "-" ] ndkVersion}";
              in
              with sdkPackages;
              [
                # Core SDK components
                cmdline-tools-latest
                emulator
                platform-tools
                platforms-android-35
                cmake-3-22-1
                build-tools-34-0-0

                # Other useful packages
                # skiaparser-3
                # sources-android-35
              ]
              ++ [
                sdkPackages.${buildTools}
                sdkPackages.${ndk}
              ]
              # Emulator system images
              ++ pkgs.lib.optionals (system == "aarch64-darwin") [
                # system-images-android-35-google-apis-arm64-v8a
                # system-images-android-35-google-apis-playstore-arm64-v8a
              ]
              ++ pkgs.lib.optionals (system == "x86_64-darwin" || system == "x86_64-linux") [
                # system-images-android-35-google-apis-x86-64
                # system-images-android-35-google-apis-playstore-x86-64
              ]
            );

            # Define common packages needed for both the package and devShell
            commonPackages =
              with pkgs;
              [
                androidSdk
                nodejs
                jdk
                watchman
              ]
              ++ lib.optionals (system == "x86_64-linux") [
                # pkgs.androidStudioPackages.stable
              ];
          in
          f {
            inherit
              pkgs
              commonPackages
              system
              androidSdk
              jdk
              buildToolsVersion
              ndkVersion
              ;
          }
        );

    in
    {
      formatter = forSystems ({ pkgs, ... }: pkgs.nixfmt-tree);

      packages = forSystems (
        { pkgs, commonPackages, ... }:
        {
          default = pkgs.buildEnv {
            paths = commonPackages;
          };
        }
      );

      devShells = forSystems (
        {
          pkgs,
          commonPackages,
          system,
          buildToolsVersion,
          ndkVersion,
          ...
        }:
        {
          default = pkgs.mkShellNoCC {
            packages = commonPackages;

            # Set environment variables needed by Android tools
            shellHook = ''
              export ANDROID_AVD_HOME="$HOME/.config/.android/avd"
              export ANDROID_NDK_ROOT="$ANDROID_SDK_ROOT/ndk/${ndkVersion}"
              export GRADLE_OPTS="-Dorg.gradle.project.android.aapt2FromMavenOverride=$ANDROID_SDK_ROOT/build-tools/${buildToolsVersion}/aapt2"
              # Print paths for verification when entering the shell
              echo "--------------------------------------------------"
              echo "System: ${system}"
              echo "React Native Android Environment Activated"
              echo "Java Home (JAVA_HOME): $JAVA_HOME"
              echo "Android SDK Root (ANDROID_SDK_ROOT): $ANDROID_SDK_ROOT"
              echo "Android NDK Root (ANDROID_NDK_ROOT): $ANDROID_NDK_ROOT"
              echo "Node version: $(node --version)"
              echo "Watchman version: $(watchman --version)"
              echo "--------------------------------------------------"
            '';
          };
        }
      );
    };
}
