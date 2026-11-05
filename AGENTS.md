# 環境変更の保存ルール

- パッケージ、環境変数、PATH、シェル、サービス、権限、VS Code等の永続的な環境変更は、このNixOS-Nocturneの適切な管理元ファイルへ反映し、検証してcommit・pushする。ローカルだけ動く状態は完了ではない。
- 通常のfast-forward push（mainを含む）はユーザーが許可済み。remoteのowner・repository・branchを確認し、force pushや無関係な変更の混入をしない。
- 認証・権限等でpushできない場合はローカルcommitまで保存し、未反映であることと原因を報告する。
- 生成先や/nix/storeを直接編集せず、元の.nixや管理元を編集する。手動導入、一時export、nix-shellだけで完了しない。
- 既存の未commit変更を保護する。特に実機のhosts/nixos/base/設定を確認せずcommitしない。秘密・認証情報を追加しない。
- 普段使う開発ツールはhome/programs/development.nix、プロジェクト固有SDKと依存はプロジェクトの開発環境定義へ置く。両者の関係と起動方法を文書化する。
- 既存flake.lockを無関係に更新しない。確認していないパッケージ名やオプションを書かない。
