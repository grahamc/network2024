{ config, lib, pkgs, ... }:
let
  standardDhcpServerConfig = {
    # See: https://github.com/NixOS/nixpkgs/pull/169675
    # ServerAddress = "${vlans.aircon.firstoctets}.1/${toString vlans.aircon.subnet}";

    PoolOffset = 100;
    PoolSize = 100;

    EmitDNS = true;
    DNS = "8.8.8.8";

    EmitRouter = true;
    #Router = "${vlans.aircon.firstoctets}.1"; # maybe not required?
  };

  externalInterface = "enp1s0";

  vlans = {
    nougat = {
      id = 1; # this was commented, and set to 40
      name = "enp2s0";
      description = "Direct access to a few machines like kif.";
      interface = "enp2s0";
      firstoctets = "10.5.3";
      subnet = 24;
      ipv6-ll = "FD00:5:3::1";
      allowOutbound = true;
      isVlan = false;

      staticAssignments = { };
    };

    admin-wifi = {
      id = 10;
      name = "adminwifi";
      description = "wifi adminstrative (bare wire out of the switch)";
      interface = "enp3s0";
      firstoctets = "10.5.5"; # TODO: Validate ends in no dot
      subnet = 24;
      ipv6-ll = "FD00:5:5::1";
      allowOutbound = true;
      isVlan = true;

      staticAssignments = { };
    };

    mgmt = {
      id = 20;
      name = "mgmt";
      description = "Management interfaces: KVMs, IPMI, ILO";
      interface = "enp3s0";
      firstoctets = "10.5.20"; # TODO: Validate ends in no dot
      subnet = 24;
      ipv6-ll = "FD00:5:20::1";
      allowOutbound = false;
      isVlan = true;

      staticAssignments = { };
    };

    kif = {
      id = 30;
      name = "kif";
      description = "Two ports to Kif";
      interface = "enp3s0";
      firstoctets = "10.5.30"; # TODO: Validate ends in no dot
      subnet = 24;
      ipv6-ll = "FD00:5:30::1";
      allowOutbound = true;
      isVlan = true;

      staticAssignments = {
        "10.5.30.11" = "70:85:c2:fd:cb:dd"; # kif port 1
        "10.5.30.12" = "70:85:c2:fd:e3:32"; # kif port 2
      };
    };

    nougat-wifi = {
      id = 41;
      name = "nougatwifi";
      description = "The 'Bearrocscir' network.";
      interface = "enp3s0";
      firstoctets = "10.5.4"; # TODO: Validate ends in no dot
      subnet = 24;
      ipv6-ll = "FD00:5:4::1";
      allowOutbound = true;
      isVlan = true;

      staticAssignments = {
        "10.5.4.50" = "dc:a6:32:6b:ea:1f"; # turner, garage door opener
        "10.5.4.51" = "b8:27:eb:2f:7b:31"; # nixos logo light
        "10.5.4.40" = "3C:6A:9D:14:DA:84"; # elgato key light A
        "10.5.4.41" = "3C:6A:9D:14:DA:85"; # elgato key light B
      };
    };

    detsys = {
      id = 51;
      name = "detsys";
      description = "DetSys sub network, routed by a detsys router";
      interface = "enp3s0";
      firstoctets = "10.50.2";
      subnet = 24;
      ipv6-ll = "FD00:50:2::1";
      allowOutbound = true;
      isVlan = true;

      staticAssignments = {
        "10.50.2.2" = "00:0d:b9:5c:f6:e8"; # thirsty-feynman, apu router (address on enp1s0)
      };

      extraRouteConfig =
        let
          # Static assignment based on the assumption that the /56 we get from Spectrum will always be the same.
          # Needs to be kept in sync with the config on thirsty-feynman.
          ipv6Prefix = "2603:7081:338:c252::/64";
          # More assumptions:
          # - Again that we always get the same /56 from Spectrum
          # - That networkd will always construct the same subnet (c251)
          # - thirsty-feynman uses SLAAC and acquires an EUI-64 address
          # - the right interface (enp1s0) on thirsty-feynman is connected to lordnibbler
          thirsty-feynman = "2603:7081:338:c251:20d:b9ff:fe5c:f6e8";
        in
        [
          { routeConfig.Destination = "10.115.25.0/24"; routeConfig.Gateway = "10.50.2.2"; }
          { routeConfig.Destination = ipv6Prefix; routeConfig.Gateway = thirsty-feynman; }
        ];
    };

    the-s-stands-for-security = {
      id = 80;
      name = "s-for-security";
      interface = "enp3s0";
      description = "The S Stands for Security (IoT)";
      firstoctets = "10.80.80";
      subnet = 24;
      ipv6-ll = "FD00:80:80::1";
      allowOutbound = true; # sigh, hubitat
      isVlan = true;

      staticAssignments = {
        "10.80.80.10" = "34:e1:d1:80:6c:2a"; # hubitat
        "10.80.80.11" = "00:17:88:10:6e:c7"; # philips hue bridge v1

        "10.80.81.30" = "40:91:51:44:bb:3b"; # standing desk controller
      };
    };

    ripeatlas = {
      id = 83;
      name = "ripeatlas";
      interface = "enp3s0";
      description = "Ripe Atlas Probe";
      firstoctets = "10.80.83";
      subnet = 24;
      ipv6-ll = "FD00:80:83::1";
      allowOutbound = true;
      isVlan = true;

      staticAssignments = {
        "10.80.83.10" = "02:01:db:d6:76:af";
      };
    };

    aircon = {
      id = 82;
      name = "aircon";
      description = "The air conditioners ('Climate Change is Here' wifi network)";
      interface = "enp3s0";
      firstoctets = "10.41.50";
      subnet = 24;
      ipv6-ll = "FD00:41:50::1";
      allowOutbound = true;
      isVlan = true;

      staticAssignments = {
        "10.41.50.2" = "28:cc:ff:80:81:95"; # office
        "10.41.50.3" = "28:cc:ff:80:70:d1"; # dining room
        "10.41.50.4" = "28:cc:ff:80:b5:ab"; # blue room
        "10.41.50.5" = "28:cc:ff:80:85:a2"; # den
        "10.41.50.6" = "28:cc:ff:80:82:7d"; # bedroom
      };
    };
  };

