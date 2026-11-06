# PS Vita開発

アプリの作業場所は `/home/hiroto/work/vita/growcastle`。VitaSDKとCMake等のビルド依存はアプリ側の `flake.nix`、`flake.lock`、`nix/vitasdk.nix` で管理する。SDKをグローバルにインストールしたり、fishやHome ManagerへVITASDK/PATHを固定したりする必要はない。

普段使うGitは `modules/nixos/desktop.nix`、VS Codeは `home/programs/development.nix` で既に宣言済み。今回、新たなシステムパッケージ・サービス・権限は追加しない。

```bash
cd ~/work/vita/growcastle
nix build path:.
nix develop path:. --command cmake -S . -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
nix develop path:. --command cmake --build build
nix develop path:. --command code .
```

VS Codeの既存プロセスが環境を引き継がない場合は全ウィンドウを終了してから最後のコマンドを実行する。プロジェクトの既定ビルドタスクもnix buildを呼ぶ。

NixpkgsはNocturneの固定済み26.05リビジョン `7dcdd87373d72e7a2173e4db02e20d3d7f495cfd` と一致させた。Nocturneのlock変更は不要。VitaSDKはこのNixpkgsのpkgs/lib内を検索して定義がないことを確認し、公式core 2026.08.1-1をハッシュ固定してNix用にパッケージ化する。

再現に必要なソースはアプリ側、環境管理の方針は両方のAGENTS.mdに保存する。アプリのGitHub保存先はユーザー未作成。APKやゲームの素材はこのdotfilesへ置かない。現段階のアプリは基本戦闘の試作でありGrow Castle全体の移植完了ではない。

この文書とAGENTS.mdのみの反映にはnixos-rebuildは不要。今後システム設定を変えた場合は、検証後 `sudo nixos-rebuild switch --flake path:$HOME/NixOS-Nocturne-0571#nocturne` で適用する。実ホスト名nixosとflake構成名nocturneは異なるため混同しない。

## 検証結果（2026-11-05 JST）

Nix 2.34.9でアプリのnix buildとnix develop経由のCMakeビルドが成功。GCC 15.2.0、ELF32 ARM EABI5 hard-float、SELF、VPK生成とunzip -tを確認。実機動作は未確認。dotfilesは文書のみの変更であり、既存lockとシステム設定は変更しない。既存のhosts/nixos/base/configuration.nixの未commit変更は含めない。

## Grow Castle再実装と素材抽出（2026-11-05 JST）

アプリ側にVitaSDK製の基本戦闘（敵の接近・弓兵の射撃・勝敗・強化・HP/MP・セーブ）と、ユーザーのXAPKから元画像をローカル生成する仕組みを追加した。原作全体の移植完了ではない。

追加した開発依存はプロジェクト固有のため、アプリ側の `nix/asset-tools.nix` と `nix/unitypy-wheels.json` にUnityPy 1.23.0および全11 wheelのURL・バージョン・SHA-256を固定した。ホスト用GCC、CMake、PythonもアプリのdevShellで管理する。手動pip導入、グローバルPATH変更、サービスや権限の追加は行わない。このdotfilesの既存flake.lockとシステム設定は変更不要。

```bash
cd ~/work/vita/growcastle
nix develop path:. --command python tools/build_local.py \
  '/home/hiroto/Downloads/Grow+Castle+-+Tower+Defense_1.51.10_APKPure.xapk'
# 元画像入り成果物: local/growcastle.vpk
nix build path:.#checks.x86_64-linux.game-logic --out-link local/check-result
```

通常の `nix build path:.` は元画像を含まないコードのVPKを作る。ゲーム画像入りVPKは上記のローカル手順を使用する。入力XAPKのハッシュを検証し、抽出素材・元データ・画像入りVPKはGitから除外する。Vita上のセーブ先は `ux0:data/growcastle/save.dat`。操作はアプリREADME参照。Vita向けクロスビルド、PCで同じ描画コードによるプレビュー、AddressSanitizer/UndefinedBehaviorSanitizer付きのゲーム・画像ローダ検査に成功した。実機の起動/入力/描画速度/セーブは未確認。

