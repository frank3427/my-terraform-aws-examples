# Terraform AWS: RDS for Oracle (Custom EE) with EC2 Client

This Terraform project provisions an AWS environment featuring an RDS for Oracle (Custom Enterprise Edition) database instance within a new VPC. It also includes a pre-configured Amazon Linux 2 EC2 instance to act as a client for the Oracle database.

## Key Features & Concepts

*   **AWS RDS for Oracle (Custom EE):** Deploys a managed Oracle database instance using the "custom-oracle-ee" engine, allowing for more control over aspects like Oracle Media and Patches (though this demo uses standard settings).
*   **DB Subnet Group:** The RDS instance is placed within an `aws_db_subnet_group` that spans two public subnets in different Availability Zones. This ensures high availability for the RDS instance if multi-AZ deployment is enabled (not explicitly enabled in this basic demo but the subnet group supports it).
*   **Private Accessibility:** The RDS instance is configured with `publicly_accessible = false`, meaning it cannot be reached directly from the public internet. Access is restricted to resources within the VPC.
*   **EC2 Client with Cloud-Init:** An Amazon Linux 2 EC2 instance is launched and configured using a cloud-init script. This script is templated with the RDS instance's connection details (endpoint, SID, admin username) and is intended to install Oracle client tools (like SQL*Plus) and facilitate easy connection to the database.
*   **Security Groups for Controlled Access:**
    *   A dedicated security group for the RDS instance allows Oracle SQL*Net traffic (TCP port 1521).
    *   The EC2 instance uses a security group that allows SSH access and communication with the RDS instance.

## AWS Resources Provisioned

*   **VPC (Virtual Private Cloud):**
    *   A new VPC with an associated Internet Gateway (IGW).
*   **Public Subnets (x2):**
    *   Two public subnets (`var.cidr_subnet1`, `var.cidr_subnet2`) created in different Availability Zones (`var.az`, `var.az2`). These are primarily used for the RDS DB Subnet Group.
*   **AWS RDS for Oracle Instance:**
    *   `aws_db_instance` resource using `engine = "custom-oracle-ee"`.
    *   A random password is generated for the master 'admin' user and stored in AWS Secrets Manager (though retrieval might need additional configuration or manual access).
    *   **DB Subnet Group (`aws_db_subnet_group`):** Created from the two public subnets.
    *   `publicly_accessible = false`.
    *   Associated with a dedicated security group (`aws_security_group.demo10_rds`).
