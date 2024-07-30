{
  description = "Graham's home network deployments.";

  inputs = {
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/=0.1.647193";
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/0.1";

    fh.follows = "determinate/fh";
    nix.follows = "determinate/fh";
  };

  outputs = { self, nixpkgs, determinate, fh, nix, ... } @ inputs:
    let
      forSystems = s: f: inputs.nixpkgs.lib.genAttrs s (system: f rec {
        inherit system;
        pkgs = inputs.nixpkgs.legacyPackages.${system};
      });

      forAllSystems = forSystems [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ];
    in
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
          determinate.nixosModules.default
        ];

        nixpkgs.config.allowUnfree = true;
        documentation.enable = false;

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
            {
              networking.hostName = "lord-nibbler";
            }
          ];
        };

        kif = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            self.nixosModules.default
            ./kif
            {
              networking.hostName = "kif";
            }
          ];
        };
      };
    };
}
