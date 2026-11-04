# NOCTURNE — NixOS 26.05 / Hyprland 0.57.1

濃紺・青紫・シアンのHyprland環境。NixOSの土台は26.05のまま、Hyprlandは公式リリースv0.57.1とその依存リビジョンに固定しています。

## 追加機能とアプリ

- タッチパッドの3本指左右スワイプでワークスペースを切り替えます。Hyprland 0.57.1の`hl.gesture`を使用します。
- 壁紙はswww 0.11.2。UWSMセッションの開始時だけdaemonを起動し、終了時に止めます。
- Super+W、またはアプリ一覧の「Wallpaper」でサムネイル付きの3列グリッドを開きます。`~/Pictures/Wallpapers`にPNG/JPEG/WebP/GIF/BMPを置き、文字入力で検索、矢印キーで移動、Enterで選択、Escapeでキャンセルします。サブフォルダも対象です。壁紙メニューだけWayland対応rofiを使い、通常のアプリ検索は従来どおりです。
- サムネイルは480×270に縮小して`~/.cache/nocturne/wallpaper-thumbnails/`へ保存します（`XDG_CACHE_HOME`設定時はそちら）。変更した画像は自動で作り直し、GIFは先頭フレームを表示します。適用時は元画像・元GIFをswwwへ渡します。プレビューを作れない画像は代替画像で表示します。
- 選択を`~/.local/state/nocturne/wallpaper.json`へ保存し、次のログイン時に復元します（`XDG_STATE_HOME`設定時はそちら）。元画像を移動・削除するとNixで指定した既定画像へ戻ります。
- Codex CLI、VS Code、Google Chrome、オリジナルのNeofetch 7.1.0を導入します。Super+BでChromeを開きます。
- アプリ一覧の「ChatGPT」は公式サイトをChromeの独立ウィンドウで開きます。Codexはターミナルで`codex`を実行します。

VS Codeは公式Marketplaceの拡張機能を使いやすいため採用しました。エディタ本体はNixで更新し、テレメトリはオフにしています。VS CodeとChromeの非自由ライセンス許可は、この2パッケージに限定しています。

`neofetch`は現在のnixpkgsから削除されているため、上流の最終公開版を`flake.lock`で固定して独自パッケージ化しました。また現在のnixpkgsの`swww`は`awww`への別名なので、指定どおり元のswwwを使うため公式v0.11.2を固定しています。

Codexの初回ログインだけ、本人の操作で行います。認証情報はNixファイルに書きません。

```bash
codex login
codex
```

## 動作中の0.57.1構成を更新

実機設定を入れてビルドしたフォルダを使います。今回の環境では`~/NixOS-Nocturne-0571`です。次を1行ずつ実行し、エラーがあれば止めます。

```bash
cd ~/NixOS-Nocturne-0571
git pull --ff-only
sudo nixos-rebuild test --flake path:.#nocturne
hyprctl reload
systemctl --user restart nocturne-wallpaper.service
```

3本指スワイプ、Super+W、`swww query`、`codex --version`、`code --version`、`google-chrome-stable --version`、`neofetch --version`を確認したら永続適用します。

```bash
sudo nixos-rebuild switch --flake path:.#nocturne
```

初回はswwwのビルドやChrome/VS Codeのダウンロードに時間がかかる場合があります。`git pull`がローカル変更との競合で止まったら、その変更を確認してから統合してください。

## 再現性と編集先

| 編集先 | 管理するもの |
|---|---|
| `home/programs/development.nix` | Codex・VS Code・Chrome・Neofetch、エディタ設定 |
| `home/desktop/wallpaper.nix` | swwwサービス、壁紙メニュー登録 |
| `lib/wallpaper-menu-theme.nix` | サムネイル選択画面の配置・配色 |
| `home/desktop/hypr/input.lua` | 3本指ジェスチャー |
| `theme.nix` | 再現する既定壁紙、色、フォント |
| `assets/` | Gitで管理する既定壁紙の画像 |
| `flake.lock` | 正確なソースリビジョンとハッシュ |

アプリの追加・削除は`.nix`に書いてrebuildします。`nix-env`や`npm install -g`による手動インストールは不要です。更新は`flake.lock`を意図的に更新したときだけ行います。壁紙UIでの選択と各サービスへのログインはユーザーごとの実行時の状態です。別PCでも同じ既定壁紙にしたい場合は、画像を`assets/`へ追加し、`theme.nix`の`wallpaper`を変更してGitへ保存します。実機のディスク設定とユーザー名は従来どおり`hosts/nixos/base/`と`user.nix`で管理します。