*   **RDS Security Group (`demo10-rds-sg`):**
    *   Allows inbound TCP port 1521 (Oracle SQL*Net) from `0.0.0.0/0`. **Note:** This is permissive for demonstration purposes. In a production environment, this should be restricted to specific security groups or IP ranges (e.g., the EC2 client's security group).
    *   Allows all traffic from within the VPC (specifically, from resources sharing the same VPC default security group, or if rules are added to allow traffic from the EC2 client's security group).
*   **Linux EC2 Client Instance:**
    *   An Amazon Linux 2 instance (type `var.al2_inst_type`) launched in one of the public subnets.
    *   An **Elastic IP (EIP)** is associated for a static public IP address.
    *   Uses a **cloud-init script** (from `var.al2_cloud_init_script` template) which is populated with RDS connection details (endpoint, SID, admin user). This script is designed to:
        *   Install Oracle Instant Client or full client.
        *   Configure TNSnames or environment variables for easy connection.
    *   Associated with its own security group (`aws_default_security_group.demo10_ec2`, typically the VPC's default SG modified or a new one).
*   **EC2 Client Security Group (`demo10-ec2-sg` - typically VPC's default SG):**
    *   Allows inbound SSH (TCP port 22) from `authorized_ips`.
    *   Allows all outbound traffic (or at least traffic to the RDS security group on port 1521). If using the VPC's default SG, it typically allows all outbound and all inbound from itself, which facilitates connectivity.
*   **Network ACLs (NACLs):**
    *   Configured for the public subnets to allow inbound SSH, Oracle SQL*Net (TCP 1521 to RDS), outbound OS update traffic, and ephemeral ports for return traffic.

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
        |  | (EIP, AL2)      |   | RDS Oracle      |<-----|  (Spans Subnet1, Subnet2)
        |  | - Cloud-Init    |   | (Custom EE)     |      |
        |  | - Oracle Client |   | - Not Publicly  |      |
        |  | (SG: demo10-ec2)|   |   Accessible    |      |
        |  |        |        |   | (SG: demo10-rds)|      |
        |  +--------|--------+   +-----------------+      |
        |           | (SSH)                               |
        |           ▼                                     |
        |     [Internet Gateway]                          |
        +---------------------------------------------------+
                      (Internet)

Traffic Flow:
  - User SSH -> EC2 Client Instance (via IGW & EIP).
  - EC2 Client -> RDS Oracle (Private IP, within VPC, TCP 1521).
    - Controlled by EC2 SG outbound rules and RDS SG inbound rules.
```
The RDS instance resides within its DB Subnet Group, making it accessible from resources within the VPC, such as the EC2 client instance. The EC2 instance is in a public subnet for external SSH access but communicates with RDS using private IP addresses.

## Key Configuration Variables

*   **General AWS:**
    *   `aws_region`: AWS region (e.g., "us-east-1").
    *   `az`: Primary Availability Zone (e.g., "us-east-1a").
    *   `az2`: Secondary Availability Zone (e.g., "us-east-1b").
    *   `cidr_vpc`: CIDR block for the VPC (e.g., "10.70.0.0/16").
    *   `cidr_subnet1`: CIDR for public subnet 1.
    *   `cidr_subnet2`: CIDR for public subnet 2.
    *   `authorized_ips`: IPs/CIDRs for SSH access to the EC2 client (e.g., `["YOUR_PUBLIC_IP/32"]`).
*   **Oracle RDS Specific:**
    *   `oracle_identifier`: DB instance identifier (e.g., "demo10-oracle").
    *   `oracle_instance_class`: DB instance class (e.g., "db.m5.large").
    *   `oracle_engine`: Defaults to "custom-oracle-ee".
    *   `oracle_edition`: Specific Oracle edition (e.g., "oracle-enterprise-edition"). This might be part of `engine_version` or a separate parameter depending on TF resource.
    *   `oracle_sid`: The Oracle System ID (e.g., "ORCL").
    *   `oracle_version`: Specific Oracle version (e.g., "19.0.0.0.ru-2023-10.rur-2023-10.r1").
    *   `oracle_license_model`: License model (e.g., "bring-your-own-license", "license-included").
    *   `allocated_storage`, `max_allocated_storage`.
    *   `db_name` (often same as `oracle_sid`).
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

## Connecting to Oracle

After successful deployment:

1.  **SSH into the EC2 Client Instance:**
    Use its Elastic IP (EIP) and your SSH key.
    ```bash
    ssh -i /path/to/your/ssh-key.pem ec2-user@<EIP_EC2_Instance>
    ```

2.  **Utilize Cloud-Init Setup:**
    The cloud-init script (`var.al2_cloud_init_script`) is intended to:
    *   Install Oracle client tools (e.g., SQL*Plus, Oracle Instant Client).
    *   Configure environment variables or TNSnames.ora using the RDS details (endpoint, SID, admin user) passed to the template.
    *   You might find connection scripts or aliases set up by cloud-init. Check the script's content for specifics.

3.  **Example Connection (Manual, if cloud-init doesn't fully automate):**
    If SQL*Plus is installed and your environment is set up (e.g., `ORACLE_HOME`, `LD_LIBRARY_PATH`, `PATH`), you would typically connect using:
    ```bash
    sqlplus <admin_username>/'<generated_password>'@//<rds_endpoint_address>:<rds_port>/<oracle_sid>
    ```
    *   `<admin_username>`: Usually 'admin'.
    *   `<generated_password>`: This is randomly generated by Terraform. You'll need to retrieve it (e.g., from AWS Secrets Manager if configured, or check Terraform output if exposed - though exposing secrets in output is not recommended for production).
    *   `<rds_endpoint_address>`: The endpoint DNS name of the RDS instance.
    *   `<rds_port>`: Usually 1521 for Oracle.
    *   `<oracle_sid>`: The Oracle SID (e.g., "ORCL").

    The cloud-init script should simplify this by pre-configuring TNS entries or providing wrapper scripts. Refer to the `cloud_init_al2_TEMPLATE.sh` for the exact methods it employs.

This setup provides a secure and convenient way to interact with your RDS for Oracle database instance from within your VPC. Remember to manage the admin password securely.