解析で確認した原作の値と仮の仕様はアプリ側 `docs/REIMPLEMENTATION.md` に区別して記録する。城の基礎HP/MPは実APKのARMコードから確認した式を反映。強化費用・ウェーブ編成・多数のヒーロー/スキル等はまだ原作と一致しない。

この変更もプロジェクト定義と手順の追加のみで、システム適用のrebuildは不要。アプリ側GitHubリポジトリは未作成であり、ソースはローカルGitへ保存する。

## タッチ操作・素材入りVPKの既定化（2026-11-06 JST）

Grow Castleの基本操作をVita前面タッチへ統一。SceTouch APIは固定SDKに含まれるものを使用するため、ホストのパッケージや権限追加は不要。プロジェクトのsrc/ui.cで操作可能状態・モーダル・タッチ領域を描画と共有する。

以前のresult/growcastle.vpkをユーザーがインストールし、素材がないエラーになったと確認できた。VS Codeの既定タスクを、アプリ側tools/build_local.pyによる元画像入りlocal/growcastle.vpkの生成へ変更した。CMakeのゲームVPKは素材パックの指定が必須。生成した最終VPKから素材を抽出し、Vitaと同じCローダで必須画像を検証する。

通常のnix buildは今後 `result/growcastle-code-check.vpk` を生成し、アプリ名Grow Castle Code Check・タイトルID HROT00003でゲームHROT00002と分離する。元画像入りゲームは従来と同じ下記の方法で生成して上書きインストールする。セーブ先は維持する。

```bash
cd ~/work/vita/growcastle
nix develop path:. --command python tools/build_local.py \
  '/home/hiroto/Downloads/Grow+Castle+-+Tower+Defense_1.51.10_APKPure.xapk'
# インストールするもの: local/growcastle.vpk
```

変更箇所はアプリ側のNix/CMake定義・ビルドタスク・コードと手順。既存flake.lock、Home Manager、システム設定の変更やnixos-rebuildは不要。タッチの座標変換・長押し・ドラッグ・複数指・強化・戦闘・pause・終了メニューと素材欠落のテストを追加した。Vita上のタッチ位置と素材読み込みの最終確認は実機で行う。読込診断はux0:data/growcastle/assets-load.logへ保存する。

## ネイティブ実装のカテゴリ分割と書式管理（2026-11-06 JST）

アプリCコードをplayer / enemy / castle / battle / ui / persistence / platform/vita等へ分割し、1処理関数につき1ファイルで管理する。旧game.c/render.c/ui.cの実装は移動し、公開ヘッダは入口として維持する。アプリ側docs/NATIVE-PORT.mdとdocs/PORT-COVERAGE.mdに構成、原作との対応、未実装を記録した。オンライン・クラン/ギルド・ランキングは保留。

共通の開発ツールとしてhome/programs/development.nixにpkgs.clang-toolsとpkgs.ruffを追加した。固定済みNixpkgsでclang-format 21.1.8 / Ruff 0.15.14の実在とバージョンを確認し、Home Managerのhome.packages評価も成功した。アプリのdevShellにも同じ固定集合のツールを含め、Codexの整形/検証はnix developを通す。flake.lockの変更は不要。

```bash
cd ~/work/vita/growcastle
nix develop path:. --command python tools/format_source.py
nix build path:.#checks.x86_64-linux.source-style --out-link local/style-check
nix build path:.#checks.x86_64-linux.game-logic --out-link local/game-check
```

通常環境にも追加したフォーマッタを適用する場合は、本人のsudo操作で次を実行する。プロジェクトのnix developは適用前でも利用できる。

```bash
sudo nixos-rebuild switch --flake path:$HOME/NixOS-Nocturne-0571#nocturne
```

元のUnity TextAssetから52敵・289ユニット・224スキルの基礎値をアプリ側tools/export_catalog.pyでネイティブ形式へ変換し、素材入りVPKのassets/catalog.gcdに含める。Cローダで最終VPKからの読込を検証する。カタログの存在と全能力の実装完了を混同しない。城・弓兵の基礎強化費用は元APKのARMコードの式へ反映した。完全移植と実機検証は引き続き未完了。

元APK・画像・カタログ・ダンプはアプリのlocal/へ生成しGitから除外する。再現用スクリプト・Nix定義・書式設定・コード・文書のみを保存する。既存のhosts/nixos/base/configuration.nixの未commit変更はこの変更に含めない。
