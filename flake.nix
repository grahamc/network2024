{
  description = "Graham's home network deployments.";

  inputs = {
    fh.url = "https://flakehub.com/f/DeterminateSystems/fh/0.1.13.tar.gz";
    nix.url = "https://flakehub.com/f/DeterminateSystems/nix/2.23.3.tar.gz";
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/=0.1.647193";

    determinate-nixd-aarch64-linux = {
      url = "https://install.determinate.systems/determinate-nixd/rev/87e416024f6e7203748aebc25862ddf17efb428e/aarch64-linux";
      flake = false;
    };
    determinate-nixd-x86_64-linux = {
      url = "https://install.determinate.systems/determinate-nixd/rev/87e416024f6e7203748aebc25862ddf17efb428e/x86_64-linux";
      flake = false;
    };
    determinate-nixd-aarch64-darwin = {
      url = "https://install.determinate.systems/determinate-nixd/rev/87e416024f6e7203748aebc25862ddf17efb428e/aarch64-darwin";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, fh, nix, ... } @ inputs:
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

      packages = forAllSystems ({ system, pkgs, ... }: {
        default = pkgs.runCommand "determinate-nixd" { } ''
          mkdir -p $out/bin
          cp ${inputs."determinate-nixd-${system}"} $out/bin/determinate-nixd
          chmod +x $out/bin/determinate-nixd
          $out/bin/determinate-nixd --help
        '';
      });


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

      nixosModules.determinate = { lib, pkgs, config, ... }: {
        imports = [
          # inputs.nix.nixosModules.default
        ];

        options = {
          determinate.nix.primaryUser.username = lib.mkOption {
            type = lib.types.str;
            description = "The Determinate Nix user";
          };

          determinate.nix.primaryUser.netrcPath = lib.mkOption {
            type = lib.types.path;
            description = "The path to the `netrc` file for the user configured by `primaryUser`";

            default =
              let
                netrcRoot =
                  if config.determinate.nix.primaryUser.username == "root"
                  then "/root"
                  else "/home/${config.determinate.nix.primaryUser.username}";
              in
              "${netrcRoot}/.local/share/flakehub/netrc";
          };
        };

        config = {
          environment.systemPackages = [
            inputs.fh.packages."${pkgs.stdenv.system}".default
          ];

          systemd.services.nix-daemon.serviceConfig.ExecStart = [
            ""
            "@${self.packages.${pkgs.stdenv.system}.default}/bin/determinate-nixd determinate-nixd --nix-bin ${config.nix.package}/bin"
          ];

          nix.settings = {
            netrc-file = config.determinate.nix.primaryUser.netrcPath;
            extra-substituters = [ "https://cache.flakehub.com" ];
            extra-trusted-public-keys = [
              "cache.flakehub.com-1:t6986ugxCA+d/ZF9IeMzJkyqi5mDhvFIx7KA/ipulzE="
              "cache.flakehub.com-2:ntBGiaKSmygJOw2j1hFS7KDlUHQWmZALvSJ9PxMJJYU="
            ];
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
              networing.hostName = "lord-nibbler";
            }
          ];
        };

        kif = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            self.nixosModules.default
            self.nixosModules.determinate
            ./kif
            {
              determinate.nix.primaryUser.username = "grahamc";
              networing.hostName = "kif";
            }
          ];
        };
      };
    };
}
