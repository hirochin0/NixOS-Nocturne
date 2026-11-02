{
  # 必ず現在の NixOS のログイン名に変更する。
  name = "yuto";
  hostName = "nocturne";
  system = "x86_64-linux";
  keyboardLayout = "jp";
  # 個別指定例: { output = "HDMI-A-1"; mode = "1920x1080@60"; position = "1920x0"; scale = 1; }
  monitors = [ { output = ""; mode = "preferred"; position = "auto"; scale = 1; } ];
  # 既存ログイン画面がなければ true。既存DMは base 側で無効化する。
  enableGreetd = false;
  # 初めて Home Manager を使う場合の初期値。既存環境では元の値を維持。
  homeStateVersion = "26.05";
}
