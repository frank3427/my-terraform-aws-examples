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

# ---- Create a PCS compute node
resource awscc_pcs_compute_node_group demo45a_ng1 {
    cluster_id               = awscc_pcs_cluster.demo45a.cluster_id
    subnet_ids               = [ aws_subnet.demo45a_public.id ]
    custom_launch_template   = {
      template_id = aws_launch_template.demo45a_cpt_nodes.id
      version     = aws_launch_template.demo45a_cpt_nodes.latest_version
    }
    iam_instance_profile_arn = aws_iam_instance_profile.demo45a.arn
    instance_configs         = [
        {
            instance_type = var.cpt_nodes_inst_type
            count         = var.cpt_nodes_count
        }
    ]
    scaling_configuration = {
        min_instance_count = var.cpt_nodes_count
        max_instance_count = var.cpt_nodes_count
    }
}

# ---- Create a PCS queue
resource awscc_pcs_queue demo45a_queue {
    name       = var.slurm_queue # "demo45a-tf-queue"
    cluster_id = awscc_pcs_cluster.demo45a.cluster_id
    compute_node_group_configurations = [{
        compute_node_group_id = awscc_pcs_compute_node_group.demo45a_ng1.compute_node_group_id
    }]
}