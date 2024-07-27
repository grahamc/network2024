{ config, lib, pkgs, ... }:
{
  imports = [
    ./hardware.nix
    ./timemachine.nix
  ];

  services.fwupd.enable = true;
  services.openssh = {
    enable = true;
    hostKeys = [
      { bits = 4096; path = "/persist/ssh/ssh_host_rsa_key"; type = "rsa"; }
      { path = "/persist/ssh/ssh_host_ed25519_key"; type = "ed25519"; }
    ];
  };
  systemd.tmpfiles.rules = [
    ''
      e /tmp/nix-build-* - - - 1d -
    ''
  ];

  # Select internationalisation properties.
  i18n = {
    defaultLocale = "en_US.UTF-8";
  };
  console.keyMap = "dvorak";
  console.font = "Lat2-Terminus16";

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs; [
    screen
  ];

  # Following is a hack from 2020-03-28: I was deploying and rebooting
  # without preserving the ACME certs in /persist, and we got rate
  # limited. Delete this after 2020-04-15.
  security.acme.certs."plex.gsc.io".email = "graham@grahamc.com";
  security.acme.certs."plex.gsc.io".extraDomainNames = [ "kif.gsc.io" ];

  services.nginx = {
    enable = true;
    virtualHosts."plex.gsc.io" = {
      enableACME = true;
      forceSSL = true;
      locations."/".proxyPass = "http://127.0.0.1:32400";
    };
  };

  networking.firewall.allowedTCPPorts = [
    80 # nginx -> plex
    443 # nginx -> plex

    # Plex: Found at https://github.com/NixOS/nixpkgs/blob/release-17.03/nixos/modules/services/misc/plex.nix#L156
    32400
    3005
    8324
    32469
  ];

  networking.firewall.allowedUDPPorts = [
    # Plex: Found at https://github.com/NixOS/nixpkgs/blob/release-17.03/nixos/modules/services/misc/plex.nix#L156
    1900
    5353
    32410
    32412
    32413
    32414 # UDP
  ];

  users = {
    groups.writemedia = { };
  };

  services.plex.enable = true;
}
