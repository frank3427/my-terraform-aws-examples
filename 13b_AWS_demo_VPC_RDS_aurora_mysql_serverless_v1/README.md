# Terraform AWS: RDS Aurora MySQL Serverless v1 Cluster and Manual Upgrade Path to v2

This Terraform project provisions an AWS environment featuring an AWS RDS Aurora MySQL **Serverless v1** cluster. It also includes a pre-configured Amazon Linux 2 EC2 instance to act as a client for the Aurora cluster.

A significant part of this documentation is dedicated to outlining a **manual, multi-step upgrade path from Aurora Serverless v1 to Aurora Serverless v2**, utilizing AWS CLI scripts provided in the `_upgrade_serverless_v1_to_v2/` subdirectory.

## Key Features & Concepts (Aurora Serverless v1)

*   **AWS RDS Aurora MySQL Serverless v1:** An on-demand, auto-scaling configuration for Aurora MySQL. It automatically starts up, shuts down, and scales capacity up or down based on your application's needs.
    *   `engine_mode = "serverless"` in the `aws_rds_cluster` resource.
    *   No explicit `aws_rds_cluster_instance` resources are defined in Terraform for Serverless v1; the capacity is managed by the service.
*   **Aurora Capacity Units (ACUs):** Serverless v1 scales by adjusting ACUs. Each ACU has a certain amount of processing capacity and memory.
*   **Auto-Pausing:** A key feature where the database can automatically pause after a configurable period of inactivity (`seconds_until_auto_pause`), helping to save costs. It automatically resumes when a connection is attempted.
*   **Scaling Configuration:** Defined within the `aws_rds_cluster` resource using a `scaling_configuration` block, specifying `min_capacity`, `max_capacity`, and `auto_pause` settings.
*   **Private Accessibility:** The Aurora cluster is not publicly accessible and relies on a DB Subnet Group and Security Groups for controlled access from within the VPC.
*   **EC2 Client:** An Amazon Linux 2 instance with MySQL client tools, configured via cloud-init to connect to the Serverless v1 cluster endpoint.

## AWS Resources Provisioned (Terraform - Serverless v1)

*   **VPC (Virtual Private Cloud):**
    *   A new VPC with an Internet Gateway (IGW).
*   **Subnets:**
    *   **Public Client Subnet (`var.cidr_subnet_public`):** Hosts the EC2 client instance.
    *   **Private RDS Subnets (`var.cidrs_subnet_private_rds`):** Multiple private subnets in different Availability Zones for the Aurora Serverless v1 cluster.
*   **AWS RDS Aurora MySQL Serverless v1 Cluster (`aws_rds_cluster`):**
    *   `engine = "aurora-mysql"`.
    *   `engine_mode = "serverless"`.
    *   Configurable Serverless v1 compatible engine version (e.g., for MySQL 5.6 or 5.7, such as "5.6.mysql_aurora.1.22.2" or "5.7.mysql_aurora.2.07.2").
    *   `scaling_configuration` block defining `min_capacity`, `max_capacity`, `auto_pause`, and `seconds_until_auto_pause`.
    *   Master username and initial database name are configurable. RDS manages the master password (can be retrieved if needed, though not directly used by Terraform after creation for this version).
    *   **DB Subnet Group (`aws_db_subnet_group`):** Created from the private RDS subnets.
    *   Associated with a dedicated RDS security group (`aws_security_group.demo13b_rds`).
*   **RDS Security Group (`demo13b-rds-sg`):**
    *   Allows inbound TCP port 3306 (MySQL) from the VPC's CIDR block (`var.cidr_vpc`).
*   **Linux EC2 Client Instance:**
    *   Amazon Linux 2 instance in the public client subnet, with an Elastic IP (EIP).
    *   Cloud-init script (`var.al2_cloud_init_script` template) using the Aurora cluster endpoint and master username for MySQL client setup.
    *   Associated with its own security group (`aws_default_security_group.demo13b_ec2`).