## 修正の内容

- `flake.lock`を同梱し、Hyprland v0.57.1・XDPH・Mesaを上流の同じ依存集合から取得します。Home Managerはrelease-26.05です。
- Kittyもその依存集合から取得し、Home Managerがインストールする実体とSuper+Enterが呼ぶ実体を一致させます。新しいMesaを古いlibcのKittyへ動的ロードする組み合わせを避けます。
- 配色やモニタはNixの値から`lib.generators.toLua`で生成します。Luaの文字列へNixの式を手入力する必要はありません。
- グラデーションはLuaのテーブル、タッチパッドは`tap_to_click`を使い、削除された`dwindle.pseudotile`は設定しません。
- キーバインドを装飾より先に登録します。ターミナル等のコマンドはNix storeの絶対パスで指定します。
- 生成ファイルはビルド時に`luac -p`と、採用したHyprland自身の`--verify-config`を通します。設定キーやdispatcherが無効なら適用前のビルドで停止します。
- UWSMの起動入口を`hyprland.desktop`に揃え、バー・壁紙・idle・通知・polkitを`wayland-session@hyprland.desktop.target`へ結び付けます。別DEでの二重起動を避けます。
- Home Managerのセッション変数を`uwsm/env`から読み込みます。
- dconfを無効にしません。HMの設定適用だけは既存バスを引き継がず、標準の`dbus-run-session`経路を利用します。古いユーザーセッションのサービス検索パスへの依存を避け、GTKのフォント・アイコン・カーソル・ダークモードを反映します。

## 管理するファイル

| ファイル | 用途 |
|---|---|
| `user.nix` | ログイン名、モニタ、キーボード、Home Manager初期バージョン |
| `theme.nix` | 配色、フォント、壁紙、角丸 |
| `flake.nix` / `flake.lock` | パッケージと固定リビジョン |
| `lib/desktop-packages.nix` | Hyprland、XDPH、Mesa、Waybar等の取得元 |
| `home/desktop/hypr/` | メインLua、外観、入力、キーバインド |
| `lib/hyprland-config.nix` | 型付きLua生成とHyprlandによる実検証 |
| `home/desktop/dconf.nix` | 設定適用時のD-Busライフサイクル |
| `hosts/nixos/base/` | 実機の既存NixOS設定。公開前に機密を確認 |
| `checks/` | モジュール連携評価、D-Bus設定反映のテスト |

## 既存のNOCTURNEから更新

手元には修正途中のファイルがあるため、既存フォルダを残し、新しいフォルダへcloneする方法を推奨します。
既存の`~/NixOS-Nocturne`内で、次を順に実行します。

```bash
git clone https://github.com/hirochin0/NixOS-Nocturne.git ../NixOS-Nocturne-0571
cp user.nix ../NixOS-Nocturne-0571/user.nix
cp -a hosts/nixos/base/. ../NixOS-Nocturne-0571/hosts/nixos/base/
cd ../NixOS-Nocturne-0571
```

新しいcloneには、現在のユーザー・モニタ設定と実機のbase設定だけを取り込みます。
古いリポジトリはそのままバックアップとして残ります。`NixOS-Nocturne-0571`が既にある場合、別の新しいフォルダ名を使ってください。

この後、下記の「ビルドと確認」を進めます。`user.nix`とbase以外に独自の設定がある場合は、元フォルダと差分を確認して移してください。

## 初回導入の準備

NixOSをインストール済みの環境が対象です。UEFI、Windowsとのデュアルブート、ディスク、カーネル等は既存設定を引き継ぎます。

1. リポジトリをcloneし、そのディレクトリへ移動します。
2. 既存`/etc/nixos`全体を別の場所へバックアップします。
3. `/etc/nixos/.`を`hosts/nixos/base/`へディレクトリ構造ごとコピーします。既存のconfiguration.nixで案内用throwを置き換えます。
4. `user.nix`の`name`を現在のログイン名へ変更します。このリポジトリの既定値は`hiroto`です。
5. 既存利用者はHome ManagerのstateVersionを維持します。system.stateVersionも元の値を変えません。
6. 元設定のHome Manager、Hyprland、通知、PulseAudio単体などの重複を整理します。既存DMは利用できます。`enableGreetd`は既存DMがない場合だけ有効にします。

