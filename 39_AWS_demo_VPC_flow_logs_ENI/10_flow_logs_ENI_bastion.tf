# -------- IAM role used by VPC flow logs
resource aws_iam_role demo39_flow_log {
  name = "demo39-eni-flow-log-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })
}

resource aws_iam_role_policy demo39_flow_log {
  name = "demo39-eni-flow-log-policy"
  role = aws_iam_role.demo39_flow_log.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

# -------- CloudWatch log group
resource aws_cloudwatch_log_group demo39_flow_log_eni {
  name              = "/aws/eni-flow-logs"
  retention_in_days = 7
}

# -------- VPC flow log for ENI
resource aws_flow_log demo39_flow_log_eni {
  iam_role_arn    = aws_iam_role.demo39_flow_log.arn
  log_destination = aws_cloudwatch_log_group.demo39_flow_log_eni.arn
  traffic_type    = "ALL"
  eni_id          = aws_instance.demo39_bastion.primary_network_interface_id
}