*   **EC2 Client Security Group (`demo13b-ec2-sg` - typically VPC's default SG):**
    *   Allows inbound SSH from `authorized_ips`.
    *   Allows necessary outbound traffic to connect to the Aurora cluster.

## Architecture (Serverless v1)

```
        [ AWS Cloud - Region: var.aws_region ]
                               |
        +-----------------------------------------------------------------+
        |                             VPC                                 |
        |                       (var.cidr_vpc)                            |
        |                                                                 |
        |  +-----------------------+  +---------------------------------+ |
        |  | Public Client Subnet  |  | Private RDS Subnets (Multi-AZ)  | | DB Subnet Group
        |  | (var.cidr_subnet_public)|  | (var.cidrs_subnet_private_rds)  |<-- (Spans Private Subnets)
        |  |-----------------------|  |---------------------------------| |
        |  | EC2 Client Instance   |  | [Aurora Serverless v1 Endpoint] | |
        |  | (EIP, AL2)            |<--->  MySQL Port 3306            | |
        |  | - MySQL Client        |  |   (Auto-scales ACUs)            | |
        |  | (SG: demo13b-ec2)     |  |   (May auto-pause)              | |
        |  |        |              |  | (SG: demo13b-rds)               | |
        |  +--------|--------------+  +---------------------------------+ |
        |           | (SSH)                                               |
        |           ▼                                                     |
        |     [Internet Gateway]                                          |
        +-----------------------------------------------------------------+
                      (Internet)
```
The Aurora Serverless v1 cluster dynamically manages its resources within the private subnets. The EC2 client connects to a single cluster endpoint.

## Key Configuration Variables (Serverless v1)

*   **General AWS:** `aws_region`, `az_rds_list` (list of AZs for private subnets), `cidr_vpc`, `cidr_subnet_public`, `cidrs_subnet_private_rds`.
*   **Aurora Serverless v1 Specific:**
    *   `aurora_sv1_cluster_identifier`: Cluster identifier.
    *   `aurora_sv1_engine_version`: Serverless v1 compatible engine version (e.g., "5.6.mysql_aurora.1.22.2").
    *   `aurora_sv1_master_username`: Master username.
    *   `aurora_sv1_db_name`: Initial database name.
    *   `aurora_sv1_min_capacity`: Minimum Aurora Capacity Units (ACUs).
    *   `aurora_sv1_max_capacity`: Maximum ACUs.
    *   `aurora_sv1_seconds_until_auto_pause`: Inactivity period before auto-pausing.
*   **EC2 Client Specific:** `al2_inst_type`, `al2_ssh_key_name`, `al2_cloud_init_script`, `authorized_ips`.

## Usage (Deploying Serverless v1)

1.  **Initialize Terraform:**
    ```bash
    terraform init
    ```
2.  **Plan Changes:**
    ```bash
    terraform plan
    ```
3.  **Apply Changes:**
    ```bash
    terraform apply
    ```
    Confirm by typing `yes`.

## Connecting to Aurora Serverless v1

After successful deployment:

1.  **SSH into the EC2 Client Instance.**
2.  **Connect to Aurora MySQL using the Cluster Endpoint:**
    The cloud-init script installs MySQL client tools.
    ```bash
    mysql -h <aurora_cluster_endpoint_address> -u <aurora_sv1_master_username> -p <aurora_sv1_db_name>
    ```
    *   Enter the master password when prompted (RDS manages this password; for initial setup, if not using Secrets Manager, it might need to be set manually or a default known one used if `manage_master_user_password` is not true or if `master_password` is set).
    *   `<aurora_cluster_endpoint_address>`: The cluster endpoint DNS name (from Terraform outputs or AWS console).

    If the cluster had auto-paused, this connection attempt will trigger it to resume, which might take a short while.

## Manual Upgrade Path to Aurora Serverless v2

This project includes a set of helper scripts in the `_upgrade_serverless_v1_to_v2/` subdirectory. These scripts outline a **manual, multi-step process using the AWS CLI** to upgrade an Aurora Serverless v1 cluster (like the one provisioned by this Terraform code) to Aurora Serverless v2.

**Important Considerations:**
*   **Complexity:** This is a complex procedure and should be undertaken with caution, preferably in a non-production environment first.
*   **Downtime:** The process involves converting the cluster to provisioned and then to Serverless v2, which will incur downtime.
*   **Engine Version Compatibility:** Direct upgrades from some Serverless v1 engine versions (e.g., those based on MySQL 5.6) to Serverless v2 (which typically requires newer MySQL versions like 8.0) are not straightforward. The scripts likely address this by first upgrading the engine version while in a provisioned state.
*   **AWS CLI and Permissions:** You will need the AWS CLI installed and configured with appropriate permissions to perform RDS modifications.

**Overview of the Upgrade Scripts:**
The scripts in `_upgrade_serverless_v1_to_v2/` are intended to be run manually and sequentially. Their general purpose is as follows:

1.  **`1_create_attach_new_param_group.sh`:**
    *   **Purpose:** Creates new DB cluster and instance parameter groups compatible with the target engine version for the upgrade (e.g., a version compatible with Serverless v2, like Aurora MySQL 3.x / MySQL 8.0.x). Attaches these new parameter groups to the existing cluster. This step is crucial for preparing the cluster for an engine version upgrade.

2.  **`2_convert_serverless_v1_to_provisioned.sh`:**
    *   **Purpose:** Modifies the existing Aurora Serverless v1 cluster to become a **provisioned cluster**. This involves adding at least one provisioned instance and changing the engine mode. This is a necessary intermediate step before an engine version upgrade or conversion to Serverless v2.

3.  **`3_upgrade_provisioned_cluster_engine_version.sh`:**
    *   **Purpose:** Upgrades the engine version of the now-provisioned cluster to one that is compatible with Aurora Serverless v2 (e.g., from an Aurora MySQL 2.x/MySQL 5.7.x version to an Aurora MySQL 3.x/MySQL 8.0.x version).

4.  **`4_modify_provisioned_cluster_for_serverless_v2.sh`:**
    *   **Purpose:** Modifies the provisioned cluster's settings (if necessary) to meet the requirements for Serverless v2, potentially adjusting instance classes or other parameters.

5.  **`5_create_serverless_v2_instance.sh`:**
    *   **Purpose:** Adds a new Aurora Serverless v2 compatible instance to the provisioned cluster. This is done by specifying an instance class that supports Serverless v2 (e.g., `db.serverless`).

6.  **`6_delete_provisioned_instance.sh`:**
    *   **Purpose:** After confirming the Serverless v2 instance is operational and the cluster supports Serverless v2 (possibly by modifying the cluster's capacity type settings), this script would delete the original provisioned instance(s) that were part of the intermediate upgrade steps. The cluster would then run with only Serverless v2 instances.

**Disclaimer:** These scripts are guides for a manual process. Thoroughly review and adapt them to your specific cluster details, engine versions, and AWS environment before execution. Always back up your database before attempting such significant changes. This manual path highlights the complexities that can arise with major version upgrades and transitions between different Aurora service models.
