# Terraform AWS: RDS for MySQL with EC2 Client and Diagnostic Scripts

This Terraform project provisions an AWS environment featuring an RDS for MySQL database instance within a new VPC. It also includes a pre-configured Amazon Linux 2 EC2 instance to act as a client for the MySQL database, along with helper scripts for network diagnostics.

## Key Features & Concepts

*   **AWS RDS for MySQL:** Deploys a managed MySQL database instance using the "mysql" engine.
*   **Configurable Multi-AZ:** The RDS instance can be deployed in a Multi-AZ configuration by setting `var.mysql_multi_az` to `true`, enhancing availability and durability.
*   **DB Subnet Group:** The RDS instance is placed within an `aws_db_subnet_group` that spans two public subnets in different Availability Zones, supporting Multi-AZ deployments.
*   **Private Accessibility:** The RDS instance is configured with `publicly_accessible = false`, restricting direct access from the public internet.
*   **EC2 Client with Cloud-Init:** An Amazon Linux 2 EC2 instance is launched and configured using a cloud-init script. This script is templated with the RDS instance's connection details and installs MySQL client tools.
*   **Diagnostic Helper Scripts:** Two scripts, `latency.py` (for checking network latency to specified ports) and `nmap.sh` (a wrapper for `nmap` to scan hosts/ports), are copied to the EC2 instance for troubleshooting network connectivity.
*   **Security Groups for Controlled Access:** Dedicated security groups for RDS and EC2 manage traffic flow.

## AWS Resources Provisioned

*   **VPC (Virtual Private Cloud):**
    *   A new VPC with an associated Internet Gateway (IGW).
*   **Public Subnets (x2):**
    *   Two public subnets (`var.cidr_subnet1`, `var.cidr_subnet2`) created in different Availability Zones (`var.az`, `var.az2`). These are used for the RDS DB Subnet Group and hosting the EC2 client.
*   **AWS RDS for MySQL Instance:**
    *   `aws_db_instance` resource with `engine = "mysql"`.
    *   Configurable options: `mysql_instance_class`, `mysql_allocated_storage`, `mysql_db_name`, `mysql_engine_version`, `mysql_multi_az`.
    *   A random password is generated for the 'admin' user (retrieval might require AWS Secrets Manager integration or checking Terraform outputs if exposed - not recommended for production).
    *   **DB Subnet Group (`aws_db_subnet_group`):** Created from the two public subnets.
    *   `publicly_accessible = false`.
    *   Associated with a dedicated security group (`aws_security_group.demo11_rds`).
*   **RDS Security Group (`demo11-rds-sg`):**
    *   Allows inbound TCP port 3306 (MySQL) from the VPC's CIDR block (`var.cidr_vpc`), enabling access from the EC2 client.
