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

## Quickshell音楽カード・電源モード（2026-11-05）

- 公式の現行安定版Quickshell v0.3.2と、固定済みHyprlandのnixpkgsに含まれる同じバージョンのパッケージを確認。lockの更新は不要。Qt/Mesaの集合を揃える。
- MPRISの`trackArtist`・機能可否フラグ・秒単位のpositionを使用。1秒のTimerはカードの表示中かつ再生中だけ動かす。毎フレーム更新やCLIポーリングは使わない。
- `PowerProfiles.profile`と`hasPerformanceProfile`を使用し、非対応機器ではPowerを無効化。Waybarのバッテリークリックから、サービスと同じ設定パスのQuickshell IPCへ接続する。
- `system-contract`でpower-profiles-daemonの有効化と競合サービスの無効化、Waybarとの接続、UWSMターゲットとの連携を評価する。
- `checks.x86_64-linux.quickshell`はQML構文、Spotify以外の隔離、複数プレイヤー・切断、画面の選択・取り外し時のフォールバック、シークの範囲を検証する。QtのoffscreenでMusicCardをインスタンス化し、長いタイトル・機能未対応・プレイヤー消失時の状態も確認する。
- 上記のsystem-contractとquickshellチェックはNixでビルド成功。操作用nocturne-widgetsラッパーもShellCheckを含めてビルド成功。offscreenでカードの描画も確認した。
- 実機のWaylandレイヤー表示・クリック/シーク・Spotifyの実MPRIS・電源モード変更・消費電力の測定は実機で確認が必要。このコンテナではUnixソケット作成が制限され、Quickshell IPCへの接続も実証できない。画面の起動確認はoffscreenでのカード描画に限定する。

参照した一次資料:

- https://github.com/quickshell-mirror/quickshell/releases/tag/v0.3.2
- https://quickshell.org/docs/v0.3.2/types/Quickshell.Services.Mpris/MprisPlayer/
- https://quickshell.org/docs/v0.3.2/types/Quickshell.Services.UPower/PowerProfiles/
- https://quickshell.org/docs/v0.3.2/types/Quickshell.Services.UPower/PowerProfile/
- https://quickshell.org/docs/v0.3.2/types/Quickshell.Io/IpcHandler/
- https://quickshell.org/docs/v0.3.2/types/Quickshell.Wayland/WlrLayershell/
- https://github.com/NixOS/nixpkgs/blob/nixos-26.05/nixos/modules/services/hardware/power-profiles-daemon.nix
- https://github.com/NixOS/nixpkgs/blob/0bb2eedc20e4739f29e8045034f2828ad7054f8f/pkgs/by-name/qu/quickshell/package.nix

## Spotify / Spicetifyの宣言的管理（2026-11-05）

- Spicetify公式の導入案内に従い、spicetify-nixの`homeManagerModules.spicetify`を使用。リビジョン`13e6fed4eb99f809d390fb50f591bed6cb716dc0`をlockに追加し、nixpkgsはHyprlandの固定集合をfollowする。既存lock nodeが変わっていないことを確認した。
- Spotify 1.2.95.453.g0eeebbedとSpicetify CLI 2.46.1を同じ固定集合から取得する。生のSpotifyをhome.packagesから外し、モジュールが作成したSpicetify適用済みSpotifyだけを導入する。CLIもhome.packagesに含める。
- `system-contract`のビルド成功。Spicetify有効化・元のSpotifyパス・二重導入の不存在とHome Manager activation derivationを検証した。dconfの単体チェックも新しい引数を受け取ってderivationまで評価できた。
- 通常のSpicetify適用ビルドはこの単一UIDコンテナのroot判定で停止する。検証専用式で、隔離したビルドのCLI呼び出しだけに`--bypass-admin`を付けてビルド完了を確認した。生成された`Apps/xpui/colors.css`にNocturneのシアン色があることも確認。リポジトリ内の設定とインストールするCLIにはこの回避指定を含めない。
- 実機でのGUI表示・ログイン・音楽再生は対象NixOSでの確認が必要。手動の`spicetify apply`やストアの権限変更は不要。

参照した一次資料:

- https://github.com/spicetify/docs/blob/main/docs/getting-started.md
- https://gerg-l.github.io/spicetify-nix/usage.html
- https://github.com/Gerg-L/spicetify-nix/blob/13e6fed4eb99f809d390fb50f591bed6cb716dc0/modules/options.nix
- https://github.com/Gerg-L/spicetify-nix/blob/13e6fed4eb99f809d390fb50f591bed6cb716dc0/modules/homeManager.nix


## Nocturne GUIログイン（2026-11-06）

