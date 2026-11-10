{ desktop, ... }: {
  programs.steam = {
    enable = true;
    # Match Steam's FHS runtime/libc with the desktop Mesa package set.
    package = desktop.steam;
  };
  hardware.graphics.enable32Bit = true;
}
