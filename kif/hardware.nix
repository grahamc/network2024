{ lib, pkgs, ... }:
{
  boot.initrd.availableKernelModules = [ "mpt3sas" "xhci_pci" "ahci" "nvme" "usb_storage" "usbhid" "sd_mod" "sr_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];
  boot.kernelParams = [ "console=tty1,115200n8" ];
  boot.kernelPackages = pkgs.linuxPackages;

  boot.zfs.passwordTimeout = 15;
  boot.zfs.extraPools = [ "hydra" ];
  boot.initrd.postDeviceCommands = lib.mkAfter ''
    zfs rollback -r hpool/local/root@blank
  '';

  fileSystems."/" =
    {
      device = "hpool/local/root";
      fsType = "zfs";
    };
  fileSystems."/var/lib/plex" =
    {
      device = "hpool/safe/plex";
      fsType = "zfs";
    };
  fileSystems."/persist" =
    {
      device = "hpool/local/persist";
      fsType = "zfs";
    };
  fileSystems."/var/lib/acme" =
    {
      device = "hpool/local/persist/acme";
      fsType = "zfs";
    };

  fileSystems."/var/lib/tailscale" =
    {
      device = "hpool/local/persist/tailscale";
      fsType = "zfs";
    };
  fileSystems."/var/lib/prometheus2" =
    {
      device = "hpool/local/persist/prometheus2";
      fsType = "zfs";
    };
  fileSystems."/var/lib/netatalk" =
    {
      device = "hpool/local/persist/netatalk";
      fsType = "zfs";
    };
  fileSystems."/nix" =
    {
      device = "hpool/local/nix";
      fsType = "zfs";
    };
  fileSystems."/boot" =
    {
      device = "/dev/disk/by-label/BOOT";
      fsType = "vfat";
    };

  fileSystems."/home/emilyc/timemachine" =
    {
      device = "rpool/time-machine/emily";
      fsType = "zfs";
      options = [ "nofail" ];
    };
  fileSystems."/home/grahamc/timemachine" =
    {
      device = "rpool/time-machine/graham";
      fsType = "zfs";
      options = [ "nofail" ];
    };
  fileSystems."/home/cole-h/timemachine" =
    {
      device = "rpool/time-machine/cole-h";
      fsType = "zfs";
      options = [ "nofail" ];
    };
  fileSystems."/home/kyle/storage" =
    {
      device = "rpool/kyle/storage";
      fsType = "zfs";
      options = [ "nofail" ];
    };
  fileSystems."/media" =
    {
      device = "rpool/media/plex";
      fsType = "zfs";
      options = [ "nofail" ];
    };


  networking.hostId = "2016154b";
  swapDevices = [ ];
  boot.loader.systemd-boot.enable = true;
  nix.maxJobs = 12;
  services.zfs.autoScrub.enable = true;
}
