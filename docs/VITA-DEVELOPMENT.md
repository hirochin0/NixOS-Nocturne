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

再現に必要なソースはアプリ側、環境管理の方針は両方のAGENTS.mdに保存する。アプリのGitHub保存先はユーザー未作成。APKやゲームの素材はこのdotfilesへ置かない。現段階のアプリはSDK検証用でありGrow Castleの移植完了ではない。

この文書とAGENTS.mdのみの反映にはnixos-rebuildは不要。今後システム設定を変えた場合は、検証後 `sudo nixos-rebuild switch --flake path:$HOME/NixOS-Nocturne-0571#nocturne` で適用する。実ホスト名nixosとflake構成名nocturneは異なるため混同しない。

## 検証結果（2026-11-05 JST）

Nix 2.34.9でアプリのnix buildとnix develop経由のCMakeビルドが成功。GCC 15.2.0、ELF32 ARM EABI5 hard-float、SELF、VPK生成とunzip -tを確認。実機動作は未確認。dotfilesは文書のみの変更であり、既存lockとシステム設定は変更しない。既存のhosts/nixos/base/configuration.nixの未commit変更は含めない。
