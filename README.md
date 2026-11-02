# NOCTURNE — NixOS × Hyprland

濃紺の背景、青紫とシアンのアクセント、浮いた3分割バー、柔らかい角丸と影。
静止画壁紙付き。Waybar / Fuzzel / Mako / Kitty / Hyprlock を揃えたモジュール構成です。
日本語キーボード・Mozc・Fish を標準にしています。

## 対象と前提

- **既にインストール済みの NixOS x86_64-linux** 向け。CachyOSへそのまま適用する設定ではありません。
- 入力は **nixos-26.05 / Home Manager release-26.05**。Hyprland **0.55系のLua API** を使用し、範囲外なら評価を止めます。
- 以後のHyprland更新時はLua APIの互換性を確認してください。
- ハードウェア・ブートローダー・ディスク・Secure Bootは、コピーした元の設定を使います。
- 元からあるユーザーを利用してください。この一式にはパスワード設定は含みません。
- 既存 Home Manager / Caelestia / Waybar / 他デスクトップ設定との併用・統合は、重複モジュールと自動起動の整理が必要です。
- Nixのない作成環境のため **Nix評価・ビルド・実機起動は未検証**。下記のbuildとtestを通してからswitchしてください。

## ファイルの役割

| ファイル / ディレクトリ | 変更する内容 |
|---|---|
| `user.nix` | ユーザー名、キーボード、モニタ、ログイン画面の利用 |
| `theme.nix` | 主な配色、角丸、フォント、壁紙へのパス |
| `flake.nix` | Nixpkgs・Home Managerの入力とホスト定義 |
| `hosts/nixos/base/` | 現在の `/etc/nixos/` 一式を置く場所 |
| `modules/nixos/desktop.nix` | Hyprland、音声、Bluetooth、権限 |
| `modules/nixos/japanese.nix` | Fcitx5 + Mozc |
| `home/desktop/hypr/binds.lua` | キーバインド |
| `home/desktop/` | ウィンドウ、バー、通知、ランチャー、ロック |
| `home/programs/` | Kitty、Fish、Starship |
| `home/scripts.nix` | スクリーンショット、ロック、電源メニュー |
| `assets/wallpaper.png` | 同梱する幾何学の静止画壁紙 |

色は `theme.nix` を変更すると各UIへ反映します。GTKアプリはadw-gtk3-dark、壁紙は静止画なので、色の変更に合わせて自動生成しません。

## 導入

展開した `nixos-nocturne` をホームディレクトリに置いてください。
以下はbashで実行する例です（Fishなら先に `bash` を起動）。

### 1. 元の設定を保存し、この構成に取り込む

```bash
cd ~/nixos-nocturne
sudo cp -a /etc/nixos "/etc/nixos.backup-$(date +%Y%m%d-%H%M%S)"
sudo cp -a /etc/nixos/. hosts/nixos/base/
sudo chown -R "$(id -u):$(id -g)" hosts/nixos/base
```

`base/configuration.nix` の案内用 `throw` が元ファイルで置き換わったことを確認します。
`hardware-configuration.nix` や相対参照先も、同じディレクトリ構造でコピーされます。
元設定に `/etc/nixos/...` の絶対参照がある場合は、この構成内への相対参照へ修正してください。
元がFlakeだけで構成され、configuration.nix単体では完結しない場合は、元Flakeのinputs・specialArgs・modulesも統合する必要があります。
シークレットや鍵を含むbaseディレクトリは公開しないでください。

### 2. 最低限の変更

`user.nix` の `name` を **現在使っているログイン名** に変更します。`id -un` で確認できます。
既存のHome Manager利用者は `homeStateVersion` を元の値へ変更します。
`system.stateVersion` はコピーした元設定の値をそのまま維持してください。

モニタは自動認識が初期値です。個別指定する場合は `hyprctl monitors` で名前を調べ、`monitors` を編集します。
US配列なら `keyboardLayout = "us";` に変更します。
VRRは初期値で無効です。必要なら `hyprland.nix` の `vrr` を変更します。

元設定の次の重複を確認します。

- 既存のHome Managerモジュール・設定は今回の `home/` と統合する。
- PulseAudio単体を使っていたら、その有効化を外してPipeWireと競合しないようにする。
- 既存のHyprlandやCaelestiaの起動設定・パネル・通知サーバーの二重起動を取り除く。
- 既存 `~/.config/hypr/hyprland.conf` がある場合はバックアップへ移す。この構成は `hyprland.lua` を使う。
- 既存のHome Manager管理対象ファイルはバックアップしてから整理する。管理外の同名ファイルがあると有効化を止める場合がある。

