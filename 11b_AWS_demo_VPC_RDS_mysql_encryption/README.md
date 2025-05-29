# Terraform AWS: RDS for MySQL with Enforced Encryption (In-Transit & At-Rest)

This Terraform project provisions an AWS environment featuring an RDS for MySQL database instance with a strong emphasis on **encryption**. It builds upon the setup in project `11_AWS_demo_VPC_RDS_mysql` by adding mandatory encryption for data in transit and explicitly enabling encryption for data at rest. A pre-configured Amazon Linux 2 EC2 instance acts as a client, now connecting securely over SSL/TLS.

## Key Features & Concepts

*   **Builds on Project `11_`:** Utilizes a similar base infrastructure including a VPC, two public subnets for the DB subnet group, an EC2 client with MySQL tools, and diagnostic scripts (`latency.py`, `nmap.sh`).
*   **Encryption in Transit (Mandatory):**
    *   A custom `aws_db_parameter_group` is created and associated with the RDS instance.
    *   This parameter group sets the `require_secure_transport` parameter to `"1"` (or `ON`), which **forces all client connections to use SSL/TLS**. Connections not using SSL/TLS will be rejected by the MySQL server.
*   **Encryption at Rest (Explicitly Enabled):**
    *   The RDS instance is configured with `storage_encrypted = true`, ensuring that the underlying storage for the database, including automated backups, read replicas, and snapshots, is encrypted using AWS KMS.
*   **Standard RDS Features:** Includes configurable Multi-AZ deployment, instance class, MySQL version, DB Subnet Group, and private accessibility (not publicly accessible).
*   **Secure Client Connectivity:** The EC2 client, pre-configured with MySQL tools, will now connect to the RDS instance over an encrypted SSL/TLS channel.

## AWS Resources Provisioned

*   **Base Infrastructure (Similar to Project `11_`):**
    *   VPC with Internet Gateway.
    *   Two Public Subnets in different Availability Zones, forming an `aws_db_subnet_group`.
    *   Amazon Linux 2 EC2 client instance with EIP, MySQL client tools (via cloud-init), and diagnostic scripts (`scripts/latency.py`, `scripts/nmap.sh`).
*   **AWS RDS for MySQL Instance:**
    *   `aws_db_instance` with `engine = "mysql"`.
    *   **Custom DB Parameter Group (`aws_db_parameter_group`):**
        *   Created with a family compatible with the chosen MySQL version (e.g., `mysql8.0`).
        *   Parameter `require_secure_transport` is set to `1` (ON).
        *   Associated with the RDS instance.
    *   **Storage Encryption:** `storage_encrypted = true` is set.
    *   Configurable options: `mysql_instance_class`, `mysql_allocated_storage`, `mysql_db_name`, `mysql_engine_version`, `mysql_multi_az`.
    *   Random password for the 'admin' user.
    *   `publicly_accessible = false`.
    *   Associated with a dedicated RDS security group (`aws_security_group.demo11b_rds`).
*   **RDS Security Group (`demo11b-rds-sg`):**
    *   Allows inbound TCP port 3306 (MySQL) from the VPC's CIDR block (`var.cidr_vpc`), enabling access from the EC2 client.
