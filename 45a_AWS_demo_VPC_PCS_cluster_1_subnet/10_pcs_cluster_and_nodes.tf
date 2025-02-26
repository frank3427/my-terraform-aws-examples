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

# ---- Create a PCS compute node group for compute nodes

# resource awscc_pcs_compute_node_group # Not available in awscc 1.26.0
# https://github.com/hashicorp/terraform-provider-awscc/issues/2157

# create AWS CLI script to create pcs compute node group
resource local_file create_pcs_cpt_nodes_group {
    filename = "tmp1_create_cpt_nodes_group.sh"
    content = <<EOF
aws pcs create-compute-node-group \
    --region "${var.aws_region}" \
    --cluster-identifier "${awscc_pcs_cluster.demo45a.cluster_id}" \
    --compute-node-group-name "demo45a-cpt-nodes-group" \
    --subnet-ids '["${aws_subnet.demo45a_public.id}"]' \
    --custom-launch-template '{
        "id": "${aws_launch_template.demo45a_cpt_nodes.id}",
        "version": "${aws_launch_template.demo45a_cpt_nodes.latest_version}"
        }' \
    --iam-instance-profile-arn "${aws_iam_instance_profile.demo45a.arn}" \
    --scaling-configuration '{
        "minInstanceCount": ${var.cpt_nodes_count},
        "maxInstanceCount": ${var.cpt_nodes_count}
        }' \
    --instance-configs instanceType=${var.cpt_nodes_inst_type}

EOF
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

# CPT_NODE_GRP_ID=`aws pcs list-compute-node-groups --cluster-identifier "${awscc_pcs_cluster.demo45a.cluster_id}" --region "${var.aws_region}" --query 'computeNodeGroups[0].id' | jq -r`

# create AWS CLI script to create pcs queue
resource local_file create_pcs_queue {
    filename = "tmp2_create_queue.sh"
    content = <<EOF
aws pcs list-compute-node-groups \
    --region "${var.aws_region}" \
    --cluster-identifier "${awscc_pcs_cluster.demo45a.cluster_id}" \
    --query 'computeNodeGroups[].[name,id]' \
    --output text > ${local.nodegrp_ids_file}

CPT_NODE_GRP_ID=`grep demo45a-cpt-nodes-group ${local.nodegrp_ids_file} | cut -f2`

aws pcs create-queue \
    --region "${var.aws_region}" \
    --cluster-identifier "${awscc_pcs_cluster.demo45a.cluster_id}" \
    --queue-name "${var.slurm_queue}" \
    --compute-node-group-configurations computeNodeGroupId=$CPT_NODE_GRP_ID

EOF
}

locals {
    nodegrp_ids_file = "tmp_node_group_ids.txt"
}