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

## Plan
```
terraform plan -var-file="secretvar.tfvars"
```

## Apply
```
terraform apply -var-file="secretvar.tfvars"
```

