resource "aws_security_group" "backend-alb-sg" {
  name   = "${var.project_name}-backend-alb-sg"
  vpc_id = aws_vpc.postapp_vpc.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
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
  # TODO ここのサブネットの意味は？ALBが属するってこと？
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
    protocol = "HTTP"
    # TODO バックエンドのヘルスチェックパス修正
    path                = "/posts"
    port                = 80
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 10
    matcher             = 200
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
  # 同一サブネットのみアクセス可能
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["192.168.0.0/16"]
  }

  tags = {
    "Name" : "${var.project_name}-backend-ecs-sg"
  }
}


resource "aws_cloudwatch_log_group" "ecs_log" {
  name              = "/ecs/postapp/backend"
  retention_in_days = 180
}


resource "aws_ecs_task_definition" "backend-app-task-definition" {
  family = "${var.project_name}-backend-task-definition"
  # Fargateで動かす
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"

  execution_role_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  # TODO リソース見直し
  cpu    = 256
  memory = 512
  # TODO 起動するコンテナ定義。とりあえずnginxにしている
  container_definitions = <<EOL
[
  {
    "name": "nginx",
    "image": "nginx:1.14",
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-stream-prefix": "backend",
        "awslogs-group": "/ecs/postapp/backend"
      }
    },
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
  name            = "${var.project_name}-backend-service"
  depends_on      = [aws_lb_listener.backend_lb_listener]
  cluster         = aws_ecs_cluster.postapp-cluster.name
  task_definition = aws_ecs_task_definition.backend-app-task-definition.arn
  launch_type     = "FARGATE"
  desired_count   = 2

  network_configuration {
    subnets = [
      aws_subnet.worker_subnet_1.id,
      aws_subnet.worker_subnet_2.id,
      aws_subnet.worker_subnet_3.id,
    ]
    security_groups = [aws_security_group.backend-ecs-sg.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.backend-lb-tg.arn
    container_name   = "nginx"
    container_port   = 80
  }
  # TODO AutoScaling
}

