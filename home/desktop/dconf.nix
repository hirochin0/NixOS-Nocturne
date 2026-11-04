{ lib, pkgs, ... }: {
  # NixOSのsystem unitから既存ユーザーバスを引き継ぐと、旧セッションの
  # activation検索パスにdconfサービスがなくServiceUnknownになる場合がある。
  # HM標準のheadless経路(dbus-run-session)で、同じユーザーDBへ適用する。
  # GTK由来のfont/icon/cursor設定も通常のdconfSettingsに任せる。
  home.activation.nocturneDconfBus = lib.hm.dag.entryBefore [ "dconfSettings" ] ''
    unset DBUS_SESSION_BUS_ADDRESS
    export XDG_DATA_DIRS="${pkgs.dconf}/share:''${XDG_DATA_DIRS:-/run/current-system/sw/share}"
  '';
}
