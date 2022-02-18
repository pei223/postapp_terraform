resource "aws_security_group" "backend-alb-sg" {
  name   = "${var.project_name}-backend-alb-sg"
  vpc_id = aws_vpc.postapp_vpc.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["192.168.0.0/16"]
  }

  tags = {
    "Name" : "${var.project_name}-backend-alb-sg"
  }
}

resource "aws_lb" "backend_lb" {
  name               = "${var.project_name}-backend-lb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.backend-alb-sg.id]
  internal           = false
  # ルーティング対象のサブネット
  subnets = [
    aws_subnet.worker_subnet_1.id,
    aws_subnet.worker_subnet_2.id,
    aws_subnet.worker_subnet_3.id,
  ]

  tags = {
    "Name" : "${var.project_name}-backend-lb"
  }
}

resource "aws_lb_target_group" "backend-lb-tg" {
  vpc_id = aws_vpc.postapp_vpc.id
  name   = "${var.project_name}-backend-lg-tg"
  # 振り分け先のポート
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"

  health_check {
    # TODO バックエンドのヘルスチェックパス修正
    path = "/api/posts/?page=1"
    port = 80
  }
}

resource "aws_lb_listener" "backend_lb_listener" {
  load_balancer_arn = aws_lb.backend_lb.arn
  # 80ポートで受け付ける
  port     = 80
  protocol = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend-lb-tg.arn
  }
}

resource "aws_ecs_cluster" "postapp-cluster" {
  name = "${var.project_name}-postapp-cluster"
}

resource "aws_security_group" "backend-ecs-sg" {
  name   = "${var.project_name}-backend-ecs-sg"
  vpc_id = aws_vpc.postapp_vpc.id
  # TODO 動作確認終わり次第ALBからのみアクセス可能にする
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.backend-alb-sg.id]
  }

  # コンテナイメージfetchに必要 
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "Name" : "${var.project_name}-backend-ecs-sg"
  }
}


resource "aws_cloudwatch_log_group" "ecs_log" {
  name              = "/ecs/postapp/backend"
  retention_in_days = 180
}

data "aws_iam_policy_document" "ecs-assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "backend-task-execution-role" {
  name               = "backend-task-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs-assume_role.json
}

resource "aws_iam_role_policy_attachment" "backend-task-role-attach" {
  role       = aws_iam_role.backend-task-execution-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}


resource "aws_ecs_task_definition" "backend-app-task-definition" {
  family     = "${var.project_name}-backend-task-definition"
  depends_on = [aws_db_instance.postapp-db]
  # Fargateで動かす
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.backend-task-execution-role.arn
  # TODO リソース見直し
  cpu    = 256
  memory = 512
  # TODO 起動するコンテナ定義。とりあえずnginxにしている
  container_definitions = <<EOL
[
  {
    "name": "${var.project_name}-backend",
    "image": "422595392192.dkr.ecr.ap-northeast-1.amazonaws.com/postapp-backend:0.0.7",
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-stream-prefix": "backend",
        "awslogs-region": "ap-northeast-1",
        "awslogs-group": "/ecs/postapp/backend"
      }
    },
    "environment": [
      {
        "name": "DB_HOST",
        "value": "${aws_db_instance.postapp-db.endpoint}"
      },
      {
        "name": "DB_USERNAME",
        "value": "${var.db_user_username}"
      },
      {
        "name": "DB_PASSWORD",
        "value": "${var.db_user_password}"
      },
      {
        "name": "JWT_SECRET",
        "value": "${var.jwt_secret}"
      }
    ],
    "portMappings": [
      {
        "containerPort": 80,
        "hostPort": 80
      }
    ]
  }
]
EOL
}

resource "aws_ecs_service" "backend-app-service" {
  name        = "${var.project_name}-backend-service"
  cluster     = aws_ecs_cluster.postapp-cluster.name
  launch_type = "FARGATE"

  task_definition                   = aws_ecs_task_definition.backend-app-task-definition.arn
  desired_count                     = 2
  health_check_grace_period_seconds = 300

  network_configuration {
    subnets = [
      aws_subnet.worker_subnet_1.id,
      aws_subnet.worker_subnet_2.id,
      aws_subnet.worker_subnet_3.id,
    ]
    security_groups  = [aws_security_group.backend-ecs-sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.backend-lb-tg.arn
    container_name   = "${var.project_name}-backend"
    container_port   = 80
  }
  # TODO AutoScaling
}

