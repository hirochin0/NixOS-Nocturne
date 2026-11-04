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
- その後、ユーザーの実機でKittyとSuper+Enterの起動成功が報告された。元ログに動的ローダの失敗理由までは出ていないため、glibc不整合が唯一の原因だったとは断定しない。

## 3本指ジェスチャー・swww・開発アプリ追加

- Hyprlandとその既存依存のlock nodeは変更せず、swww v0.11.2とNeofetch 7.1.0の公式ソースを追加固定した。
- VS CodeとChromeもMesaと同じ固定nixpkgsから取得する。非自由ライセンスの許可はこの2パッケージだけ。
- 壁紙選択のheadlessテストは、空白・日本語・シェル記号のあるパス、選択保存と復元、キャンセル、適用失敗時の状態保持、起動待ち、状態JSON破損、元画像削除、保存画像の適用失敗からの既定画像への復帰を確認する。
- このコンテナではChrome展開時のsetuid権限変更がEPERM、swwwの依存crate展開時のUID 1000への所有者変更がEINVALとなる。通常の実ビルド全体は完了していない。実機設定を変更する回避策は入れていない。
- Lua解析と起動スクリプトの検証では、検証専用の式でChrome/swwwの実際のstoreパス文字列だけを残し、両バイナリのビルド依存を除外する。これはCLI/GUIの起動検証ではなく、同じLua内容とシェル構文の検証に限定する。
- この限定した検証では、Hyprland 0.57.1の`--verify-config`が`config ok`で終了、Lua構文検査と起動スクリプトのShellCheckが成功、壁紙の4つのheadlessテストが成功した。
- 通常の`system-contract`と`application-cli`はビルド成功。Home Manager activation derivationまで評価し、インストールしたCodexとNeofetchのバージョン出力も確認した。swww/Chrome/VS CodeのGUI起動は試していない。
- 実機でのタッチパッド入力、swww起動・画像表示、壁紙選択UI、VS Code/ChromeのGUIは引き続き確認が必要。`checks.x86_64-linux.wallpaper-tools`にはswwwの実コマンド検証も定義してあり、NixOS上で実行できる。

## 壁紙メニューのサムネイル表示

- 壁紙メニューをrofiのicon row付きグリッドに変更。通常のアプリランチャー、swwwサービス、状態ファイルの形式は維持する。
- Python/PillowとWayland対応rofiをNixの起動スクリプトに組み込み、ユーザーによるpip等の追加作業は不要。
- 縮小・キャッシュ再利用・画像更新による無効化・GIF先頭フレーム・不正画像の代替表示・行プロトコルの制御文字を追加テスト。既存の保存/復元・キャンセル等と合わせて7テスト。
- 通常の`system-contract`を再ビルドして成功。変更したPython/Pillow環境と起動ラッパーもNixでビルドし、7テスト、ShellCheck、rofi 2.0.0でのテーマ読込と3列設定の出力確認が成功した。従来どおり、このコンテナではswww本体のビルドを除外した検証専用式を用いる。
- rofi 2.0.0の`-rasi-validate`は最小の有効テーマでも終了処理でsegfaultしたため、チェックは通常の`-theme ... -dump-theme`経路で読込エラーがないことと解析結果を確認する方式にした。
- 実際のWayland画面でのレイアウトとキー・マウス操作は、対象NixOSでの確認が必要。

## 参照した一次資料

- https://github.com/hyprwm/Hyprland/releases/tag/v0.57.1
- https://github.com/hyprwm/Hyprland/blob/v0.57.1/example/hyprland.lua
- https://wiki.hypr.land/nix/installing-hyprland-on-nixos/
- https://wiki.hypr.land/nix/cachix/
- https://github.com/nix-community/home-manager/blob/release-26.05/modules/misc/dconf.nix
- https://github.com/Vladimir-csp/uwsm
