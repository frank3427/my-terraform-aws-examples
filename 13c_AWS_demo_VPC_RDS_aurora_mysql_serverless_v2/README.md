# Terraform AWS: RDS Aurora MySQL Serverless v2 Cluster

This Terraform project provisions an AWS environment featuring an AWS RDS Aurora MySQL **Serverless v2** cluster. It also includes a pre-configured Amazon Linux 2023 EC2 instance to act as a client for the Aurora cluster.

Aurora Serverless v2 is designed for demanding, highly variable workloads, offering granular, instance-level auto-scaling without the auto-pausing feature found in Serverless v1.

## Key Features & Concepts (Aurora Serverless v2)

*   **AWS RDS Aurora MySQL Serverless v2:** Provides on-demand, second-by-second auto-scaling of database capacity. It adjusts capacity in fine-grained increments, making it suitable for a wide range of applications, including those with high variability and sudden peaks.
*   **Configuration Differences from Serverless v1:**
    *   **Cluster Level (`aws_rds_cluster`):**
        *   The `engine_mode` attribute is **not** set to `"serverless"` (unlike v1). The serverless nature is determined by the instance class of its instances.
        *   A `serverlessv2_scaling_configuration` block is used to define the `min_capacity` and `max_capacity` in Aurora Capacity Units (ACUs).
    *   **Instance Level (`aws_rds_cluster_instance`):**
        *   At least one database instance must be explicitly defined.
        *   The `instance_class` for these instances is set to `"db.serverless"`. This, in conjunction with the cluster's `serverlessv2_scaling_configuration`, enables Serverless v2 behavior.
*   **No Auto-Pausing:** Unlike Serverless v1, Aurora Serverless v2 does **not** support auto-pausing. The database remains active even with no connections, with capacity scaling down to the configured `min_capacity`. This makes it more suitable for workloads that cannot tolerate the resume latency of Serverless v1.
*   **Granular Scaling:** Scales compute and memory capacity in place, often without requiring database restarts or connection drops for scaling events.
*   **Private Accessibility:** The Aurora cluster instances are not publicly accessible and rely on a DB Subnet Group and Security Groups for controlled access from within the VPC.
*   **EC2 Client:** An Amazon Linux 2023 instance with MySQL client tools, configured via cloud-init to connect to the Serverless v2 cluster endpoint.

## AWS Resources Provisioned (Terraform - Serverless v2)

*   **VPC (Virtual Private Cloud):**
    *   A new VPC with an Internet Gateway (IGW).
*   **Subnets:**
    *   **Public Client Subnet (`var.cidr_subnet_public`):** Hosts the EC2 client instance.
    *   **Private RDS Subnets (`var.cidrs_subnet_private_rds`):** Multiple private subnets in different Availability Zones for the Aurora Serverless v2 cluster instances.
*   **AWS RDS Aurora MySQL Cluster (`aws_rds_cluster`):**
    *   `engine = "aurora-mysql"`.
    *   Engine version compatible with Serverless v2 (e.g., Aurora MySQL 3.x, which is compatible with MySQL 8.0.x).
    *   **`serverlessv2_scaling_configuration` block:**
        *   `min_capacity`: Minimum Aurora Capacity Units (ACUs) (e.g., `var.aurora_mysql_serverless_v2_min_acu`).
        *   `max_capacity`: Maximum ACUs (e.g., `var.aurora_mysql_serverless_v2_max_acu`).
    *   Master username and initial database name are configurable. RDS manages the master password (can be retrieved if needed).
    *   **DB Subnet Group (`aws_db_subnet_group`):** Created from the private RDS subnets.
    *   Associated with a dedicated RDS security group (`aws_security_group.demo13c_rds`).
*   **Aurora Cluster Instance (`aws_rds_cluster_instance`):**
    *   At least one instance is explicitly defined (this project provisions one by default).
    *   `instance_class = "db.serverless"`. This is key for enabling Serverless v2.
    *   Attached to the `aws_rds_cluster` defined above.
    *   `publicly_accessible = false`.