*   **EC2 Client Security Group (`demo11b-ec2-sg` - typically VPC's default SG):**
    *   Allows inbound SSH (TCP port 22) from `authorized_ips`.
    *   Allows all outbound traffic (or at least traffic to the RDS security group on port 3306).

## Architecture

The overall architecture is similar to project `11_AWS_demo_VPC_RDS_mysql`, with the RDS instance in its private DB subnet group and the EC2 client in a public subnet. The key difference lies in the enforced SSL/TLS connections and encrypted storage for the RDS instance.

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
        |  | (EIP, AL2)      |<--SSL/TLS (3306) -->| RDS MySQL       |<-----|  (Spans Subnet1, Subnet2)
        |  | - MySQL Client  |   |                 | (Encrypted Storage) |      |
        |  | - Helper Scripts|   |                 | - require_secure_transport=ON |
        |  | (SG: demo11b-ec2)|  |                 | (SG: demo11b-rds)|      |
        |  |        |        |   |                 |                 |      |
        |  +--------|--------+   +-----------------+                 |      |
        |           | (SSH)                                           |      |
        |           ▼                                                 |      |
        |     [Internet Gateway]                                      |      |
        +-------------------------------------------------------------+------+
                      (Internet)                                      (KMS for Storage Encryption)

Traffic Flow:
  - User SSH -> EC2 Client Instance (via IGW & EIP).
  - EC2 Client -> RDS MySQL (Private IP, within VPC, TCP 3306, **SSL/TLS Encrypted**).
```

## Key Configuration Variables

Most variables are similar to project `11_AWS_demo_VPC_RDS_mysql`. Key ones include:

*   **General AWS:** `aws_region`, `az`, `az2`, `cidr_vpc`, `cidr_subnet1`, `cidr_subnet2`, `authorized_ips`.
*   **MySQL RDS Specific:**
    *   `mysql_identifier`, `mysql_instance_class`, `mysql_allocated_storage`, `mysql_db_name`, `mysql_engine_version`, `mysql_multi_az`.
    *   `require_secure_transport_pg_family`: The parameter group family string (e.g., `mysql8.0`) required for the custom DB parameter group. This must match the chosen MySQL version family.
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

## Connecting & Testing Encryption

After successful deployment:

1.  **SSH into the EC2 Client Instance:**
    Use its Elastic IP (EIP) and your SSH key.
    ```bash
    ssh -i /path/to/your/ssh-key.pem ec2-user@<EIP_EC2_Instance>
    ```

2.  **Connect to MySQL (SSL/TLS will be enforced):**
    The cloud-init script (`var.al2_cloud_init_script`) should have installed MySQL client tools.
    ```bash
    mysql -h <rds_endpoint_address> -u <admin_username> -p <mysql_db_name>
    ```
    *   Enter the **randomly generated password** when prompted.
    *   `<rds_endpoint_address>`: The endpoint DNS name of the RDS instance.
    *   `<admin_username>`: Usually 'admin'.
    *   `<mysql_db_name>`: The database name specified in `var.mysql_db_name`.

    Since `require_secure_transport` is ON, this connection will automatically attempt to use SSL/TLS. If the client cannot establish an SSL/TLS connection, the server will reject it.

3.  **Verify SSL/TLS Connection:**
    Once connected to MySQL using the `mysql` client:
    ```sql
    SHOW STATUS LIKE 'Ssl_cipher';
    -- Or, for more details:
    STATUS; -- or \s
    ```
    Look for the "SSL: Cipher in use is..." line in the output of `STATUS` or a non-empty value for `Ssl_cipher`. This confirms the connection is encrypted.

4.  **Client-side SSL Mode (Optional for further client enforcement):**
    While `require_secure_transport` enforces server-side SSL/TLS, you can be more explicit on the client-side if needed, or if you were dealing with specific CA certificates (not the case here as we are just enforcing encryption):
    ```bash
    # Example: Forcing SSL and verifying server CA (if you had one set up)
    # mysql -h <rds_endpoint_address> -u <admin_username> -p <mysql_db_name> --ssl-mode=VERIFY_CA --ssl-ca=/path/to/ca.pem

    # For this demo, simply connecting without extra SSL flags should work and be encrypted.
    ```

5.  **Using Helper Scripts (Located in `/tmp` on the EC2 instance):**
    *   **`latency.py`:**
        ```bash
        python /tmp/latency.py <rds_endpoint_address> 3306
        ```
    *   **`nmap.sh`:** (Ensure `nmap` is installed: `sudo yum install -y nmap`)
        ```bash
        /tmp/nmap.sh <rds_endpoint_address> 3306
        ```
        These scripts test basic network reachability. `nmap` might also provide information about the SSL handshake if run with appropriate flags (e.g., `--script ssl-enum-ciphers`).

This setup ensures that your RDS for MySQL database uses encrypted storage and mandates SSL/TLS for all client connections, significantly enhancing data security.
