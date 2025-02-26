resource aws_sns_topic demo39 {
  name = "demo39-email"  
}

resource aws_sns_topic_subscription demo39_email {
  topic_arn = aws_sns_topic.demo39.arn
  protocol  = "email"
  endpoint  = var.sns_email
}