*   **RDS Security Group (`demo13c-rds-sg`):**
    *   Allows inbound TCP port 3306 (MySQL) from the VPC's CIDR block (`var.cidr_vpc`).
*   **Linux EC2 Client Instance:**
    *   Amazon Linux 2023 instance (type `var.al2023_inst_type`) in the public client subnet, with an Elastic IP (EIP).
    *   Cloud-init script (`var.al2023_cloud_init_script` template) using the Aurora cluster endpoint and master username for MySQL client setup.
    *   Associated with its own security group (`aws_default_security_group.demo13c_ec2`).
*   **EC2 Client Security Group (`demo13c-ec2-sg` - typically VPC's default SG):**
    *   Allows inbound SSH from `authorized_ips`.
    *   Allows necessary outbound traffic to connect to the Aurora cluster.

## Architecture (Serverless v2)

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
        |  | EC2 Client Instance   |  | [Aurora Serverless v2 Endpoint] | |
        |  | (EIP, AL2023)         |<--->  MySQL Port 3306            | |
        |  | - MySQL Client        |  |   Instance 1 (db.serverless)    | |
        |  | (SG: demo13c-ec2)     |  |   (Scales ACUs based on load)   | |
        |  |        |              |  | (SG: demo13c-rds)               | |
        |  +--------|--------------+  +---------------------------------+ |
        |           | (SSH)                                               |
        |           ▼                                                     |
        |     [Internet Gateway]                                          |
        +-----------------------------------------------------------------+
                      (Internet)
```
The Aurora Serverless v2 cluster hosts one or more `db.serverless` instances in private subnets. These instances dynamically scale their capacity based on the `serverlessv2_scaling_configuration`. The EC2 client connects to a single cluster endpoint.

## Key Configuration Variables (Serverless v2)

*   **General AWS:** `aws_region`, `az_rds_list` (list of AZs for private subnets), `cidr_vpc`, `cidr_subnet_public`, `cidrs_subnet_private_rds`.
*   **Aurora Serverless v2 Specific:**
    *   `aurora_s_v2_cluster_identifier`: Cluster identifier.
    *   `aurora_s_v2_engine_version`: Serverless v2 compatible engine version (e.g., "8.0.mysql_aurora.3.03.0").
    *   `aurora_s_v2_master_username`: Master username.
    *   `aurora_s_v2_db_name`: Initial database name.
    *   `aurora_mysql_serverless_v2_min_acu`: Minimum Aurora Capacity Units (ACUs) for scaling.
    *   `aurora_mysql_serverless_v2_max_acu`: Maximum ACUs for scaling.
*   **EC2 Client Specific (Amazon Linux 2023):**
    *   `al2023_inst_type`: EC2 instance type (e.g., "t3.micro").
    *   `al2023_ssh_key_name`: Name of an existing EC2 Key Pair.
    *   `al2023_cloud_init_script`: Path to the cloud-init template file.
    *   `authorized_ips`: IPs/CIDRs for SSH access.

## Usage

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

## Connecting to Aurora Serverless v2

After successful deployment:

1.  **SSH into the EC2 Client Instance.**
2.  **Connect to Aurora MySQL using the Cluster Endpoint:**
    The cloud-init script installs MySQL client tools.
    ```bash
    mysql -h <aurora_cluster_endpoint_address> -u <aurora_s_v2_master_username> -p <aurora_s_v2_db_name>
    ```
    *   Enter the master password when prompted (RDS manages this password; for initial setup, if not using Secrets Manager, it might need to be set manually or a default known one used if `manage_master_user_password` is not true or if `master_password` is set).
    *   `<aurora_cluster_endpoint_address>`: The cluster endpoint DNS name (from Terraform outputs or AWS console).

    Connections to Serverless v2 are generally faster to establish than resuming a paused Serverless v1 cluster. The capacity will scale based on load within the defined min/max ACU range.

This project provides a modern, scalable Aurora Serverless v2 database suitable for a variety of workloads, accessible from a pre-configured EC2 client.
