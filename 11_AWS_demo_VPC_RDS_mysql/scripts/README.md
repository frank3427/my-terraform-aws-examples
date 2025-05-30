# Utility and Diagnostic Scripts for EC2 MySQL Client

## Purpose of this Directory

This directory (`scripts/`) contains utility and diagnostic scripts that are intended to be copied to the EC2 client instance provisioned by the parent Terraform project (`11_AWS_demo_VPC_RDS_mysql/`).

The primary purpose of these scripts is to provide tools for:
*   Testing network connectivity and performance to the RDS MySQL database instance.
*   General network troubleshooting from the perspective of the EC2 client instance.

These scripts are deployed to the EC2 instance to aid operators in diagnosing issues or verifying the network setup after the infrastructure is provisioned.

## Script Descriptions

This directory contains the following scripts:

*   **`latency.py`**:
    *   **Type:** Python script.
    *   **Purpose:** This script is designed to measure network latency to a specified host and port. In the context of the parent project, it would typically be used to check the latency of the connection from the EC2 client to the RDS MySQL database instance's endpoint on its specific port (default 3306).
    *   **Functionality (Assumed):** It likely attempts to establish a connection or send minimal data to the target host/port and measures the round-trip time or connection time.

*   **`nmap.sh`**:
    *   **Type:** Shell script.
    *   **Purpose:** This script serves as a wrapper or utility to use the `nmap` (Network Mapper) command. `nmap` is a powerful tool for network discovery and security auditing.
    *   **Functionality (Assumed):**
        *   It likely takes a target host (e.g., the RDS MySQL endpoint) and possibly port numbers as arguments.
        *   It then executes `nmap` with appropriate flags to scan the target, which can be used to:
            *   Verify if the MySQL port (default 3306) is open and reachable from the EC2 client.
            *   Check for other open ports on a target.
            *   Gather information about the network services running on the target.
        *   The script assumes that `nmap` is installed on the EC2 client instance (this is typically handled by the `cloud_init_al2_TEMPLATE.sh` script in the parent project's `cloud_init/` directory).

## Deployment by Terraform

These scripts are copied to the EC2 client instance and made executable by the Terraform configuration in the parent directory, specifically within a resource like `null_resource "ec2_provisioners"` located in a file such as `07_instance_linux_al2.tf`.

The deployment process typically involves these steps within the `null_resource`:

1.  **Connection Establishment:** Terraform establishes an SSH connection to the newly created EC2 instance using the specified private key.
2.  **Copying Scripts (`provisioner "file"`):**
    *   The `provisioner "file"` block is used to copy each script from this local `scripts/` directory to a temporary location on the EC2 instance (e.g., `/tmp/`).
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
    *   After copying, a `provisioner "remote-exec"` block is often used to run commands on the EC2 instance, including making these scripts executable.
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

Once the EC2 client instance is provisioned and these scripts are copied and made executable:

1.  **SSH into the EC2 Client Instance:**
    Use the Elastic IP (EIP) of the instance and your SSH key.
    ```bash
    ssh -i /path/to/your/ssh-key.pem <user>@<EIP_EC2_Instance>
    # Default user for Amazon Linux 2 is ec2-user
    ```

2.  **Run the Scripts:**
    Navigate to the directory where the scripts were copied (e.g., `/tmp/`) or invoke them using their full path.

    *   **`latency.py`:**
        ```bash
        python /tmp/latency.py <target_host> <target_port>
        # Example to test latency to RDS MySQL endpoint:
        # python /tmp/latency.py my-rds-mysql-endpoint.xxxxxxxx.awsregion.rds.amazonaws.com 3306
        ```
        (You would replace `<target_host>` and `<target_port>` with the actual RDS endpoint and port).

    *   **`nmap.sh`:**
        ```bash
        /tmp/nmap.sh <target_host> [optional_nmap_arguments]
        # Example to scan common ports on the RDS MySQL endpoint:
        # /tmp/nmap.sh my-rds-mysql-endpoint.xxxxxxxx.awsregion.rds.amazonaws.com
        # Example to check if port 3306 is open:
        # /tmp/nmap.sh my-rds-mysql-endpoint.xxxxxxxx.awsregion.rds.amazonaws.com -p 3306
        ```
        (Ensure `nmap` is installed on the EC2 instance, which should be handled by its cloud-init script).

These scripts serve as helpful tools for operators to perform quick diagnostics and network checks from the client instance perspective, particularly for verifying connectivity to the RDS MySQL database.