in
{
  systemd.services.systemd-networkd.environment.SYSTEMD_LOG_LEVEL = "debug";
  boot.kernel.sysctl = {
    "net.ipv4.conf.all.forwarding" = 1;
    "net.ipv4.conf.default.forwarding" = 1;

    "net.ipv6.conf.all.forwarding" = 1;
    "net.ipv6.conf.default.forwarding" = 1;
    "net.ipv6.conf.${externalInterface}.accept_ra" = 2;

    # default: 4096, which caused "Route cache is full: consider increasing sysctl net.ipv6.route.max_size."
    "net.ipv6.route.max_size" = 512000000;
  };

  networking.useDHCP = false;
  networking.useNetworkd = true;
  systemd.network.netdevs = lib.mapAttrs'
    (_: { name, id, description, ... }: {
      name = "20-${name}";
      value = {
        netdevConfig = {
          Kind = "vlan";
          Name = name;
          Description = description;
        };
        vlanConfig.Id = id;
      };
    })
    (lib.filterAttrs (_: { isVlan, ... }: isVlan) vlans);

  systemd.network.networks = {
    "60-enp1s0" = {
      matchConfig.Name = "enp1s0";
      networkConfig = {
        IPv6AcceptRA = true;
        DHCP = "yes";
      };
      dhcpV6Config = {
        WithoutRA = "solicit";
        PrefixDelegationHint = "::/56";
      };
      linkConfig.RequiredForOnline = "routable";
    };

    "10-enp3s0" = {
      matchConfig.Name = "enp3s0";
      linkConfig = {
        RequiredForOnline = "no";
      };
      networkConfig.LinkLocalAddressing = "no";

      vlan = builtins.map ({ name, ... }: name)
        (builtins.filter
          ({ interface, ... }: interface == "enp3s0")
          (builtins.attrValues vlans));
    };
  } // (lib.mapAttrs'
    (_: { name, id, firstoctets, subnet, staticAssignments ? { }, extraRouteConfig ? [ ], ... }: {
      name = "50-${name}";
      value = {
        matchConfig.Name = name;
        address = [
          "${firstoctets}.1/${toString subnet}"
          # "fd42:23:42:b864::1/64"
          "fe80::1/64"
        ];
        networkConfig = {
          ConfigureWithoutCarrier = true;
          DHCPPrefixDelegation = true;
          IPv6AcceptRA = false;
          IPv6SendRA = true;
          DHCPServer = true;
        };
        dhcpPrefixDelegationConfig = {
          SubnetId = id;
        };
        # ipv6Prefixes = [{
        #   ipv6PrefixConfig = {
        #     Prefix = "fd42:23:42:b864::/64";
        #   };
        # }];
        ipv6SendRAConfig = {
          RouterLifetimeSec = 1800;
          EmitDNS = true;
          DNS = "fe80::1";
          #EmitDomains = true;
          Domains = [
            # "lan.lossy.network"
          ];
        };
        linkConfig = {
          RequiredForOnline = "routable";
        };
        routes = extraRouteConfig;
        dhcpServerConfig = standardDhcpServerConfig;
        dhcpServerStaticLeases = builtins.map
          ({ name, value }: {
            dhcpServerStaticLeaseConfig = {
              MACAddress = value;
              Address = name;
            };
          })
          (builtins.map (name: { inherit name; value = staticAssignments.${name}; }) (builtins.attrNames staticAssignments));
      };
    })
    vlans);

  # Basically, we want to allow some ports only locally and refuse
  # them externally.
  #
  # We don't make a distinction between udp and tcp, since hopefully
  # we won't have that complex of a configuration.
  networking.firewall.extraCommands =
    let
      dropPortNoLog = port:
        ''
          ip46tables -A nixos-fw -p tcp \
            --dport ${toString port} -j nixos-fw-refuse
          ip46tables -A nixos-fw -p udp \
            --dport ${toString port} -j nixos-fw-refuse
        '';

      refusePortOnInterface = port: interface:
        ''
          ip46tables -A nixos-fw -i ${interface} -p tcp \
            --dport ${toString port} -j nixos-fw-log-refuse
          ip46tables -A nixos-fw -i ${interface} -p udp \
            --dport ${toString port} -j nixos-fw-log-refuse
        '';

      refusePortOnInterfaceHighPriority = port: interface:
        ''
          ip46tables -I nixos-fw -i ${interface} -p tcp \
            --dport ${toString port} -j nixos-fw-log-refuse
          ip46tables -I nixos-fw -i ${interface} -p udp \
            --dport ${toString port} -j nixos-fw-log-refuse
        '';

      acceptPortOnInterface = port: interface:
        ''
          ip46tables -A nixos-fw -i ${interface} -p tcp \
            --dport ${toString port} -j nixos-fw-accept
          ip46tables -A nixos-fw -i ${interface} -p udp \
            --dport ${toString port} -j nixos-fw-accept
        '';

      privatelyAcceptPort = port:
        lib.concatMapStrings
          (interface: acceptPortOnInterface port interface)
          [
            vlans.admin-wifi.name
            vlans.aircon.name # consider dropping, too many ports
            vlans.the-s-stands-for-security.name
            vlans.ripeatlas.name
            vlans.kif.name
            vlans.mgmt.name
            vlans.nougat-wifi.name
            vlans.nougat.name
            vlans.detsys.name
          ];

      publiclyRejectPort = port:
        refusePortOnInterface port externalInterface;

      allowPortOnlyPrivately = port:
        ''
          ${privatelyAcceptPort port}
          ${publiclyRejectPort port}
        '';

      # IPv6 flat forwarding. For ipv4, see nat.forwardPorts
      forwardPortToHost = port: interface: proto: host:
        ''
          ip6tables -A nixos-forward -i ${interface} \
            -p ${proto} -d ${host} \
            --dport ${toString port} -j ACCEPT
        '';
    in
    lib.concatStrings [
      ''
        set -x
        ip46tables -P FORWARD DROP
        # set up and/or empty nixos-forward chain
        ip46tables -N nixos-forward || true
        ip46tables -F nixos-forward

        # allow all already established connections
        ip46tables -A nixos-forward -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

        # hook nixos-forward chain into FORWARD. Remove the rule
        # first, so we don't go through the nixos-forward chain n
        # times after n restarts of the firewall service
        ip46tables -D FORWARD -j nixos-forward || true
        ip46tables -A FORWARD -j nixos-forward
      ''
      # (refusePortOnInterfaceHighPriority 22 vlans.target.name)
      (lib.concatMapStrings allowPortOnlyPrivately
        [

          53 # knot dns resolver
          67 # DHCP?
          68 # DHCP?
          69 # tftp

          config.services.netatalk.port
          5353 # avahi

          9100 # node exporter
          9130 # unifi exporter
          9239 # surfboard exporter

          # https://help.ubnt.com/hc/en-us/articles/204910084-UniFi-Change-Default-Ports-for-Controller-and-UAPs
          # TCP:
          6789 # Port for throughput tests
          8080 # Port for UAP to inform controller.
          8880 # Port for HTTP portal redirect, if guest portal is enabled.
          8843 # Port for HTTPS portal redirect, ditto.
          8443 # Port for HTTPS portal redirect, ditto.
          #UDP:
          3478 # UDP port used for STUN.
          10001 # UDP port used for device discovery.

          # Plex: Found at https://github.com/NixOS/nixpkgs/blob/release-17.03/nixos/modules/services/misc/plex.nix#L156
          3005
          8324
          32469 # TCP, 32400 is allowed on all interfaces
          1900
          5353
          32410
          32412
          32413
          32414 # UDP
        ])
      (lib.concatMapStrings dropPortNoLog
        [
          23 # Common from public internet
          143 # Common from public internet
          139 # From RT AP
          515 # From RT AP
          # 9100 # From RT AP
        ])
      (
        let
          crossblock = builtins.attrNames vlans;
          allowDirectional = [
            [ "nougat" "nougat-wifi" ]
            [ "nougat-wifi" "nougat" ]
            [ "nougat-wifi" "kif" ]
            [ "kif" "nougat-wifi" ]
            [ "nougat-wifi" "the-s-stands-for-security" ]
            [ "the-s-stands-for-security" "nougat-wifi" ]
            # [ "nougat-wifi" "aircon" ]
            # [ "aircon" "nougat-wifi" ]
          ];
        in
        lib.concatMapStrings
          (allow: ''
            ip46tables -A nixos-forward -i ${vlans.${builtins.elemAt allow 0}.name} -o ${vlans.${builtins.elemAt allow 1}.name} -j ACCEPT
          '')
          allowDirectional
      )
      ''
        # allow icmp6, because it unbreaks the internet
        ip6tables -A nixos-forward -p icmpv6 -j ACCEPT

        # allow from trusted interfaces
        ${lib.concatMapStrings ({ name, allowOutbound, ... }: if allowOutbound then ''
        ip46tables -A nixos-forward -m state --state NEW -i ${name} -o ${externalInterface} -j ACCEPT
        '' else "") (builtins.attrValues vlans)}

        # let the detsys router handle all firewalling
        ip46tables -A nixos-forward -i ${externalInterface} -o ${vlans.detsys.name} -j ACCEPT
                
        # block any forwarding from the internet which wasn't explicitly permitted
        ip46tables -A nixos-forward -i ${externalInterface} -j REJECT
      ''
    ];
  networking.firewall.allowedTCPPorts = [
    32400 # plex
    2200 # turner's SSH port
  ];
  networking.firewall.allowedUDPPorts = [
    546 # router RAs?
    41741 # Wireguard on ogden
    22094 # vault wireguard network
  ];
  networking.firewall.allowPing = true;

  services.kresd = {
    enable = true;
    listenPlain = [
      "[::]:53"
      "${vlans.nougat.firstoctets}.1:53"
      "${vlans.nougat-wifi.firstoctets}.1:53"

    ];
    extraConfig =
      if true then ''
        modules = {
          'policy',   -- Block queries to local zones/bad sites
          'stats',    -- Track internal statistics
          'predict',  -- Prefetch expiring/frequent records
        }

        -- Smaller cache size
        cache.size = 10 * MB
      '' else ''
        modules = {
          http = {
                  host = 'localhost',
                  port = 8053,
                  -- geoip = 'GeoLite2-City.mmdb' -- Optional, see
                  -- e.g. https://dev.maxmind.com/geoip/geoip2/geolite2/
                  -- and install mmdblua library
          }
        }
      '';
  };

  networking.nat = {
    enable = true;
    externalInterface = externalInterface;
    internalInterfaces = builtins.map
      ({ name, ... }: name)
      (builtins.filter ({ allowOutbound, ... }: allowOutbound) (builtins.attrValues vlans));

    internalIPs =
      [ "10.115.25.0/24" ] # detsys (range managed by thirsty-feynman)
      ++ builtins.map
        ({ firstoctets
         , subnet
         , ...
         }: "${firstoctets}.0/${toString subnet}")
        (builtins.filter ({ allowOutbound, ... }: allowOutbound) (builtins.attrValues vlans));

    forwardPorts = [
      { destination = "10.5.30.11:32400"; proto = "tcp"; sourcePort = 32400; }
      { destination = "10.5.30.11:22"; proto = "tcp"; sourcePort = 22; }
      { destination = "10.5.30.11:80"; proto = "tcp"; sourcePort = 80; }
      { destination = "10.5.30.11:443"; proto = "tcp"; sourcePort = 443; }

      { destination = "10.5.30.11:41741"; proto = "udp"; sourcePort = 41741; }
      { destination = "10.5.30.11:22094"; proto = "udp"; sourcePort = 22094; }
      # always uset he hairpin service below instead of the forward rule, which
      # appears to be broken.
      # { destination = "10.5.4.50:22"; proto = "tcp"; sourcePort = 2200; } # turner
    ];
  };

  services.unifi = {
    enable = true;
    openPorts = false;
    unifiPackage = pkgs.unifi;
    mongoDbPackage = pkgs.mongodb-5_0.override { python3 = pkgs.python311; };
  };

  services.avahi.enable = true;

  systemd.services.forward-hairpin-2200-to-turner-22 = {
    wantedBy = [ "multi-user.target" ];
    script = ''
      set -euxo pipefail
      exec ${pkgs.socat}/bin/socat TCP-LISTEN:2200,fork TCP:10.5.4.50:22
    '';
  };

}
