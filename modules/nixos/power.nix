{ lib, ... }: {
  powerManagement.enable = true;
  # One owner of CPU/platform power policy; do not run competing tuners.
  services.power-profiles-daemon.enable = true;
  services.tlp.enable = lib.mkForce false;
  services.auto-cpufreq.enable = lib.mkForce false;
  powerManagement.powertop.enable = lib.mkForce false;
}
