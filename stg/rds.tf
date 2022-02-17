resource "aws_security_group" "rds_sg" {
  name        = "rds_sg"
  description = "Allow PostgreSQL Port from worker subnets and bastion server"
  vpc_id      = aws_vpc.postapp_vpc.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.worker_subnet_1.cidr_block, aws_subnet.worker_subnet_2.cidr_block, aws_subnet.worker_subnet_3.cidr_block, aws_subnet.db_bastion_subnet.cidr_block]
  }

  tags = {
    "Name" : "${var.project_name}-rds_sg"
  }
}

resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "${var.project_name}-db_subnet_group"
  subnet_ids = [aws_subnet.rds_subnet_1.id, aws_subnet.rds_subnet_2.id]

  tags = {
    "Name" : "${var.project_name}-db_subnet_group"
  }
}


# TODO 色々見直し
resource "aws_db_instance" "postapp-db" {
  name                   = "postapp_db"

  engine            = "postgres"
  engine_version    = "10.6"
  instance_class    = "db.t2.micro"
  allocated_storage = 30
  storage_type      = "gp2"

  publicly_accessible    = true
  multi_az               = true
  username               = var.db_master_username
  password               = var.db_master_password
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  backup_window              = "18:00-18:30"
  maintenance_window         = "sat:19:00-sat:19:30"
  auto_minor_version_upgrade = true
  copy_tags_to_snapshot      = true
  backup_retention_period    = 7
  deletion_protection        = false

  tags = {
    "Name": "postapp_db"
  }
}

output "rds_endpoint" {
  value = aws_db_instance.postapp-db.endpoint
}