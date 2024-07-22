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

      nixosModules.default = { pkgs, ... }: {
        imports = [
          nix.nixosModules.default
        ];

        nixpkgs.config.allowUnfree = true;
        documentation.enable = false;

        environment.systemPackages = [
          fh.packages.${pkgs.system}.default
        ];

        services.openssh = {
          enable = true;
          passwordAuthentication = false;
        };

        networking = {
          firewall = {
            enable = true;
            allowedTCPPorts = [ 22 ];
          };
        };

        security.acme.acceptTerms = true;

        services.tailscale.enable = true;
        systemd.services.tailscaled.path = [ pkgs.openresolv ];

        users = {
          mutableUsers = false;
          users = {
            root.openssh.authorizedKeys.keys = [
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE335gifUrpJZb5m4sV9ucLt/35Ct5BCoaiE2bntx43k"
            ];

            grahamc = {
              isNormalUser = true;
              uid = 1000;
              extraGroups = [ "wheel" ];
              createHome = true;
              home = "/home/grahamc";
              openssh.authorizedKeys.keys = [
                "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE335gifUrpJZb5m4sV9ucLt/35Ct5BCoaiE2bntx43k"
              ];
            };
          };
        };
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
