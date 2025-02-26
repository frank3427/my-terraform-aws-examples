locals {
    az               = "${var.aws_region}${var.az_for_fis}"
    ecs_cluster_name = aws_ecs_cluster.demo23.name
    ecs_service_name = aws_ecs_service.demo23_svc2.name
}

resource aws_cloudwatch_log_group demo23_fis {
  name = "/aws/fis/demo23"          # name must start by /aws/fis/
  retention_in_days = 14
}

# IAM role to allow FIS to stop ECS tasks and write to CloudWatch log group
resource aws_iam_role demo23_fis_role {
  name = "AWSFISIAMRole-xxxx-cpa-demo23"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "fis.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  # add managed policy AWSFaultInjectionSimulatorECSAccess to iam role
  managed_policy_arns = [ "arn:aws:iam::aws:policy/service-role/AWSFaultInjectionSimulatorECSAccess" ]

# autorise ecs stop task and cloudwatch put logs
  inline_policy {
    name = "demo23_fis_to_cloudwatch_logs"
    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogDelivery"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:PutResourcePolicy",
                "logs:DescribeResourcePolicies",
                "logs:DescribeLogGroups"
            ],
            "Resource": "${aws_cloudwatch_log_group.demo23_fis.arn}"
        }
    ]
}
EOF
  }
}

resource aws_fis_experiment_template demo23_stop_ecs_tasks {
  description = "Stop ECS tasks in AZ ${local.az} from cluster ${local.ecs_cluster_name} and service ${local.ecs_service_name}"
  role_arn    = aws_iam_role.demo23_fis_role.arn
  tags = {
    Name = "demo23_stop_ecs_tasks_in_AZ"
  }

  log_configuration {
    log_schema_version = "2.0"
    cloudwatch_logs_configuration {
        log_group_arn = "${aws_cloudwatch_log_group.demo23_fis.arn}:*"
    }
  }

  stop_condition {
    source = "none"
  }

  action {
    name      = "stop_ecs_tasks"
    action_id = "aws:ecs:stop-task"

    target {
      key   = "Tasks"
      value = "ECS_tasks_in_AZ_${local.az}"
    }
  }

  target {
    name           = "ECS_tasks_in_AZ_${local.az}"
    resource_type  = "aws:ecs:task"
    selection_mode = "ALL"

    parameters = {
      cluster = local.ecs_cluster_name
      service = local.ecs_service_name
    }
    
    filter {
      path   = "AvailabilityZone"
      values = [ local.az ]
    }
  }
}