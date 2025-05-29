# Terraform AWS: RDS for PostgreSQL (Multi-AZ) with EC2 Client and SQL Scripts

This Terraform project provisions an AWS environment featuring an AWS RDS for PostgreSQL database instance configured for Multi-AZ deployment. It also includes a pre-configured Amazon Linux 2 EC2 instance to act as a client, complete with PostgreSQL client tools (`psql`), a collection of SQL scripts for database interaction, and a shell script to guide manual creation of a read replica.

## Key Features & Concepts

*   **AWS RDS for PostgreSQL (Multi-AZ):** Deploys a managed PostgreSQL database instance with `multi_az = true`, ensuring high availability by synchronously replicating data to a standby instance in a different Availability Zone.
*   **DB Subnet Group:** The RDS instance is placed within an `aws_db_subnet_group` that spans two public subnets in different Availability Zones, which is essential for Multi-AZ functionality.
*   **Private Accessibility:** The RDS instance is configured with `publicly_accessible = false`, restricting direct access from the public internet.
*   **EC2 Client with `psql` and Cloud-Init:** An Amazon Linux 2 EC2 instance is launched and configured using a cloud-init script. This script is templated with the RDS instance's connection details and installs PostgreSQL client tools (specifically `psql`).
*   **SQL Interaction Scripts:** A directory of SQL scripts (`sql_scripts/`) is copied to the EC2 client, providing ready-to-use examples for creating tables, inserting data, and querying the database.
*   **Manual Read Replica Guide:** A shell script (`create_read_replica_in_different_AZ.sh`) is included in the project to provide guidance on manually creating a read replica for the PostgreSQL instance, though the replica creation itself is not automated by Terraform.
*   **Performance Insights:** Enabled for the RDS instance to help diagnose performance issues. Enhanced Monitoring is disabled by default but can be enabled.
*   **Security Groups for Controlled Access:** Dedicated security groups for RDS and EC2 manage traffic flow.

## AWS Resources Provisioned

*   **VPC (Virtual Private Cloud):**
    *   A new VPC with an associated Internet Gateway (IGW).
*   **Public Subnets (x2):**
    *   Two public subnets (`var.cidr_subnet1`, `var.cidr_subnet2`) created in different Availability Zones (`var.az`, `var.az2`). These are used for the RDS DB Subnet Group and hosting the EC2 client.
*   **AWS RDS for PostgreSQL Instance:**
    *   `aws_db_instance` resource with `engine = "postgres"`.
    *   `multi_az = true` for high availability.
    *   Configurable options: `pg_instance_class`, `pg_allocated_storage`, `pg_db_name`, `pg_engine_version`.
    *   A random password is generated for the 'adm' user (retrieval might require AWS Secrets Manager integration or checking Terraform outputs - not recommended for production).
    *   **DB Subnet Group (`aws_db_subnet_group`):** Created from the two public subnets.
    *   `publicly_accessible = false`.
    *   `monitoring_interval = 0` (Enhanced Monitoring disabled).
    *   `performance_insights_enabled = true`.
    *   Associated with a dedicated security group (`aws_security_group.demo12_rds`).
*   **RDS Security Group (`demo12-rds-sg`):**
    *   Allows inbound TCP port 5432 (PostgreSQL) from the VPC's CIDR block (`var.cidr_vpc`), enabling access from the EC2 client.
