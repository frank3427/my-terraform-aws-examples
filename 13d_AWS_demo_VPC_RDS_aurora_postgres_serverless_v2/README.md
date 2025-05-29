# Terraform AWS: RDS Aurora PostgreSQL Serverless v2 Cluster

This Terraform project provisions an AWS environment featuring an AWS RDS Aurora **PostgreSQL Serverless v2** cluster. The cluster is configured with multiple `db.serverless` instances, typically providing a serverless writer and one or more serverless readers. It also includes a pre-configured Amazon Linux 2023 EC2 instance to act as a client, complete with PostgreSQL client tools (`psql`) and a collection of SQL scripts for database interaction.

Aurora Serverless v2 for PostgreSQL offers on-demand, granular auto-scaling of database capacity, making it suitable for variable and demanding workloads without the auto-pausing feature of Serverless v1.

## Key Features & Concepts (Aurora PostgreSQL Serverless v2)

*   **AWS RDS Aurora PostgreSQL Serverless v2:** Provides auto-scaling of database capacity for Aurora PostgreSQL. It adjusts capacity in fine-grained increments based on application demand.
*   **Multiple `db.serverless` Instances:**
    *   The cluster is provisioned with **two explicit `aws_rds_cluster_instance` resources** (e.g., `demo13d_inst1`, `demo13d_inst2`).
    *   Both instances are configured with `instance_class = "db.serverless"`. This setup typically results in one instance acting as the writer and the other as a serverless reader, both capable of scaling their capacity independently based on the `serverlessv2_scaling_configuration`.
*   **Cluster Level Configuration (`aws_rds_cluster`):**
    *   `engine = "aurora-postgresql"`.
    *   A `serverlessv2_scaling_configuration` block defines the `min_capacity` and `max_capacity` in Aurora Capacity Units (ACUs) for each serverless instance in the cluster.
*   **No Auto-Pausing:** Unlike Serverless v1, Aurora Serverless v2 does not support auto-pausing. The database instances remain active, scaling down to the configured `min_capacity` when idle.
*   **Private Accessibility:** The Aurora cluster instances are not publicly accessible and use a DB Subnet Group and Security Groups for controlled access from within the VPC.
*   **EC2 Client with `psql` and SQL Scripts:** An Amazon Linux 2023 instance with `psql` (via cloud-init) and pre-copied SQL scripts for database operations.

## AWS Resources Provisioned (Terraform - Serverless v2)

*   **VPC (Virtual Private Cloud):**
    *   A new VPC with an Internet Gateway (IGW).
*   **Subnets:**
    *   **Public Client Subnet (`var.cidr_subnet_public`):** Hosts the EC2 client instance.
    *   **Private RDS Subnets (`var.cidrs_subnet_private_rds`):** Multiple private subnets in different Availability Zones for the Aurora Serverless v2 cluster instances.
*   **AWS RDS Aurora PostgreSQL Cluster (`aws_rds_cluster`):**
    *   `engine = "aurora-postgresql"`.
    *   Engine version compatible with Aurora PostgreSQL Serverless v2 (e.g., "15.x").
    *   **`serverlessv2_scaling_configuration` block:**
        *   `min_capacity`: Minimum ACUs (e.g., `var.aurora_postgresql_serverless_v2_min_acu`).
        *   `max_capacity`: Maximum ACUs (e.g., `var.aurora_postgresql_serverless_v2_max_acu`).
    *   Master username and initial database name are configurable. RDS manages the master password (retrieved by Terraform for EC2 client setup).
    *   **DB Subnet Group (`aws_db_subnet_group`):** Created from the private RDS subnets.
    *   Associated with a dedicated RDS security group (`aws_security_group.demo13d_rds`).
*   **Aurora Cluster Instances (`aws_rds_cluster_instance`) - Two Instances:**
    *   **Instance 1 (e.g., `demo13d_inst1` - typically the writer):**
        *   `instance_class = "db.serverless"`.
        *   Attached to the `aws_rds_cluster`.
        *   `publicly_accessible = false`.
    *   **Instance 2 (e.g., `demo13d_inst2` - typically a reader):**
        *   `instance_class = "db.serverless"`.
        *   Attached to the `aws_rds_cluster`.
        *   `publicly_accessible = false`.
*   **RDS Security Group (`demo13d-rds-sg`):**
    *   Allows inbound TCP port 5432 (PostgreSQL) from the VPC's CIDR block (`var.cidr_vpc`).
