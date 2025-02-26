# aws_globalaccelerator_accelerator.demo41: Creation complete after 47s
resource aws_globalaccelerator_accelerator demo41 {
  name            = "demo41-accelerator"
  ip_address_type = "IPV4"
  enabled         = true
}

# aws_globalaccelerator_listener.demo41: Creation complete after 1m5s 
resource aws_globalaccelerator_listener demo41 {
  accelerator_arn = aws_globalaccelerator_accelerator.demo41.id
  protocol        = "TCP"

  port_range {
    from_port = 80
    to_port   = 80
  }

  # client_affinity = "SOURCE_IP"
}

# aws_globalaccelerator_endpoint_group.demo41: Creation complete after 1m9s
resource aws_globalaccelerator_endpoint_group demo41 {
  listener_arn = aws_globalaccelerator_listener.demo41.id

  endpoint_configuration {
    endpoint_id = aws_lb.demo41_alb_private.arn
    weight      = 100
    client_ip_preservation_enabled = true
  }
}