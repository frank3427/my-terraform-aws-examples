# ------ Create a security group for the MSK cluster
resource aws_security_group demo35_msk {
  name        = "demo35-msk"
  description = "sg for the MSK cluster"
  vpc_id      = aws_vpc.demo35.id
  tags        = { Name = "demo35-msk" }

  # ingress rule: allow HTTP
  ingress {
    description = "allow Kafka traffic from Kafka client"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"    # all protocols
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
# ------ Create the MSK cluster
resource aws_msk_cluster demo35_provisioned {
  lifecycle {
    ignore_changes = all
  }
  cluster_name           = "demo35-provisioned"
  kafka_version          = var.msk_kafka_version
  number_of_broker_nodes = 3

# "vpc_connectivity" = tolist([
#             {
#               "client_authentication" = tolist([
#                 {
#                   "sasl" = tolist([
#                     {
#                       "iam" = false
#                       "scram" = false
#                     },
#                   ])
#                   "tls" = false
#                 },
#               ])
#             },
#           ])

    # connectivity_info = [{
    #   vpc_connectivity = [{
    #     client_authentication = [{
    #       sasl = [{ iam = true }]
    #     }]       
    #   }]
    # }]

  broker_node_group_info {
    instance_type = var.msk_node_type
    client_subnets = [ for subnet in aws_subnet.demo35_public: subnet.id ]
    connectivity_info {
      public_access {
        type = "DISABLED"
      }
      vpc_connectivity {
        client_authentication {
          sasl {
            iam = true
          }
        }
      }
    }
    # client_authentication {
    #   unauthenticated = true
    #   sasl {
    #     iam   = true 
    #     scram = false
    #   }
    # }
    storage_info {
      ebs_storage_info {
        volume_size = var.msk_ebs_size_gb
      }
    }
    security_groups = [ aws_security_group.demo35_msk.id ] 
  }

  # possible values below: DEFAULT, PER_BROKER, PER_TOPIC_PER_BROKER, PER_TOPIC_PER_PARTITION
  enhanced_monitoring = "PER_TOPIC_PER_PARTITION" 

#   encryption_info {
#     encryption_at_rest_kms_key_arn = aws_kms_key.kms.arn
#   }

#   open_monitoring {
#     prometheus {
#       jmx_exporter {
#         enabled_in_broker = true
#       }
#       node_exporter {
#         enabled_in_broker = true
#       }
#     }
#   }

#   logging_info {
#     broker_logs {
#       cloudwatch_logs {
#         enabled   = true
#         log_group = aws_cloudwatch_log_group.test.name
#       }
#       firehose {
#         enabled         = true
#         delivery_stream = aws_kinesis_firehose_delivery_stream.test_stream.name
#       }
#       s3 {
#         enabled = true
#         bucket  = aws_s3_bucket.bucket.id
#         prefix  = "logs/msk-"
#       }
#     }
#   }

  tags = {
    demo = "demo35"
  }
}

output debug_msk {
  value = aws_msk_cluster.demo35_provisioned
}

locals {
  msk_bootstrap_brokers = aws_msk_cluster.demo35_provisioned.bootstrap_brokers_sasl_iam
  msk_cluster_arn       = aws_msk_cluster.demo35_provisioned.arn
}

# ------ Create an IAM policy, IAM role and instance profile
resource aws_iam_policy demo35_msk {
  name        = "demo35_msk_policy"
  path        = "/"
  description = "IAM policy for MSK"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "kafka-cluster:Connect",
                "kafka-cluster:AlterCluster",
                "kafka-cluster:DescribeCluster"
            ],
            "Resource": [
                "${local.msk_cluster_arn}/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "kafka-cluster:*Topic*",
                "kafka-cluster:WriteData",
                "kafka-cluster:ReadData"
            ],
            "Resource": [
                "${local.msk_cluster_arn}/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "kafka-cluster:AlterGroup",
                "kafka-cluster:DescribeGroup"
            ],
            "Resource": [
                "${local.msk_cluster_arn}/*"
            ]
        }
    ]
  })
}

# create IAM role using IAM policy for EC2
resource aws_iam_role demo35_msk {
  name = "demo35_msk_role"
  path = "/"

  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
  })
  managed_policy_arns = [ aws_iam_policy.demo35_msk.arn ]
}

resource aws_iam_instance_profile demo35_msk {
  name = "dem325_msk_for_ec2_instprof"
  role = aws_iam_role.demo35_msk.name
}