*   **Linux EC2 Client Instance:**
    *   An Amazon Linux 2 instance (type `var.al2_inst_type`) launched in one of the public subnets.
    *   An **Elastic IP (EIP)** is associated for a static public IP address.
    *   Uses a **cloud-init script** (from `var.al2_cloud_init_script` template) populated with RDS connection details. The script installs MySQL client tools.
    *   Associated with its own security group (`aws_default_security_group.demo11_ec2`, typically the VPC's default SG modified or a new one).
*   **EC2 Client Security Group (`demo11-ec2-sg` - typically VPC's default SG):**
    *   Allows inbound SSH (TCP port 22) from `authorized_ips`.
    *   Allows all outbound traffic (or at least traffic to the RDS security group on port 3306). If using the VPC's default SG, it typically allows all outbound and all inbound from itself, facilitating connectivity.
*   **Helper Scripts Provisioning (`null_resource`):**
    *   The `scripts/latency.py` and `scripts/nmap.sh` files are copied from the local Terraform project to the `/tmp` directory on the EC2 instance using `file` and `remote-exec` provisioners within a `null_resource`.
*   **Network ACLs (NACLs):**
    *   Configured for the public subnets to allow inbound SSH, MySQL (TCP 3306 to RDS from within VPC), outbound OS update traffic, and ephemeral ports for return traffic.

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
        |  | (EIP, AL2)      |   | RDS MySQL       |<-----|  (Spans Subnet1, Subnet2)
        |  | - Cloud-Init    |   | (Multi-AZ?)     |      |  (if var.mysql_multi_az = true)
        |  | - MySQL Client  |   | - Not Publicly  |      |
        |  | - Helper Scripts|   |   Accessible    |      |
        |  | (SG: demo11-ec2)|   | (SG: demo11-rds)|      |
        |  |        |        |   |                 |      |
        |  +--------|--------+   +-----------------+      |
        |           | (SSH)                               |
        |           ▼                                     |
        |     [Internet Gateway]                          |
        +---------------------------------------------------+
                      (Internet)

Traffic Flow:
  - User SSH -> EC2 Client Instance (via IGW & EIP).
  - EC2 Client -> RDS MySQL (Private IP, within VPC, TCP 3306).
    - Controlled by EC2 SG outbound rules and RDS SG inbound rules.
```
The RDS instance resides within its DB Subnet Group. The EC2 client instance, located in a public subnet for SSH access, communicates with RDS using private IP addresses. Helper scripts are available on the EC2 instance for diagnostics.

## Key Configuration Variables

*   **General AWS:**
    *   `aws_region`: AWS region (e.g., "us-east-1").
    *   `az`: Primary Availability Zone (e.g., "us-east-1a").
    *   `az2`: Secondary Availability Zone (e.g., "us-east-1b").
    *   `cidr_vpc`: CIDR block for the VPC (e.g., "10.80.0.0/16").
    *   `cidr_subnet1`: CIDR for public subnet 1.
    *   `cidr_subnet2`: CIDR for public subnet 2.
    *   `authorized_ips`: IPs/CIDRs for SSH access to the EC2 client (e.g., `["YOUR_PUBLIC_IP/32"]`).
*   **MySQL RDS Specific:**
    *   `mysql_identifier`: DB instance identifier (e.g., "demo11-mysql").
    *   `mysql_instance_class`: DB instance class (e.g., "db.t3.micro").
    *   `mysql_allocated_storage`: Allocated storage in GiB (e.g., 20).
    *   `mysql_db_name`: The name of the initial database to create (e.g., "demodb").
    *   `mysql_engine_version`: MySQL engine version (e.g., "8.0.35").
    *   `mysql_multi_az`: Boolean, set to `true` for Multi-AZ deployment.
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

## Connecting & Testing

After successful deployment:

1.  **SSH into the EC2 Client Instance:**
    Use its Elastic IP (EIP) and your SSH key.
    ```bash
    ssh -i /path/to/your/ssh-key.pem ec2-user@<EIP_EC2_Instance>
    ```

2.  **Connect to MySQL:**
    The cloud-init script (`var.al2_cloud_init_script`) should have installed MySQL client tools. You can connect using:
    ```bash
    mysql -h <rds_endpoint_address> -u <admin_username> -p <mysql_db_name>
    ```
    *   Enter the **randomly generated password** when prompted. You'll need to retrieve this password (e.g., from AWS Secrets Manager if integrated, or from Terraform output if exposed - though not recommended for production).
    *   `<rds_endpoint_address>`: The endpoint DNS name of the RDS instance.
    *   `<admin_username>`: Usually 'admin'.
    *   `<mysql_db_name>`: The database name specified in `var.mysql_db_name`.

3.  **Using Helper Scripts (Located in `/tmp` on the EC2 instance):**
    *   **`latency.py`:** A Python script to check network latency to a host and port.
        ```bash
        # Make it executable if needed: chmod +x /tmp/latency.py
        python /tmp/latency.py <rds_endpoint_address> 3306
        ```
        This can help diagnose if the EC2 instance can reach the RDS instance on the MySQL port.
    *   **`nmap.sh`:** A shell script that uses `nmap` (Network Mapper) to scan for open ports on a host. `nmap` might need to be installed (`sudo yum install -y nmap`).
        ```bash
        # Make it executable if needed: chmod +x /tmp/nmap.sh
        # Ensure nmap is installed: sudo yum install -y nmap
        /tmp/nmap.sh <rds_endpoint_address>
        # To scan specific ports:
        # /tmp/nmap.sh <rds_endpoint_address> 3306
        # /tmp/nmap.sh <rds_endpoint_address> 22,3306
        ```
        This script helps verify which ports are open and reachable on the RDS instance from the EC2 client's perspective.

This setup provides a functional MySQL database accessible from a pre-configured EC2 client, with tools for basic network diagnostics. Remember to manage the database admin password securely.
