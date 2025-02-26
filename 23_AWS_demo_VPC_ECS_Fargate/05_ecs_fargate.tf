resource aws_ecs_cluster demo23 {
  name = "demo23-cluster"
}

resource aws_ecs_cluster_capacity_providers demo23 {
  cluster_name       = aws_ecs_cluster.demo23.name
  capacity_providers = ["FARGATE","FARGATE_SPOT"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 50
    capacity_provider = "FARGATE"
  }

  default_capacity_provider_strategy {
    weight            = 50
    capacity_provider = "FARGATE_SPOT"
  }
}

resource aws_ecs_task_definition demo23_taskdef1 {
  family                   = "demo23-taskdef1"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 512      # 512 cpu units = 0.5 vCPU
  memory                   = 2048     # 2048 MB = 2 GB
  # When networkMode=awsvpc, the host ports and container ports in port mappings must match
  container_definitions    = <<EOF
  [
    {
      "name"      : "nginx",
      "image"     : "nginx:1.23.1",
      "cpu"       : 512,
      "memory"    : 2048,
      "essential" : true,
      "portMappings" : [
        {
          "containerPort" : 80,
          "hostPort"      : 80
        }
      ]
    }
  ]
EOF
}

# # ---- ECS service #1 with single task, no LB
# resource aws_ecs_service demo23_svc1 {
#   lifecycle {
#     ignore_changes = [task_definition,desired_count]
#   }
#   name             = "demo23-svc1"
#   cluster          = aws_ecs_cluster.demo23.id
#   task_definition  = aws_ecs_task_definition.demo23_taskdef1.id
#   desired_count    = 1
#   launch_type      = "FARGATE"
#   platform_version = "LATEST"
#   enable_ecs_managed_tags = true
#   wait_for_steady_state   = true

#   network_configuration {
#     assign_public_ip = true
#     security_groups  = [ aws_default_security_group.demo23.id ]
#     subnets          = [ for subnet in aws_subnet.demo23_public: subnet.id ]
#   }
# }

# # ---- Get public IP address assigned to the task in service #1
# # https://github.com/hashicorp/terraform-provider-aws/issues/3444

# data aws_network_interface demo23_svc1_task {
#   filter {
#     name   = "tag:aws:ecs:serviceName"
#     values = [ aws_ecs_service.demo23_svc1.name ]
#   }
# }

# locals {
#   demo23_svc1_task_public_ip = data.aws_network_interface.demo23_svc1_task.association[0].public_ip
# }

# output service1 {
#   value = <<EOF
#     You can access the web server running in single task on service ${aws_ecs_service.demo23_svc1.name} by opening following URL in your web browser:
#     http://${local.demo23_svc1_task_public_ip}
# EOF
# }

# ---- ECS service #2 with 3 tasks (1 per AZ/subnet) with LB
resource aws_ecs_service demo23_svc2 {
  lifecycle {
    ignore_changes = [task_definition,desired_count]
  }
  name             = "demo23-svc2"
  cluster          = aws_ecs_cluster.demo23.id
  task_definition  = aws_ecs_task_definition.demo23_taskdef1.id
  desired_count    = 3
  launch_type      = "FARGATE"
  platform_version = "LATEST"
  enable_ecs_managed_tags = true
  wait_for_steady_state   = true

  # ordered_placement_strategy {
  #   type  = "binpack"
  #   field = "cpu"
  # }

  load_balancer {
    target_group_arn = aws_lb_target_group.demo23_tg1.arn
    container_name   = "nginx"
    container_port   = 80
  }

  # placement_constraints {
  #   type       = "memberOf"
  #   expression = "attribute:ecs.availability-zone in [us-west-2a, us-west-2b]"
  # }

  network_configuration {
    assign_public_ip = true
    security_groups  = [ aws_default_security_group.demo23.id ]
    subnets          = [ for subnet in aws_subnet.demo23_public: subnet.id ]
    #subnets          = [ aws_subnet.demo23_public[0].id, aws_subnet.demo23_public[1].id ]
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }
}

locals {
  demo23_svc2_lb_dns_name = aws_lb.demo23_alb.dns_name
}

output service2 {
  value = <<EOF
    You can access the web servers running in 3 tasks behind load balancer on service ${aws_ecs_service.demo23_svc2.name} by opening following URL in your web browser:
    http://${local.demo23_svc2_lb_dns_name}
EOF
}

