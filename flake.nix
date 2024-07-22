{
  description = "Graham's home network deployments.";

  inputs = {
    fh.url = "https://flakehub.com/f/DeterminateSystems/fh/0.1.13.tar.gz";
    nix.url = "https://flakehub.com/f/DeterminateSystems/nix/2.23.3.tar.gz";
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1";
  };

  outputs = { self, nixpkgs, fh, nix, ... } @ inputs:
    {
      devShells.aarch64-darwin.default = nixpkgs.legacyPackages.aarch64-darwin.mkShell {
        nativeBuildInputs = with nixpkgs.legacyPackages.aarch64-darwin; [
          nixpkgs-fmt
        ] ++ [
          nix.packages.aarch64-darwin.default
          fh.packages.aarch64-darwin.default
        ];
      };

      nixosModules.default = { pkgs, system, ... }: {
        imports = [
          nix.nixosModules.default
        ];

        nixpkgs.config.allowUnfree = true;

        environment.systemPackages = [
          fh.packages.x86_64-linux.default
        ];
      };

      nixosConfigurations = {
        lord-nibbler = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            self.nixosModules.default
            ./lord-nibbler
          ];
        };
      };
    };
}
