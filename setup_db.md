# データベースセットアップ
## 手順
本当はTerraform上で完結したいがそうもいかなそうなので、Session Manager使って踏み台サーバー経由で色々やる

- Session ManagerでDBの踏み台サーバーにログイン
- PostgreSQLインストール
- アプリで使用するユーザー作成
- データベース作成
- 必要ならテーブルセットアップ用SQL実行

## PostgreSQLインストール
```
sudo yum install -y git
sudo amazon-linux-extras install -y postgresql10
```


## ユーザー作成
RDSエンドポイントはcreate_rds.yamlをCloudFormationで実行した後に出力タブが出てくるのでそれをコピペ
```
createuser -d -U <db_master_username> -P -h <RDSエンドポイント> <db_user_username>
```


- 最初2回は新しいユーザーのパスワード入力を求められるので、db_user_passwordの値を入力
- その後masterのパスワードを求められるので、db_master_passwordを入力


## データベース作成
ここで要求されるパスワードはRdsUserSecretの方

```
createdb -U <db_user_username> -h <RDSエンドポイント> -E UTF8 postappdb
```


## データベースへの接続確認
```
psql -U <db_user_username> -h <RDSエンドポイント> postappdb
# 全テーブル取得
SELECT * FROM information_schema.tables;
# 終了
\q
```
データベース接続後に必要であればテーブルセットアップ

