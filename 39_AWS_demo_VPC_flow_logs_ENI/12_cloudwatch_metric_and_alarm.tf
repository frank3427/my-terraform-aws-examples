# -------- Create a CloudWatch metric for failed SSH to Bastion Host
resource aws_cloudwatch_log_metric_filter demo39_ssh {
  name           = "demo39-filter-ssh"
  pattern        = "[version, account, eni, source, destination, srcport, destport=\"22\", protocol=\"6\", packets, bytes, windowstart, windowend, action=\"REJECT\", flowlogstatus]"
  log_group_name = aws_cloudwatch_log_group.demo39_flow_log_eni.name

  metric_transformation {
    name      = var.cw_metric_name
    namespace = var.cw_metric_namespace
    value     = "1"
  }
}

# -------- Create a CloudWatch alarm for failed SSH to Bastion Host
resource aws_cloudwatch_metric_alarm demo39_ssh {
  alarm_name          = "demo39_failed_ssh"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = var.cw_metric_name
  namespace           = var.cw_metric_namespace
  period              = "300"   
  statistic           = "Sum"
  threshold           = "3"
  alarm_description   = "This metric monitors error count"
  alarm_actions       = [aws_sns_topic.demo39.arn]
}