### 3. 入力の固定とビルド

```bash
nix --extra-experimental-features 'nix-command flakes' flake lock
nix --extra-experimental-features 'nix-command flakes' flake check path:.
nix --extra-experimental-features 'nix-command flakes' build path:.#nixosConfigurations.nocturne.config.system.build.toplevel
```

`hostName` を変えた場合は、コマンドの `nocturne` も変更します。
初回の `flake.lock` は利用するマシンで生成します。検証した `flake.lock` を設定と一緒に保存すると、入力リビジョンを再現できます。
この配布には、取得できていないリビジョンを埋めたlockは含めません。
ビルド時のエラーを解消してから次へ進みます。

### 4. 一時適用 → 永続適用

```bash
sudo nixos-rebuild test --flake path:.#nocturne
```

一度ログアウトし、ログイン画面で **Hyprland (uwsm-managed)** を選びます。
既存ログイン画面がない場合はTTYログイン後に次を実行します。

```bash
uwsm start hyprland-uwsm.desktop
```

画面・キーボード・ネットワーク・音声・日本語入力・ロック解除を確認してから、永続適用します。

```bash
sudo nixos-rebuild switch --flake path:.#nocturne
```

`test` は次回起動の既定を変更しません。ただし、Home Managerのファイル変更はホーム側に残る場合があります。
設定エラー時はTTY（Ctrl+Alt+F3）から修正できます。`switch` 後の問題では `sudo nixos-rebuild switch --rollback` またはブートメニューから以前の世代へ戻れます。

### ログイン画面が必要な場合

`enableGreetd = true;` にします。既存SDDM/GDMなどは、コピーしたbase設定で無効化してから有効にしてください。
自動ログインは設定していません。

## 操作

| キー | 動作 |
|---|---|
| Super + Enter | Kitty |
| Super + B / E | Firefox / ファイル管理 |
| Super + D | アプリ検索 |
| Super + Q | ウィンドウを閉じる |
| Super + F / Space | 全画面 / フロート切替 |
| Super + 矢印 | フォーカス移動 |
| Super + Shift + 矢印 | ウィンドウ移動 |
| Super + 1〜9 | ワークスペース移動 |
| Super + Shift + 1〜9 | ウィンドウを指定ワークスペースへ移動 |
| Super + 左ドラッグ / 右ドラッグ | 移動 / リサイズ |
| Super + L | ロック |
| Super + Shift + E | セッション・電源メニュー |
| Print / Super + Shift + S | 範囲選択スクリーンショット・クリップボードへコピー |
| Super + Shift + R | Hyprland設定の再読み込み |

日本語入力はFcitx5設定画面でMozcを選び、切替キーを確認してください。アプリによってWayland IME対応に差があります。
5分無操作でロック、10分で画面オフ。自動サスペンドは設定していません。
画面キャプチャは `~/Pictures/Screenshots/` に保存します。

## 日々の編集

`user.nix` / `theme.nix` / モジュールを編集し、`nix build` → `nixos-rebuild test` → 確認 → `switch` の順で適用します。
Home ManagerはNixOSに統合しているため、別途 `home-manager switch` は不要です。
`hyprctl reload` だけではNixソースの変更は反映しません。
更新する際だけ `nix flake update` を実行し、再ビルドして確認してください。

## Git管理

通常のGit管理を始める場合は、評価に必要なコピー済みbaseファイルも追加する必要があります。
`.gitignore` では意図的にbaseの大部分を除外しているため、機密がないと確認した設定ファイルを `git add -f` で追加します。
未追跡ファイルは通常のGit Flake評価から見えません。上の手順では `path:.` を使って作業ツリーを参照しています。

## 調査用

```bash
hyprctl version
hyprctl configerrors
systemctl --user --failed
journalctl --user -b -u waybar
journalctl --user -b -u hypridle
```

## 公式資料

- https://nixos.org/blog/announcements/2026/nixos-2605/
- https://wiki.hypr.land/nix/installing-hyprland-on-nixos/
- https://wiki.hypr.land/useful-utilities/uwsm/
- https://wiki.hypr.land/0.55.0/Configuring/Basics/Dispatchers/

## 検証範囲

同梱前にNixの区切り記号、ローカル参照、スクリプトのbash構文、Lua構文、壁紙の読み込み、ZIP整合性を静的確認しています。
この確認はNixの構文解析・オプション評価・パッケージ取得・Hyprlandの実起動を代替しません。
Nixがないため `flake.lock` 生成・`nix flake check`・`nix build` は利用マシン側の作業です。