既存設定がFlakeのinputsやspecialArgsに依存する場合は、その依存も統合する必要があります。公開リポジトリには実機のbase設定が含まれていないため、こちらでは実機のシステム全体は検証できません。

## ビルドと確認

TTYまたは現在のKDE/GNOMEから、リポジトリ内で実行します。初回だけ、公式Hyprlandバイナリキャッシュの設定も読み込むためrootでビルドします。

```bash
sudo nix --extra-experimental-features 'nix-command flakes' --accept-flake-config build path:.#checks.x86_64-linux.hyprland-config --out-link config-result
sudo nix --extra-experimental-features 'nix-command flakes' --accept-flake-config build path:.#checks.x86_64-linux.dconf-activation --out-link dconf-result
sudo nix --extra-experimental-features 'nix-command flakes' --accept-flake-config build path:.#nixosConfigurations.nocturne.config.system.build.toplevel
sudo ./result/bin/switch-to-configuration test
```

最後まで成功したら作業を保存し、ログアウトして`Hyprland (uwsm-managed)`を選びます。既存の古いHyprlandプロセスへ`reload`するだけでは、パッケージやUWSM環境は更新されません。

TTYから直接起動する場合は、他のグラフィカルセッションを終了してから次を実行します。

```bash
uwsm start -e -D Hyprland hyprland.desktop
```

`uwsm start hyprland-uwsm.desktop`は使いません。そのdesktop entry自体がUWSMを起動するラッパーだからです。

ログイン後に確認します。

```bash
Hyprland --version
hyprctl configerrors
systemctl --user status wayland-session@hyprland.desktop.target --no-pager
systemctl --user --failed
systemctl status home-manager-hiroto.service --no-pager
dconf read /org/gnome/desktop/interface/color-scheme
```

`configerrors`が空で、Super+Enter、Super+D、バー、壁紙、音声、Wi-Fi、日本語入力、ロックと解除を確認できたら永続適用します。

```bash
sudo nixos-rebuild switch --flake path:.#nocturne
```

`test`はブートの既定を変更しませんが、Home Managerのホーム内ファイルは変更されます。バックアップは残してください。

## 操作

| キー | 動作 |
|---|---|
| Super+Enter | Kitty |
| Super+D | アプリ検索 |
| Super+B / E | Google Chrome / Thunar |
| Super+W | 壁紙選択 |
| Super+Q | ウィンドウを閉じる |
| Super+F / Space | 全画面 / フロート |
| Super+矢印 | フォーカス |
| Super+Shift+矢印 | ウィンドウ移動 |
| Super+1〜9 | ワークスペース |
| Super+Shift+1〜9 | 指定ワークスペースへ移動 |
| Super+左/右ドラッグ | 移動 / リサイズ |
| Super+L | ロック |
| Super+Shift+E | 電源メニュー |
| Print / Super+Shift+S | 範囲スクリーンショット |
| 明るさキー / Super+F5・F6 | 内蔵画面を5%ずつ暗く / 明るく |

Waybarの太陽アイコンには内蔵画面の明るさ（%）を表示します。アイコン上で上スクロールすると明るく、下スクロールすると暗くなり、キー操作による変更も表示に反映されます。ThinkPadのF5/F6はFn Lockの状態によりFnとの同時押しが必要です。Super+F5/F6でも操作できます。

キー操作とバーは`lib/brightness.nix`の同じコマンドを使用し、`backlight`クラスを自動選択します。デバイス名を固定せず、キーボード照明は変更しません。最低値はハードウェアの1段階です。権限はNixOSのudevルールと`video`グループで管理するため、毎回sudoを使う必要はありません。外部HDMI/DisplayPortモニターの明るさは別途DDC/CI対応が必要です。

既存環境に初めて適用した際は、rebuild後に`sudo udevadm trigger --subsystem-match=backlight --action=add`を実行すると、接続済みバックライトにも権限を反映できます。以後の起動時は自動適用されます。

## 検証範囲

詳細は`docs/VALIDATION.md`を参照してください。GPU・画面・実機のログイン・Windowsとの起動切替は対象マシンで確認が必要です。

## Git管理

`.gitignore`はbaseのハードウェア設定等を意図的に除外しています。Git Flakeには追跡済みファイルしか含まれないため、ローカル全体の検証では`path:.`を使います。

公開するのは機密がないと確認したファイルだけにしてください。`flake.lock`は生成済みのものを保存し、更新時だけ意図的に変更します。
