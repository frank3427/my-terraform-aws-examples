# Terraform AWS: RDS for PostgreSQL with Secrets Manager Integration

This Terraform project provisions an AWS environment featuring an AWS RDS for PostgreSQL database instance (Single-AZ for this version). A key feature of this project is the integration with **AWS Secrets Manager** for managing the master user credentials of the RDS instance. It also includes a pre-configured Amazon Linux 2 EC2 instance as a client, complete with PostgreSQL client tools (`psql`) and SQL scripts for database interaction.

This project builds upon the concepts in `12_AWS_demo_VPC_RDS_postgresql` but focuses on secure credential management using Secrets Manager.

## Key Features & Concepts

*   **AWS RDS for PostgreSQL (Single-AZ):** Deploys a managed PostgreSQL database instance. For this demonstration, `multi_az` is set to `false`.
*   **AWS Secrets Manager for Master Credentials:**
    *   The RDS instance is configured with `manage_master_user_password = true`. This instructs RDS to automatically generate a strong password for the master user (e.g., 'adm') and store it securely in AWS Secrets Manager.
    *   Terraform uses data sources (`aws_secretsmanager_secret` and `aws_secretsmanager_secret_version`) to retrieve the automatically generated secret's ARN and its value (which is a JSON string containing the username and password).
*   **DB Subnet Group:** The RDS instance is placed within an `aws_db_subnet_group` that spans two public subnets in different Availability Zones, although the instance itself is Single-AZ.
*   **Private Accessibility:** The RDS instance is configured with `publicly_accessible = false`.
*   **EC2 Client with `psql` and Cloud-Init:** An Amazon Linux 2 EC2 instance is launched. Its cloud-init script is templated with RDS connection details, **including the master password retrieved from AWS Secrets Manager**, to configure `psql` for seamless connection.
*   **SQL Interaction Scripts:** SQL scripts (`sql_scripts/`) are copied to the EC2 client for database operations.
*   **Security Groups for Controlled Access:** Standard security group configurations for RDS and EC2.

## AWS Resources Provisioned

*   **Base Infrastructure (Similar to Project `12_`):**
    *   VPC with Internet Gateway.
    *   Two Public Subnets in different Availability Zones, forming an `aws_db_subnet_group`.
*   **AWS RDS for PostgreSQL Instance:**
    *   `aws_db_instance` resource with `engine = "postgres"`.
    *   `multi_az = false` (Single-AZ deployment).
    *   **Master Credential Management:**
        *   `manage_master_user_password = true`.
        *   `master_username` (e.g., 'adm', as per `var.pg_user`).
    *   Configurable options: `pg_instance_class`, `pg_allocated_storage`, `pg_db_name`, `pg_engine_version`.
    *   `publicly_accessible = false`.
    *   Associated with a dedicated security group (`aws_security_group.demo12b_rds`).
*   **AWS Secrets Manager Data Sources:**
    *   `data "aws_secretsmanager_secret"`: To find the secret associated with the RDS instance.
    *   `data "aws_secretsmanager_secret_version"`: To retrieve the actual secret value (username and password).
*   **Linux EC2 Client Instance:**
    *   An Amazon Linux 2 instance launched in one of the public subnets, with an Elastic IP (EIP).
    *   Uses a **cloud-init script** (`var.al2_cloud_init_script` template) populated with RDS connection details. **The master password used by this script is sourced from AWS Secrets Manager via Terraform.**
    *   SQL scripts from the `sql_scripts/` directory are copied to the EC2 instance.
    *   Associated with its own security group (`aws_default_security_group.demo12b_ec2`).