- NixOS 26.05の固定モジュール`programs.regreet`を使用し、ReGreet 0.5.0とCageはMesaと同じ固定nixpkgs集合から取得する。flake.lockは変更していない。
- `system-contract`をビルドし、GUI有効化、greeterユーザー、initial_sessionの不存在、自動ログイン無効化、SDDM/GDM/LightDM/lyとの重複がないこと、Home Managerのactivation derivationを確認した。
- `enableGreetd = false`で既存のログイン方式を使う構成も、同じチェックのderivation評価が成功した。
- 生成したセッションは`uwsm start -e -D Hyprland hyprland.desktop`を呼ぶ。既存の`wayland-session@hyprland.desktop.target`を維持する。
- ReGreet実行ファイルのデモモードを1440×900の仮想Xサーバーで起動し、実際に生成したGTK CSSを読み込ませて描画確認した。検証専用のAccountsServiceモックを使用し、ユーザー／セッション選択画面からEnterで秘密情報入力画面へ遷移することも確認した。モック・仮想Xサーバー・検証用D-Busは実機設定には含めない。
- プレビューは`docs/login-preview.png`。カスタムCSSファイルの構文エラーは出ていない。デモ環境では上流のインラインCSSにempty declarationの警告が出るが、画面描画と入力遷移は成功した。
- 実機のDRM/Wayland起動、PAM認証、ログイン後のHyprland起動、サスペンド復帰はこのコンテナでは検証できない。実機のディスク設定を含むOS全体のビルド・起動テストは対象端末で行う。適用は`nixos-rebuild boot`後の再起動を案内する。

参照した一次資料:

- https://github.com/rharish101/ReGreet/blob/0.5.0/regreet.sample.toml
- https://github.com/rharish101/ReGreet/blob/0.5.0/src/sysutil.rs
- https://github.com/rharish101/ReGreet/blob/0.5.0/src/gui/templates.rs
- https://github.com/NixOS/nixpkgs/blob/7dcdd87373d72e7a2173e4db02e20d3d7f495cfd/nixos/modules/programs/regreet.nix
- https://github.com/NixOS/nixpkgs/blob/7dcdd87373d72e7a2173e4db02e20d3d7f495cfd/nixos/modules/services/display-managers/greetd.nix


## ロック画面風のシンプルなログイン（2026-11-06）

- `home/desktop/lock.nix`の構成に合わせて、大きな中央時計、ユーザー名、シアン／青紫の枠の入力欄を配置した。カード枠とセッション選択表示を外し、電源操作は下部の小さなテキストボタンにした。
- ReGreet 0.5.0へ`assets/regreet/lock-layout.patch`を適用して実ビルド成功。変更対象はGTKテンプレートと表示制御のみ。`src/client.rs`、PAM、認証モデル、セッション開始処理は変更していない。Cargoの書き込み先はビルド用一時ディレクトリに限定した。
- 最終構成の`system-contract`ビルド成功。時計の`%H:%M`、ユーザー／セッションを記憶する`skip_selection = true`を生成結果から確認した。
- ぼかし壁紙をビルド時に生成し、最終構成のCSSと同一のCSSをデモで読み込んで描画確認した。実際のNoto Sans CJK JPとJetBrainsMono Nerd Fontで日本語ボタンと時計を確認した。
- 最終ビルドのReGreetを使い、検証専用AccountsServiceと`/bin/true`のセッションで、Enterによるユーザー選択→デモOTP→Passwordの表示遷移、誤入力時のエラー／認証キャンセル、正しいデモ入力後のセッション開始成功まで確認した。秘密入力はプロンプトごとに選択して置き換えた。これらはデモ認証であり、実機のPAM検証ではない。
- `docs/login-preview.png`はデモのPassword入力画面。実機のWayland・PAM・Hyprland起動の確認は対象端末で必要。適用方法は引き続き`nixos-rebuild boot`後の再起動。


## GCC・英語ログイン・バッテリーメニュー（2026-11-09）

- `home.packages`へ固定NixpkgsのGCCを追加。GCC 15.3.0で`-Wall -Wextra -Werror`を付けたCプログラムを実際にコンパイルし、生成物の実行を確認した。
- ReGreet 0.5.0のレイアウト差分を更新して実ビルド成功。入力欄の右に`go-next-symbolic`のLog inボタンを配置し、Back/Reboot/Power offなどの表示を英語化した。greetdとgreeterはC.UTF-8で起動し、セッション開始時はOSのデスクトップ用LANGへ戻す。日本語キーボードは維持する。
- 最終ReGreetを仮想Xサーバーと検証用AccountsServiceで起動し、矢印のマウスクリックによる認証開始・デモOTP入力・Password入力後の矢印クリック・デモセッション開始成功を確認した。`docs/login-preview.png`を更新した。実機のPAM認証やWaylandの検証ではない。
- PowerCardを分離し、UPowerの集約デバイスから％・TimeToEmpty・TimeToFullを表示する。モード説明文を削除し、残り時間が未知・充電中・満充電・バッテリー不在の場合を区別する。モードごとの架空の稼働時間は表示しない。
- バーは`custom/battery`のJSONモジュールへ変更。横向きFont Awesomeバッテリーを約24px相当で表示し、通常の％テキストは12pxのままにした。UPowerのGetAllを10秒ごとに参照し、％設定の変更時は同じユーザーのWaybarにSIGRTMIN+9を送って即時更新する。
- ％設定の原子的保存・破損時の既定値・表示切替・充電／放電／満充電・不明な推定時間・低残量色・半端な％の丸め・短い時間のツールチップのマークアップを含むPythonの11テストが成功した。実際のNixラッパーでも設定のオフ／オンと再読込を確認した。
- 検証用のUPower D-Busモックに対し、実装したGetAll呼出しから68％・残り3時間30分を取得できることを確認した。モックはTCPの匿名認証を使う検証専用構成で、実機は通常のシステムD-Bus認証を使う。
- Quickshell実行ファイルでPowerCardの描画、推定値変更時の反映、バッテリー消失時の状態、スイッチを実際にクリックしたオフ／オンを検証した。既存の音楽カードのテストも成功した。offscreen環境ではWayland PanelWindowのバックエンドは利用できないため、実際のオーバーレイ配置とハードウェア上の電源モード切替は実機確認が必要。
- NixOS/Home Managerのsystem-contractはGCC・Waybarの設定・greetdの英語ロケールとセッションロケール復元を含めて検証する。flake.lockと実機のディスク／ブート設定は変更していない。

