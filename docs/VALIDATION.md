# 検証記録（2026-11-04 JST）

対象公開コミット: `80220dba1e7d5baedffe2c48ea2077a0b3430e44`

## 確認済み

- 公開された全Nix/Luaモジュールを読み、v0.57.1の公式ソース・サンプルと照合。
- Nix 2.31.2をこの作業環境に用意し、実際にflake.lockを生成。
- Hyprland `0.57.1+date=2026-11-03_acc1aa0`の実パッケージで、生成したすべてのLuaを検証。`config ok`、終了コード0。
- NixOS 26.05 / Home Manager release-26.05のfixtureで全モジュールassertionと型評価を確認。Home Manager activation derivationの生成まで成功。
- XDPH `1.5.0+date=2026-11-01_8545044`、Mesa `26.2.6`、Waybar/Hyprlock/Hypridleの取得元を上流依存集合に統一。
- UWSMパッケージとHyprlandのdesktop entryを読み、起動IDに対応する`wayland-session@hyprland.desktop.target`にサービスを接続。
- shell wrapperはNixのwriteShellApplicationによるShellCheckを含むビルドを通過。

## この環境では確認できないもの

- D-Busによる設定書き込みのテストは定義済みだが、このコンテナではUnixソケット作成がEPERMとなり実行不可。テストを通過したとは主張しない。対象NixOSで`checks.x86_64-linux.dconf-activation`を実行する。
- 同様にHyprlandの設定検証では、IPC用Unixソケットの警告が出る。設定解析結果は`config ok`だが、画面を表示するテストではない。
- 実機のbase設定・ローカル変更・既存flake.lockは公開されていない。fixtureの評価成功は、実機全体のビルド・起動成功を保証しない。
- 実機のGPU、モニタ配置、SDDM/GDMからのログイン、ロック解除、音声、日本語入力、Windowsとの起動切替は未確認。

## dconfの修正理由と残る確認

写真のログから確定しているのは、dconfSettings段階のD-Bus ServiceUnknownである。
Home Managerのソースでは、既存DBUS_SESSION_BUS_ADDRESSがある場合はそのバスを使い、ない場合はdbus-run-sessionを起動する。
今回の修正は、NixOSのsystem unitから行う設定反映を既存グラフィカルセッションのバスと切り離し、HM標準のheadless経路で反映するもの。
XDG_DATA_DIRSに採用dconfパッケージのサービス定義を明示する。dconf、GTK設定、ダークモードは無効にしない。
ただし、元のユーザーバスのサービス一覧は未取得なので、既存バスの検索パスが原因だったとの断定はしない。

## 参照した一次資料

- https://github.com/hyprwm/Hyprland/releases/tag/v0.57.1
- https://github.com/hyprwm/Hyprland/blob/v0.57.1/example/hyprland.lua
- https://wiki.hypr.land/nix/installing-hyprland-on-nixos/
- https://wiki.hypr.land/nix/cachix/
- https://github.com/nix-community/home-manager/blob/release-26.05/modules/misc/dconf.nix
- https://github.com/Vladimir-csp/uwsm
