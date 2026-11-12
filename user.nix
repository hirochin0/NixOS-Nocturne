{
  # 必ず現在の NixOS のログイン名に変更する。
  name = "hiroto";
  hostName = "nocturne";
  system = "x86_64-linux";
  keyboardLayout = "jp";
  # 個別指定例: { output = "HDMI-A-1"; mode = "1920x1080@60"; position = "1920x0"; scale = 1; }
  monitors = [ { output = ""; mode = "preferred"; position = "auto"; scale = 1; } ];
  # NocturneのGUIログイン。trueならSDDM/GDM/LightDMを置き換える。
  enableGreetd = true;
  # 初めて Home Manager を使う場合の初期値。既存環境では元の値を維持。
  homeStateVersion = "26.05";
  # 空ならSpotifyカードを全画面へ表示。特定画面だけに出す例: "HDMI-A-1"
  musicWidgetOutput = "";
}
