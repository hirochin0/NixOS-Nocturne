{ pkgs, home-manager, desktop, user, theme }:
let
  hm = (home-manager.lib.homeManagerConfiguration {
    inherit pkgs;
    extraSpecialArgs = { inherit desktop user theme; };
    modules = [ ../home ];
  }).config;
  # ビルド環境にはNixOSの/etc/dbus-1/session.confがないため、同じ
  # パッケージの設定ファイルを明示する。HMの設定生成/cleanup/loadはそのまま検証。
  activation = pkgs.lib.replaceStrings
    [ "--dbus-daemon=${pkgs.dbus}/bin/dbus-daemon" ]
    [ "--dbus-daemon=${pkgs.dbus}/bin/dbus-daemon --config-file=${pkgs.dbus}/share/dbus-1/session.conf" ]
    hm.home.activation.dconfSettings.data;
in pkgs.runCommand "nocturne-dconf-activation" {
  nativeBuildInputs = [ pkgs.dconf pkgs.dbus ];
} ''
  export HOME="$TMPDIR/home" XDG_CONFIG_HOME="$TMPDIR/config" XDG_RUNTIME_DIR="$TMPDIR/runtime"
  mkdir -p "$HOME" "$XDG_CONFIG_HOME" "$XDG_RUNTIME_DIR"
  chmod 700 "$XDG_RUNTIME_DIR"
  # 既存バスに接続できないケースでも、実際のHM activationが最後まで通ること。
  export DBUS_SESSION_BUS_ADDRESS="unix:path=$TMPDIR/unavailable-bus"
  run() { "$@"; }
  ${hm.home.activation.nocturneDconfBus.data}
  ${activation}
  test "$(dconf read /org/gnome/desktop/interface/color-scheme)" = "'prefer-dark'"
  test "$(dconf read /org/gnome/desktop/interface/gtk-theme)" = "'adw-gtk3-dark'"
  test "$(dconf read /org/gnome/desktop/interface/icon-theme)" = "'Papirus-Dark'"
  mkdir -p "$out"
  printf '%s\n' 'Home Manager dconf activation and persistent theme values: passed' > "$out/result"
''
