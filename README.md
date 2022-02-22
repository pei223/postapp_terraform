# Postapp terraform
このリポジトリのアプリをAWSにデプロイする用のterraform。

https://github.com/pei223/springboot-post-app-sample

## 処理の流れ
1. VPCなどの基本リソース、DB周りセットアップ
2. DBセットアップを手動で実行
3. ECRにリポジトリを作成し、springboot-post-app-sampleリポジトリでDocker imageビルド、push
4. backend_ecsのcontainer_definitions/imageのURLを3.で作成したECRのURLに変更する
5. ALB/ECSでデプロイ


# 手順
## tfvarsファイル作成
variables.tfのdb_master_usernameから下の変数を指定したtfvarsファイルをstg配下に作成。


## DB関連を先にapply
DB関連ファイルだけapplyするpythonスクリプトを実行。

```
python .\apply_about_db.py --files=vpc.tf,db_bastion.tf,rds.tf -var-file=secretvar.tfvars
```

## DBセットアップ
setup_db.mdを参照

## ECRにdocker image push
1. ECRリポジトリ作成
2. springboot-post-app-sampleリポジトリでdocker imageをビルド
3. 2.のimageを1.のリポジトリにpush
   1. ECR上にpushコマンドの説明あるのでそれに従う 

## ECSのコンテナURL変更
backend_ecs.tfのbackend-app-task-definition/container-definitions/imageのURLを変更する

## ALB/ECSあたりのapply
以下のコマンドでapplyして完了。
### Plan
```
terraform plan -var-file="secretvar.tfvars"
```

### Apply
```
terraform apply -var-file="secretvar.tfvars"
```


## 動作確認
- <ALBのDNS>/posts/?page=1にアクセスしてデータが返ってくることを確認
- ALBのtarget groupのヘルスチェックを確認
- apache benchで負荷テストしてスケーリングできることを確認