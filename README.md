# Postapp terraform
このリポジトリのアプリをAWSにデプロイする用のterraform。

https://github.com/pei223/springboot-post-app-sample

## 内容
- VPCなどの基本リソース
- DBアクセスの踏み台サーバー
- RDSでDB
- (まだ)ALB/ECSでデプロイ

## Plan
```
terraform plan -var-file="secretvar.tfvars"
```

## Apply
```
terraform apply -var-file="secretvar.tfvars"
```