*   **Linux EC2 Client Instance:**
    *   An Amazon Linux 2 instance (type `var.al2_inst_type`) launched in one of the public subnets.
    *   An **Elastic IP (EIP)** is associated for a static public IP address.
    *   Uses a **cloud-init script** (from `var.al2_cloud_init_script` template) populated with RDS connection details. The script installs PostgreSQL client tools (`psql`).
    *   Associated with its own security group (`aws_default_security_group.demo12_ec2`, typically the VPC's default SG modified or a new one).
*   **EC2 Client Security Group (`demo12-ec2-sg` - typically VPC's default SG):**
    *   Allows inbound SSH (TCP port 22) from `authorized_ips`.
    *   Allows all outbound traffic (or at least traffic to the RDS security group on port 5432).
*   **SQL Scripts Provisioning (`null_resource`):**
    *   The `sql_scripts/` directory is copied from the local Terraform project to the `ec2-user`'s home directory on the EC2 instance using `file` provisioner within a `null_resource`.
*   **Network ACLs (NACLs):**
    *   Configured for the public subnets to allow inbound SSH, PostgreSQL (TCP 5432 to RDS from within VPC), outbound OS update traffic, and ephemeral ports for return traffic.

## Architecture

```
        [ AWS Cloud - Region: var.aws_region ]
                         |
        +---------------------------------------------------+
        |                       VPC                       |
        |                (var.cidr_vpc)                   |
        |                                                 |
        |  +-----------------+   +-----------------+      |
        |  | Public Subnet 1 |   | Public Subnet 2 |      | (In different AZs)
        |  | (var.az)        |   | (var.az2)       |      |
        |  |-----------------|   |-----------------|      |
        |  | EC2 Client Inst |   |                 |      |  RDS DB Subnet Group
        |  | (EIP, AL2)      |   | RDS PostgreSQL  |<-----|  (Spans Subnet1, Subnet2)
        |  | - Cloud-Init    |   | (Multi-AZ)      |      |
        |  | - psql client   |   | - Not Publicly  |      |
        |  | - SQL Scripts   |   |   Accessible    |      |
        |  | (SG: demo12-ec2)|   | (SG: demo12-rds)|      |
        |  |        |        |   |                 |      |
        |  +--------|--------+   +-----------------+      |
        |           | (SSH)                               |
        |           ▼                                     |
        |     [Internet Gateway]                          |
        +---------------------------------------------------+
                      (Internet)

Traffic Flow:
  - User SSH -> EC2 Client Instance (via IGW & EIP).
  - EC2 Client -> RDS PostgreSQL (Private IP, within VPC, TCP 5432).
    - Controlled by EC2 SG outbound rules and RDS SG inbound rules.
```
The RDS instance is deployed in a Multi-AZ configuration using its DB Subnet Group. The EC2 client, in a public subnet for SSH access, communicates with RDS using private IP addresses. SQL scripts are available on the EC2 instance for database interaction.

## Key Configuration Variables

*   **General AWS:**
    *   `aws_region`: AWS region (e.g., "us-east-1").
    *   `az`: Primary Availability Zone (e.g., "us-east-1a").
    *   `az2`: Secondary Availability Zone (e.g., "us-east-1b").
    *   `cidr_vpc`: CIDR block for the VPC (e.g., "10.90.0.0/16").
    *   `cidr_subnet1`: CIDR for public subnet 1.
    *   `cidr_subnet2`: CIDR for public subnet 2.
    *   `authorized_ips`: IPs/CIDRs for SSH access to the EC2 client (e.g., `["YOUR_PUBLIC_IP/32"]`).
*   **PostgreSQL RDS Specific:**
    *   `pg_identifier`: DB instance identifier (e.g., "demo12-pg").
    *   `pg_instance_class`: DB instance class (e.g., "db.t3.micro").
    *   `pg_allocated_storage`: Allocated storage in GiB (e.g., 20).
    *   `pg_db_name`: The name of the initial database to create (e.g., "demodb").
    *   `pg_engine_version`: PostgreSQL engine version (e.g., "15.5").
    *   `pg_user`: The master username (defaults to 'adm').
*   **EC2 Client Specific:**
    *   `al2_inst_type`: EC2 instance type (e.g., "t3.micro").
    *   `al2_ssh_key_name`: Name of an existing EC2 Key Pair for SSH.
    *   `al2_cloud_init_script`: Path to the cloud-init template file (e.g., "cloud_init_al2_TEMPLATE.sh").

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

## Connecting & Database Setup

After successful deployment:

1.  **SSH into the EC2 Client Instance:**
    Use its Elastic IP (EIP) and your SSH key.
    ```bash
    ssh -i /path/to/your/ssh-key.pem ec2-user@<EIP_EC2_Instance>
    ```

2.  **Connect to PostgreSQL using `psql`:**
    The cloud-init script (`var.al2_cloud_init_script`) should have installed PostgreSQL client tools and may have set up environment variables or a `.pgpass` file for easier connection.
    The RDS connection details (endpoint, DB name, user, password) are passed as template variables to the cloud-init script.
    You can typically connect using:
    ```bash
    psql -h <rds_endpoint_address> -U <pg_user> -d <pg_db_name>
    ```
    *   You will be prompted for the password. This is the **randomly generated password** for the `pg_user` (default 'adm'). You'll need to retrieve this password (e.g., from AWS Secrets Manager if integrated, or from Terraform output if exposed - though not recommended for production). Check the cloud-init script for how it handles the password (it might store it in `.pgpass`).
    *   `<rds_endpoint_address>`: The endpoint DNS name of the RDS instance.
    *   `<pg_user>`: The PostgreSQL admin username (default 'adm').
    *   `<pg_db_name>`: The database name specified in `var.pg_db_name`.

3.  **Using the SQL Scripts:**
    The `sql_scripts/` directory from your Terraform project is copied to the `ec2-user`'s home directory on the EC2 instance (e.g., `/home/ec2-user/sql_scripts/`).
    Navigate to this directory:
    ```bash
    cd ~/sql_scripts
    ```
    You can then execute these scripts using `psql`. For example, to run `01_create_table.sql`:
    ```bash
    psql -h <rds_endpoint_address> -U <pg_user> -d <pg_db_name> -f 01_create_table.sql
    ```
    Review the SQL scripts to understand their purpose (e.g., creating tables, inserting data, querying).

## Manual Read Replica Creation

This project includes a shell script named `create_read_replica_in_different_AZ.sh` located in the root of the Terraform project directory (not on the EC2 instance by default).

*   **Purpose:** This script is **not executed by Terraform**. It serves as a documented guide with AWS CLI commands to help you manually create a read replica for your PostgreSQL RDS instance, typically in a different Availability Zone for read scaling and potentially increased availability for reads.
*   **How to Use:**
    1.  Review the script content on your local machine where you run Terraform.
    2.  Modify any placeholder variables in the script (like RDS instance identifier, replica identifier, target AZ) to match your environment or desired configuration.
    3.  Ensure your AWS CLI is configured with appropriate permissions to create RDS read replicas.
    4.  Execute the script commands manually from your terminal.

This script is provided as a learning aid and a starting point for manual read replica creation. For automated read replica provisioning, you would use the `aws_db_instance` resource with the `replicate_source_db` argument in Terraform.
