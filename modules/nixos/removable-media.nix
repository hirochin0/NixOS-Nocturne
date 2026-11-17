{ pkgs, ... }: {
  services.udisks2.enable = true;
  services.gvfs.enable = true;
  # Checking tools only; never run filesystem repair automatically.
  environment.systemPackages = [ pkgs.exfatprogs pkgs.dosfstools ];
}