*   **Security Groups:**
    *   **RDS Security Group (`demo12b-rds-sg`):** Allows inbound TCP port 5432 (PostgreSQL) from the VPC's CIDR block.
    *   **EC2 Client Security Group (`demo12b-ec2-sg` - typically VPC's default SG):** Allows inbound SSH from `authorized_ips` and necessary outbound traffic to RDS.

## Architecture

```
        [ AWS Cloud - Region: var.aws_region ]
                         |
        +---------------------------------------------------+
        |                       VPC                       |
        |                (var.cidr_vpc)                   |
        |                                                 |
        |  +-----------------+   +-----------------+      |  +---------------------+
        |  | Public Subnet 1 |   | Public Subnet 2 |      |  | AWS Secrets Manager |
        |  | (var.az)        |   | (var.az2)       |      |  |---------------------|
        |  |-----------------|   |-----------------|      |  | RDS Master Secret   |
        |  | EC2 Client Inst |   |                 |      |  | (Username, Password)|
        |  | (EIP, AL2)      |   | RDS PostgreSQL  |<--------|  (Auto-generated)   |
        |  | - Cloud-Init    |<----(Uses Secret)----| (Single-AZ)     |  +---------------------+
        |  | - psql client   |   | - Not Publicly  |      |
        |  | - SQL Scripts   |   |   Accessible    |      |  RDS DB Subnet Group
        |  | (SG: demo12b-ec2)|  | (SG: demo12b-rds)|<-----|  (Spans Subnet1, Subnet2)
        |  |        |        |   |                 |      |
        |  +--------|--------+   +-----------------+      |
        |           | (SSH)                               |
        |           ▼                                     |
        |     [Internet Gateway]                          |
        +---------------------------------------------------+
                      (Internet)

Key Interactions:
1. RDS instance is created with `manage_master_user_password = true`.
2. RDS automatically generates a password and stores it in AWS Secrets Manager.
3. Terraform data sources retrieve this secret (username and password).
4. Terraform passes the retrieved credentials to the EC2 client's cloud-init script.
5. Cloud-init configures `psql` access (e.g., sets up `.pgpass`) using these credentials.
```
The EC2 client communicates with RDS using private IP addresses. The master password lifecycle is managed by AWS services.

## Key Configuration Variables

Most variables are similar to project `12_AWS_demo_VPC_RDS_postgresql`. Key ones include:

*   **General AWS:** `aws_region`, `az`, `az2`, `cidr_vpc`, `cidr_subnet1`, `cidr_subnet2`, `authorized_ips`.
*   **PostgreSQL RDS Specific:**
    *   `pg_identifier`: DB instance identifier (e.g., "demo12b-pg").
    *   `pg_instance_class`: DB instance class (e.g., "db.t3.micro").
    *   `pg_allocated_storage`: Allocated storage in GiB (e.g., 20).
    *   `pg_db_name`: The name of the initial database to create (e.g., "demodb").
    *   `pg_engine_version`: PostgreSQL engine version (e.g., "15.5").
    *   `pg_user`: The master username (defaults to 'adm'). This username is stored in Secrets Manager along with the auto-generated password.
    *   Note: `multi_az` is set to `false` in the Terraform code for this specific project version.
*   **EC2 Client Specific:** `al2_inst_type`, `al2_ssh_key_name`, `al2_cloud_init_script`.

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
    The cloud-init script (`var.al2_cloud_init_script`) is designed to:
    *   Install PostgreSQL client tools (`psql`).
    *   Retrieve the RDS connection details (endpoint, DB name, user) and the **master password fetched by Terraform from AWS Secrets Manager**.
    *   Configure the environment for `psql` connections, often by creating a `.pgpass` file in the `ec2-user`'s home directory. This file securely stores the password, allowing `psql` to connect without prompting for it.

    You should be able to connect directly using:
    ```bash
    psql -h <rds_endpoint_address> -U <pg_user> -d <pg_db_name>
    ```
    *   If the `.pgpass` file is correctly configured by cloud-init, you **should not be prompted for a password**.
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
    Review the SQL scripts to understand their purpose.

This setup demonstrates a more secure way to manage RDS master credentials by leveraging AWS Secrets Manager, reducing the need to handle or expose the master password directly in Terraform configurations or EC2 instance metadata after initial setup.
