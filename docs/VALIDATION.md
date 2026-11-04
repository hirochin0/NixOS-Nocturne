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

## 実機からの追加報告とKittyの取得元修正

- バーと壁紙はUWSM経由で表示されたが、Kitty 0.49.1はWayland接続後のEGL初期化で終了した。
- 実機の`50_mesa.json`はMesa 26.2.6を指し、`ldd`ではその依存先にglibc 2.44が見えた。単体の`ldd`に不足がないことは、Kittyプロセスへの動的ロードの互換性まで保証しない。
- KittyをHyprlandの固定nixpkgsから取得し、Mesaとビルド時の依存集合を揃える。Home Managerのpackageと生成キー設定の実行パスの両方を変更する。
- `system-contract`にKittyの実パス一致のassertionと採用バージョンを追加した。
- 追加後の`checks.x86_64-linux.system-contract`を再ビルドして成功。Kitty 0.49.2、Mesa 26.2.6、Hyprland 0.57.1と、Home Manager activation derivationの評価を確認した。KittyのGUI起動テストではない。
- この変更で実機のEGL失敗が解消するかは、対象マシンで再確認が必要。元ログに動的ローダの失敗理由までは出ていないため、glibc不整合が唯一の原因だとは断定しない。

## 参照した一次資料

- https://github.com/hyprwm/Hyprland/releases/tag/v0.57.1
- https://github.com/hyprwm/Hyprland/blob/v0.57.1/example/hyprland.lua
- https://wiki.hypr.land/nix/installing-hyprland-on-nixos/
- https://wiki.hypr.land/nix/cachix/
- https://github.com/nix-community/home-manager/blob/release-26.05/modules/misc/dconf.nix
- https://github.com/Vladimir-csp/uwsm
