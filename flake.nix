{
  description = "BystroTeX command-line tools";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in {
      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
          bystrotex = pkgs.callPackage ./default.nix { };
        in {
          default = bystrotex;
          inherit bystrotex;
          b2l = bystrotex;
        });

      apps = forAllSystems (system: {
        default = {
          type = "app";
          program = "${self.packages.${system}.bystrotex}/bin/bystrotex";
        };
        bystrotex = {
          type = "app";
          program = "${self.packages.${system}.bystrotex}/bin/bystrotex";
        };
        b2l = {
          type = "app";
          program = "${self.packages.${system}.bystrotex}/bin/b2l";
        };
      });
    };
}
