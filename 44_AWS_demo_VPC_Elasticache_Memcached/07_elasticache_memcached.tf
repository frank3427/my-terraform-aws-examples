# ------ Create the ElastiCache subnet group
resource "aws_elasticache_subnet_group" "elasticache_subnet_group" {
  name       = "demo44-elasticache"
  subnet_ids = [aws_subnet.demo44_private.id]
}

# ------ Create the ElastiCache Memcached cluster
resource "aws_elasticache_cluster" "memcached_cluster" {
  cluster_id           = "demo44-memcached-cluster"
  engine               = "memcached"
  engine_version       = var.memcached_version
  node_type            = var.elasticache_node_type
  num_cache_nodes      = var.elasticache_nb_nodes
  parameter_group_name = "default.memcached1.6"
  port                 = 11211

  subnet_group_name  = aws_elasticache_subnet_group.elasticache_subnet_group.name
  security_group_ids = [aws_security_group.memcached.id]
}

# ------ Create a security group for the Elasticache Memcached cluster
resource "aws_security_group" "memcached" {
  vpc_id = aws_vpc.demo44.id
  tags   = { Name = "demo44-memcached" }

}


resource "aws_vpc_security_group_ingress_rule" "memcached_ingress_all_0" {
  security_group_id = aws_security_group.memcached.id
  description       = "allow access to Memcached cluster from VPC"
  from_port         = 11211
  to_port           = 11211
  ip_protocol       = "tcp"
  cidr_ipv4         = var.cidr_vpc
  tags              = { Name = "memcached-sgr-ingress-all-0" }
}

resource "aws_vpc_security_group_egress_rule" "memcached_egress_all_1" {
  security_group_id = aws_security_group.memcached.id
  description       = "allow all traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  tags              = { Name = "memcached-sgr-egress-all-1" }
}
