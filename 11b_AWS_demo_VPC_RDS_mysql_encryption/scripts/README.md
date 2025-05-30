# Utility and Diagnostic Scripts for EC2 MySQL Client (Encryption Focus)

## Purpose of this Directory

This directory (`scripts/`) contains utility and diagnostic scripts that are intended to be copied to the EC2 client instance. This instance is provisioned by the parent Terraform project (`11b_AWS_demo_VPC_RDS_mysql_encryption/`), which sets up an RDS for MySQL database with a strong emphasis on encryption (both in-transit and at-rest).

The primary purpose of these scripts is to provide tools for:
*   Testing network connectivity and performance to the secure RDS MySQL database instance.
*   General network troubleshooting from the perspective of the EC2 client instance, especially in the context of encrypted connections.

These scripts are deployed to the EC2 instance to aid operators in diagnosing issues or verifying the network and security setup after the infrastructure is provisioned.

## Script Descriptions

This directory contains the following scripts:

*   **`latency.py`**:
    *   **Type:** Python script.
    *   **Purpose:** This script is designed to measure network latency to a specified host and port. In the context of the parent project, it would be used to check the latency of the SSL/TLS encrypted connection from the EC2 client to the RDS MySQL database instance's endpoint on its specific port (default 3306).
    *   **Functionality (Assumed):** It likely attempts to establish a TCP connection (which would then be upgraded to SSL/TLS by MySQL if the server requires it) to the target host/port and measures the round-trip time or connection time.

*   **`nmap.sh`**:
    *   **Type:** Shell script.
    *   **Purpose:** This script serves as a wrapper or utility to use the `nmap` (Network Mapper) command. `nmap` is a versatile tool for network discovery, port scanning, and security auditing.
    *   **Functionality (Assumed):**
        *   It likely takes a target host (e.g., the RDS MySQL endpoint) and possibly port numbers as arguments.
        *   It then executes `nmap` with appropriate flags. For an encryption-focused setup, `nmap` could be used to:
            *   Verify if the MySQL port (default 3306) is open and reachable from the EC2 client.
            *   Potentially use `nmap` scripts (NSE - Nmap Scripting Engine) to check SSL/TLS handshake details, supported ciphers, or certificate information for the MySQL service, although the `nmap.sh` script itself might be a simpler wrapper.
        *   The script assumes that `nmap` is installed on the EC2 client instance (this is typically handled by the `cloud_init_al2_TEMPLATE.sh` script in the parent project's `cloud_init/` directory).

## Deployment by Terraform

These scripts are copied to the EC2 client instance and made executable by the Terraform configuration in the parent directory. This is typically handled using a `null_resource` in a file like `07_instance_linux_al2.tf` (or a similarly named file responsible for the EC2 client instance).

The deployment process within the `null_resource` usually involves:

1.  **Connection Establishment:** Terraform establishes an SSH connection to the newly created EC2 instance using the specified private key.
2.  **Copying Scripts (`provisioner "file"`):**
    *   The `provisioner "file"` block copies each script from this local `scripts/` directory to a specified location on the EC2 instance (e.g., `/tmp/`).
    ```terraform
    // Example snippet from the null_resource in the parent project
    provisioner "file" {
      source      = "${path.module}/scripts/latency.py"
      destination = "/tmp/latency.py"
      // ... connection details ...
    }
    provisioner "file" {
      source      = "${path.module}/scripts/nmap.sh"
      destination = "/tmp/nmap.sh"
      // ... connection details ...
    }
    ```
3.  **Making Scripts Executable (`provisioner "remote-exec"`):**
    *   After the files are copied, a `provisioner "remote-exec"` block is used to execute commands on the EC2 instance, such as changing the file permissions to make them executable.
    ```terraform
    // Example snippet from the null_resource in the parent project
    provisioner "remote-exec" {
      inline = [
        "chmod +x /tmp/latency.py",
        "chmod +x /tmp/nmap.sh"
      ]
      // ... connection details ...
    }
    ```

## Usage on EC2 Instance

Once the EC2 client instance is provisioned and these scripts have been successfully copied and made executable:

1.  **SSH into the EC2 Client Instance:**
    Use the Elastic IP (EIP) of the instance and your SSH key.
    ```bash
    ssh -i /path/to/your/ssh-key.pem <user>@<EIP_EC2_Instance>
    # Default user for Amazon Linux 2 is ec2-user
    ```

2.  **Run the Scripts:**
    The scripts will be located in the destination directory specified in the `provisioner "file"` block (e.g., `/tmp/`).

    *   **`latency.py`:**
        ```bash
        python /tmp/latency.py <target_host> <target_port>
        # Example to test latency to the RDS MySQL endpoint (which enforces SSL/TLS):
        # python /tmp/latency.py my-rds-mysql-endpoint.xxxxxxxx.awsregion.rds.amazonaws.com 3306
        ```
        (Replace `<target_host>` and `<target_port>` with the actual RDS endpoint and port).

    *   **`nmap.sh`:**
        ```bash
        /tmp/nmap.sh <target_host> [optional_nmap_arguments]
        # Example to scan common ports on the RDS MySQL endpoint:
        # /tmp/nmap.sh my-rds-mysql-endpoint.xxxxxxxx.awsregion.rds.amazonaws.com
        # Example to check if port 3306 is open and attempt to get service version info (which might show SSL details):
        # /tmp/nmap.sh my-rds-mysql-endpoint.xxxxxxxx.awsregion.rds.amazonaws.com -p 3306 -sV
        ```
        (Ensure `nmap` is installed on the EC2 instance, as handled by its cloud-init script).

These scripts are valuable for operators to perform initial diagnostics and verify that the network paths and security configurations allow secure communication with the RDS MySQL instance, especially when encryption in transit is a key requirement.
