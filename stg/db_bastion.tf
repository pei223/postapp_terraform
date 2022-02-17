# DB踏み台サーバーのIAM role
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}
resource "aws_iam_role" "db_bastion_server_role" {
  name               = "db_bastion_server_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}
resource "aws_iam_role_policy_attachment" "attach_SSM_role_to_bastion_server" {
  role       = aws_iam_role.db_bastion_server_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "db_bastion_instance_profile" {
  name = "db_bastion_instance_profile"
  role = aws_iam_role.db_bastion_server_role.name
}


resource "aws_security_group" "db_bastion_sg" {
  name        = "db_bastion_sg"
  description = "Allow EC2 instance connect"
  vpc_id      = aws_vpc.postapp_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSM agentのインストールのために開けておく必要がある 
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "Name" : "db_bastion_sg"
  }
}


resource "aws_instance" "db_bastion_server" {
  # Amazon Linux2
  ami           = "ami-00d101850e971728d"
  instance_type = "t2.micro"
  ebs_block_device {
    device_name = "/dev/xvda"
    volume_type = "gp2"
    volume_size = 8
  }
  security_groups         = [aws_security_group.db_bastion_sg.id]
  subnet_id               = aws_subnet.db_bastion_subnet.id
  iam_instance_profile    = aws_iam_instance_profile.db_bastion_instance_profile.name
  disable_api_termination = false
  tags = {
    Name = "db_bastion_server"
  }

  user_data = <<EOF
#!/bin/bash
cd /tmp
sudo yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
sudo systemctl enable amazon-ssm-agent
sudo systemctl start amazon-ssm-agent
EOF


}

resource "aws_eip" "db_bastion_eip" {
  vpc = true
  tags = {
    "Name" = "db_bastion_eip"
  }

  lifecycle {
    ignore_changes = all
  }
}
resource "aws_eip_association" "db_bastion_eip_association" {
  instance_id   = aws_instance.db_bastion_server.id
  allocation_id = aws_eip.db_bastion_eip.id
  lifecycle {
    ignore_changes = all
  }
}
