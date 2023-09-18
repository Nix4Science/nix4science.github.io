{
  description = "A very basic flake";

  inputs = { nixpkgs.url = "github:nixos/nixpkgs/23.05"; };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in {
      packages.${system} = {
        docker-ci = pkgs.dockerTools.buildImage {
          name = "GuilloteauQ/nix4science";
          tag = "latest";

          copyToRoot = pkgs.buildEnv {
            name = "image-root";
            paths = with pkgs; [
              gnumake
              python3Packages.sphinx
              python3Packages.sphinx-book-theme
            ];
            pathsToLink = [ "/bin" ];
          };
        };
      };

      devShells.${system} = {
        default = pkgs.mkShell {
          buildInputs = with pkgs; [
            gnumake
            python3Packages.sphinx
            python3Packages.sphinx-book-theme
          ];
        };
      };

    };
}
