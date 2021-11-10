{ config, lib, pkgs, modulesPath, ... }:
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;
  boot.loader.grub.device = "nodev";
  boot.loader.grub.copyKernels = true;
  boot.loader.grub.fsIdentifier = "label";
  boot.loader.grub.extraConfig = "serial; terminal_input serial; terminal_output serial";

  boot.kernelParams = [ "console=ttyS0,19200n8" ];

  networking.usePredictableInterfaceNames = false;
  networking.interfaces.eth0.useDHCP = true;
  networking.interfaces.eth0.tempAddress = "disabled";
}
