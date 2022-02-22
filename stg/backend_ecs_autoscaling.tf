data "aws_iam_policy_document" "ecs-autoscale_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs.application-autoscaling.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_autoscale_role" {
  name               = "${var.project_name}-ecs_autoscale_role"
  assume_role_policy = data.aws_iam_policy_document.ecs-autoscale_assume_role.json
}
resource "aws_iam_policy" "ecs_autoscale_role_policy" {
  name        = "ecs_autoscale_role_policy"
  description = "AWSApplicationAutoscalingECSService_Policy"
  policy      = file("ecs_autoscaling_policy.json")
}

resource "aws_iam_role_policy_attachment" "ecs_autoscale_role_attach" {
  role       = aws_iam_role.ecs_autoscale_role.name
  policy_arn = aws_iam_policy.ecs_autoscale_role_policy.arn
}

resource "aws_appautoscaling_target" "backend-scaling-target" {
  service_namespace = "ecs" # AWSサービスごとに決まった値を指定する
  # service/<ClusterName/<Service>の形式
  resource_id        = "service/${aws_ecs_cluster.postapp-cluster.name}/${aws_ecs_service.backend-app-service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  role_arn           = aws_iam_role.ecs_autoscale_role.arn
  min_capacity       = 2
  max_capacity       = 5
}

resource "aws_appautoscaling_policy" "backend_scale_out" {
  service_namespace  = "ecs"
  name               = "${var.project_name}_ECS-ScaleOut-CPU-High"
  resource_id        = "service/${aws_ecs_cluster.postapp-cluster.name}/${aws_ecs_service.backend-app-service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 300
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }
  depends_on = [aws_appautoscaling_target.backend-scaling-target]
}

resource "aws_appautoscaling_policy" "backend_scale_in" {
  service_namespace  = "ecs"
  name               = "${var.project_name}_ECS-ScaleIn-CPU-Low"
  resource_id        = "service/${aws_ecs_cluster.postapp-cluster.name}/${aws_ecs_service.backend-app-service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 300
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = -1
    }
  }
  depends_on = [aws_appautoscaling_target.backend-scaling-target]
}

resource "aws_cloudwatch_metric_alarm" "backend_cpu_high" {
  alarm_name          = "${var.project_name}_backend_cpu_high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS" # AWSサービスごとに決まった値を指定する
  period              = 120
  statistic           = "Average"
  threshold           = 25
  dimensions = {
    ClusterName = aws_ecs_cluster.postapp-cluster.name
    ServiceName = aws_ecs_service.backend-app-service.name
  }
  alarm_actions = [aws_appautoscaling_policy.backend_scale_out.arn]
}

resource "aws_cloudwatch_metric_alarm" "backend_cpu_low" {
  alarm_name          = "${var.project_name}_backend_cpu_low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS" # AWSサービスごとに決まった値を指定する
  period              = 120
  statistic           = "Average"
  threshold           = 5
  dimensions = {
    ClusterName = aws_ecs_cluster.postapp-cluster.name
    ServiceName = aws_ecs_service.backend-app-service.name
  }
  alarm_actions = [aws_appautoscaling_policy.backend_scale_in.arn]
}



