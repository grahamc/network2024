{ config, ... }:
let
  internalInterface = "enp35s0";
in
{
  networking.firewall.allowedTCPPorts = [
    config.services.netatalk.port
    5353 # avahi
  ];

  users.users.emilyc = {
    isNormalUser = true;
    uid = 1002;
    createHome = true;
    home = "/home/emilyc";
  };

  services.netatalk = {
    enable = true;
    settings = {
      "Global" = {
        "afp interfaces" = internalInterface;
        "afp listen" = "10.5.30.11";
        "log level" = "default:debug";
      };

      "emilys-time-machine-2020-04" = {
        "time machine" = "yes";
        path = "/home/emilyc/timemachine/time-machine-root";
        "valid users" = "emilyc";
      };
    };
  };

  services.avahi = {
    enable = true;
    interfaces = [ internalInterface ];
    nssmdns = true;

    publish = {
      enable = true;
      userServices = true;
    };
  };
}