*   **Linux EC2 Client Instance:**
    *   Amazon Linux 2023 instance (type `var.al2023_inst_type`) in the public client subnet, with an Elastic IP (EIP).
    *   Cloud-init script (`var.al2023_cloud_init_script` template) using the Aurora cluster details (endpoint, username, password, DB name) for `psql` client setup and `.pgpass` configuration.
    *   SQL scripts from the `sql_scripts/` directory are copied to the EC2 instance.
    *   Associated with its own security group (`aws_default_security_group.demo13d_ec2`).
*   **EC2 Client Security Group (`demo13d-ec2-sg` - typically VPC's default SG):**
    *   Allows inbound SSH from `authorized_ips`.
    *   Allows necessary outbound traffic to connect to the Aurora cluster.

## Architecture (Serverless v2 with Multiple Instances)

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
        |  | EC2 Client Instance   |  | [Cluster Endpoint (Writer)]     | |
        |  | (EIP, AL2023)         |<---> Instance 1 (db.serverless)   | |
        |  | - psql Client         |  | [Reader Endpoint]               | |
        |  | - SQL Scripts         |<---> Instance 2 (db.serverless)   | |
        |  | (SG: demo13d-ec2)     |  | (Scales ACUs based on load)     | |
        |  |        |              |  | (SG: demo13d-rds)               | |
        |  +--------|--------------+  +---------------------------------+ |
        |           | (SSH)                                               |
        |           ▼                                                     |
        |     [Internet Gateway]                                          |
        +-----------------------------------------------------------------+
                      (Internet)
```
The Aurora PostgreSQL Serverless v2 cluster hosts multiple `db.serverless` instances (writer and reader) in private subnets. These instances dynamically scale their capacity. The EC2 client connects to the appropriate cluster endpoints.

## Key Configuration Variables (Serverless v2)

*   **General AWS:** `aws_region`, `az_rds_list` (list of AZs for private subnets), `cidr_vpc`, `cidr_subnet_public`, `cidrs_subnet_private_rds`.
*   **Aurora PostgreSQL Serverless v2 Specific:**
    *   `aurora_pg_s_v2_cluster_identifier`: Cluster identifier.
    *   `aurora_pg_s_v2_engine_version`: Serverless v2 compatible PostgreSQL engine version (e.g., "15.5").
    *   `aurora_pg_s_v2_master_username`: Master username (e.g., "adm").
    *   `aurora_pg_s_v2_db_name`: Initial database name.
    *   `aurora_postgresql_serverless_v2_min_acu`: Minimum ACUs for scaling per instance.
    *   `aurora_postgresql_serverless_v2_max_acu`: Maximum ACUs for scaling per instance.
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

## Connecting & Database Interaction

After successful deployment:

1.  **SSH into the EC2 Client Instance.**
2.  **Connect to Aurora PostgreSQL using `psql`:**
    The cloud-init script installs `psql` and should configure a `.pgpass` file using the RDS master password retrieved by Terraform, enabling password-less connection for the specified user and database.
    *   **To connect to the Writer Instance (for read/write operations):**
        Use the main cluster endpoint.
        ```bash
        psql -h <aurora_cluster_endpoint_address> -U <aurora_pg_s_v2_master_username> -d <aurora_pg_s_v2_db_name>
        ```
    *   **To connect to a Reader Instance (for read-only operations):**
        Use the reader cluster endpoint (usually ends with `-ro-` in the DNS name).
        ```bash
        psql -h <aurora_cluster_reader_endpoint_address> -U <aurora_pg_s_v2_master_username> -d <aurora_pg_s_v2_db_name>
        ```
    *   `<aurora_cluster_endpoint_address>` and `<aurora_cluster_reader_endpoint_address>` are available from Terraform outputs or the AWS console.
    *   If `.pgpass` is correctly set up by cloud-init, you should not be prompted for a password.

3.  **Using the SQL Scripts:**
    The `sql_scripts/` directory from your Terraform project is copied to the `ec2-user`'s home directory on the EC2 instance (e.g., `/home/ec2-user/sql_scripts/`).
    Navigate to this directory:
    ```bash
    cd ~/sql_scripts
    ```
    You can then execute these scripts using `psql`. For example, to run `01_create_table.sql` against the writer endpoint:
    ```bash
    psql -h <aurora_cluster_endpoint_address> -U <aurora_pg_s_v2_master_username> -d <aurora_pg_s_v2_db_name> -f 01_create_table.sql
    ```
    Review the SQL scripts to understand their purpose (e.g., creating tables, inserting data, querying).

This project provides a highly available and scalable Aurora PostgreSQL Serverless v2 setup, suitable for various modern applications.
