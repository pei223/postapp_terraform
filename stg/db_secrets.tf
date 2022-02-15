
# resource "aws_secretsmanager_secret" "rds_master_secret" {
#   name = "rds_master_secret"
# }

# resource "random_password" "db_master_password" {
#   length  = 16
#   special = false
# }

# resource "aws_secretsmanager_secret_version" "db_master_credential" {
#   secret_id     = aws_secretsmanager_secret.rds_master_secret.id
#   secret_string = <<EOF
#    {
#     "username": "dbadmin",
#     "password": "${random_password.db_master_password.result}"
#    }
# EOF
# }

# resource "aws_secretsmanager_secret" "rds_user_secret" {
#   name = "rds_user_secret"
# }

# resource "random_password" "db_user_password" {
#   length  = 16
#   special = false
# }

# resource "aws_secretsmanager_secret_version" "db_user_credential" {
#   secret_id     = aws_secretsmanager_secret.rds_user_secret.id
#   secret_string = <<EOF
#    {
#     "username": "dbadmin",
#     "password": "${random_password.db_user_password.result}"
#    }
# EOF
# }