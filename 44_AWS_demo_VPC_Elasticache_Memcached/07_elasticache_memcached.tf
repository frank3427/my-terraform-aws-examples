# ------ Create the ElastiCache subnet group
resource aws_elasticache_subnet_group elasticache_subnet_group {
  name       = "demo44-elasticache"
  subnet_ids = [ aws_subnet.demo44_private.id]  
}

# ------ Create the ElastiCache Memcached cluster
resource aws_elasticache_cluster memcached_cluster {
  cluster_id           = "demo44-memcached-cluster"
  engine               = "memcached"
  engine_version       = var.memcached_version
  node_type            = var.elasticache_node_type
  num_cache_nodes      = var.elasticache_nb_nodes
  parameter_group_name = "default.memcached1.6"
  port                 = 11211
  
  subnet_group_name    = aws_elasticache_subnet_group.elasticache_subnet_group.name
  security_group_ids   = [ aws_security_group.memcached.id ]
}

# ------ Create a security group for the Elasticache Memcached cluster
resource aws_security_group memcached {
  vpc_id      = aws_vpc.demo44.id
  tags        = { Name = "demo44-memcached" }

  # ingress rule: allow SSH
  ingress {
    description = "allow access to Memcached cluster from VPC"
    from_port   = 11211
    to_port     = 11211
    protocol    = "tcp"
    cidr_blocks = [ var.cidr_vpc ]
  }

  # egress rule: allow all traffic
  egress {
    description = "allow all traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"    # all protocols
    cidr_blocks = [ "0.0.0.0/0" ]
  }
}