参照:

- https://quickshell.org/docs/v0.3.2/types/Quickshell.Services.UPower/UPowerDevice/
- https://quickshell.org/docs/v0.3.2/types/Quickshell.Services.UPower/UPowerDeviceState/
- https://quickshell.org/docs/v0.3.2/types/Quickshell.Services.UPower/UPower/
- https://github.com/Alexays/Waybar/blob/master/man/waybar-custom.5.scd

## Vim（2026-11-09 UTC）

- `home/programs/development.nix`からVim専用モジュールを読み込み、fzf.vim・Fugitive・GitGutter・Surround・Commentary・vim-nixをNixで導入。既存の`EDITOR=nano`とflake.lockは変更していない。
- `checks.x86_64-linux.vim`のビルド成功。生成した実際のVimラッパーを一時HOMEで2回起動し、設定値、検索/Git/コメントコマンド、fzf実行ファイル、GitGutterの読み込み、Nixのファイルタイプと2文字インデントを確認した。
- Vim内でCの行コメントの追加・解除、単語を引用符で囲む編集も確認。Undoディレクトリの作成と再利用を確認した。
- `system-contract.drvPath`の評価も成功し、Vimの有効化とHome Managerパッケージへの登録、既存モジュールとの統合を確認した。
- 実機の端末描画、対話的なfzf選択、クリップボード連携は対象端末で確認する。実機のシステム全体のビルド・適用は行っていない。

## ORBITショートカット（2026-11-09 JST）

- QuickShellに左上の画像タイルと、6件ずつ四分円状に展開するランチャーを追加。初期画像・一覧はリポジトリで管理し、初回適用時だけユーザー用のJSONをコピーする。既存JSONは再構築で保持する。
- `checks.x86_64-linux.quickshell`のビルド成功。実際のQuickShell 0.3.2のoffscreen描画で初期JSON、開閉アニメーション終了、アプリ一覧の変更、不正JSONから直前の設定を保持する動作を確認。既存のMusicCard・PowerCard・バッテリーテストも成功。
- ソフトウェア描画の画像を確認し、アイコンの配置間隔を調整した。検証環境にはデスクトップアプリが導入されていないため、アプリアイコンは代替文字で描画した。実機ではDesktopEntriesからアイコン・起動コマンドを取得する。
- `system-contract.drvPath`の評価成功。実機のWayland左上配置、アプリの実起動、GPUによる任意画像の角丸マスクは実機確認が必要。コンテナではIPC用Unixソケット作成不可、offscreenはウィンドウマスク非対応の警告が出るが、UIと編集のテストは成功している。

## ORBITの背景透過・ノード接続（2026-11-09 JST）

- ランチャーをWaylandのBottomレイヤーへ変更し、通常のアプリウィンドウが手前に表示される構成にした。背景パネル・見出しを除去し、画像タイル→アプリアイコンを細いシアンの線で接続する。線は展開時の各アイコン位置に追従し、毎フレーム消去して描き直す。
- 入力領域を画像タイル、展開中のアプリアイコン、必要なページ操作部だけに限定した。透過部分は下のデスクトップへクリックを通す。
- `checks.x86_64-linux.quickshell`のビルド成功。既存の開閉・設定更新・音楽・電源テストとQML解析が成功し、offscreenで透過描画を確認した。Wayland上の重なり順とクリック透過は実機で確認する。

## 月タイル拡大・放射状接続（2026-11-09 JST）

- 月タイルを64pxから96pxに拡大。アプリタイル62px・内部アイコン32pxは維持し、月の中心から各アプリへ直接線を伸ばす形へ変更した。
- QuickShellチェックのビルドと開閉・設定更新テストが成功。offscreen描画でも月の拡大と放射状の線を確認した。
