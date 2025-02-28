# ---- Create a PCS cluster
# awscc_pcs_cluster.demo45a: Creation complete after 7m47s
resource awscc_pcs_cluster demo45a {
    name = "demo45a-tf-cluster"
    size = "SMALL"      # SMALL, MEDIUM or LARGE
    scheduler = {
        type = "SLURM"
        version = "24.05"
    }
    networking = {
        subnet_ids         = [ aws_subnet.demo45a_public.id ]
        security_group_ids = [ aws_security_group.demo45a.id ]
    }
}

# ---- create CloudfFormation stack to create PCS compute node group and PCS queue
# awscc 1.31 does not support PCS compute node group
resource aws_cloudformation_stack demo45a_nodes_queue {
  name          = "demo45a-pcs-nodes-queue"
  capabilities  = ["CAPABILITY_IAM"]
  template_body = templatefile("templates/cfn_template.tpl", {
    compute_node_group_name = "demo45a-nodes-group1",
    pcs_cluster_id          = awscc_pcs_cluster.demo45a.cluster_id,
    instance_type           = var.cpt_nodes_inst_type,
    launch_template_version = aws_launch_template.demo45a_cpt_nodes.latest_version,
    launch_template_id      = aws_launch_template.demo45a_cpt_nodes.id,
    subnet_id               = aws_subnet.demo45a_public.id,
    instance_profile_arn    = aws_iam_instance_profile.demo45a.arn,
    queue_name              = var.slurm_queue,
    nodes_count             = var.cpt_nodes_count
  })
}

locals {
    pcs_compute_nodes_group_id = aws_cloudformation_stack.demo45a_nodes_queue.outputs.ComputeNodeGroupID
}

# ---- Create a PCS queue
# https://registry.terraform.io/providers/hashicorp/awscc/1.26.0/docs/resources/pcs_queue

# resource awscc_pcs_queue demo45a_queue {
#     name       = "demo45a-tf-queue"
#     cluster_id = awscc_pcs_cluster.demo45a.cluster_id
#     compute_node_group_configurations = [{
#         compute_node_group_id = "pcs_ub9sk06mye"
#     }]
# }