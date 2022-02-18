# data "aws_iam_policy_document" "ecs-autoscale_assume_role" {
#   statement {
#     effect  = "Allow"
#     actions = ["sts:AssumeRole"]
#     principals {
#       type        = "Service"
#       identifiers = ["application-autoscaling.amazonaws.com"]
#     }
#   }
# }

# resource "aws_iam_role" "ecs_autoscale_role" {
#   name               = "${var.project_name}-ecs_autoscale_role"
#   assume_role_policy = data.aws_iam_policy_document.ecs-autoscale_assume_role.json
# }

# resource "aws_iam_role_policy_attachment" "ecs_autoscale_role_attach" {
#   name       = "ecs_autoscale_role_attach"
#   role       = aws_iam_role.ecs_autoscale_role.name
#   policy_arn = "TODO 色々必要そう"
# }

# resource "aws_appautoscaling_target" "backend-scaling-target" {
#   service_namespace = "TODO なに指定すればいい？"
#   # TODO 本当にこの形式？
#   resource_id  = "service/${aws_ecs_cluster.api_cluster.name}/${aws_ecs_service.api_service.name}"
#   role_arn     = aws_iam_role.ecs_autoscale_role.arn
#   min_capacity = 2
#   max_capacity = 5
# }



