resource "aws_vpc" "postapp_vpc" {
  cidr_block           = "192.168.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    "Name" = "${var.project_name}-vpc"
  }
}

resource "aws_subnet" "worker_subnet_1" {
  vpc_id            = aws_vpc.postapp_vpc.id
  availability_zone = var.AZ1
  cidr_block        = "192.168.1.0/24"
  tags = {
    "Name" : "${var.project_name}-worker-subnet_1"
  }
}

resource "aws_subnet" "worker_subnet_2" {
  vpc_id            = aws_vpc.postapp_vpc.id
  availability_zone = var.AZ2
  cidr_block        = "192.168.2.0/24"
  tags = {
    "Name" : "${var.project_name}-worker-subnet_2"
  }
}

resource "aws_subnet" "worker_subnet_3" {
  vpc_id            = aws_vpc.postapp_vpc.id
  availability_zone = var.AZ3
  cidr_block        = "192.168.3.0/24"
  tags = {
    "Name" : "${var.project_name}-worker-subnet_3"
  }
}

resource "aws_subnet" "db_bastion_subnet" {
  vpc_id                  = aws_vpc.postapp_vpc.id
  availability_zone       = var.AZ1
  cidr_block              = "192.168.5.0/24"
  map_public_ip_on_launch = true
  tags = {
    "Name" : "${var.project_name}-db-bastion_subnet"
  }
}

resource "aws_subnet" "rds_subnet_1" {
  vpc_id            = aws_vpc.postapp_vpc.id
  availability_zone = var.AZ2
  cidr_block        = "192.168.10.0/24"
  tags = {
    "Name" : "${var.project_name}-rds_subnet_1"
  }
}

resource "aws_subnet" "rds_subnet_2" {
  vpc_id            = aws_vpc.postapp_vpc.id
  availability_zone = var.AZ3
  cidr_block        = "192.168.11.0/24"
  tags = {
    "Name" : "${var.project_name}-rds_subnet_2"
  }
}

resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.postapp_vpc.id
  tags = {
    "Name" : "${var.project_name}-main-igw"
  }
}

resource "aws_route_table" "default_rt" {
  vpc_id = aws_vpc.postapp_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw.id
  }

  tags = {
    "Name" : "${var.project_name}-default-internet-routing"
  }
}

resource "aws_route_table_association" "default_rt_association1" {
  subnet_id      = aws_subnet.worker_subnet_1.id
  route_table_id = aws_route_table.default_rt.id
}

resource "aws_route_table_association" "default_rt_association2" {
  subnet_id      = aws_subnet.worker_subnet_2.id
  route_table_id = aws_route_table.default_rt.id
}

resource "aws_route_table_association" "default_rt_association3" {
  subnet_id      = aws_subnet.worker_subnet_3.id
  route_table_id = aws_route_table.default_rt.id
}

resource "aws_route_table_association" "default_rt_association_bastion" {
  subnet_id      = aws_subnet.db_bastion_subnet.id
  route_table_id = aws_route_table.default_rt.id
}


