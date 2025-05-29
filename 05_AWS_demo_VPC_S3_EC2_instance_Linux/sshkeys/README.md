# Sample SSH Key Pair for EC2 Instance Access

## Purpose of this Directory

This directory (`sshkeys/`) contains a **sample, pre-generated SSH key pair**:

*   `ssh_key_demo05` (Private Key)
*   `ssh_key_demo05.pub` (Public Key)

These keys are provided to allow the parent Terraform project (`05_AWS_demo_VPC_S3_EC2_instance_Linux/`) to be run "out-of-the-box" for demonstration purposes, enabling SSH access to the EC2 instance it provisions.

## How it's Used in the Parent Project

1.  **Public Key (`ssh_key_demo05.pub`):**
    *   The Terraform configuration in the parent directory (typically in a file like `05_ssh_key_pair.tf`, or directly within the `aws_instance` resource in `07_instance.tf`) is designed to use this public key.
    *   It reads the content of `ssh_key_demo05.pub` (often via a variable like `var.public_sshkey_path` which defaults to pointing to this file).
    *   This public key material is then used to create an `aws_key_pair` resource within AWS. The name of this AWS key pair resource might be something like `demo05_kp`.
    *   The created `aws_key_pair` is then associated with the EC2 instance(s) launched by the project. This allows anyone possessing the corresponding private key to SSH into the instance.

2.  **Private Key (`ssh_key_demo05`):**
    *   This is the corresponding private key to `ssh_key_demo05.pub`.
    *   **You would use this private key with your SSH client** (e.g., `ssh -i path/to/sshkeys/ssh_key_demo05 ec2-user@<instance_public_ip>`) to connect to the EC2 instance provisioned by the parent Terraform project.
    *   Ensure the permissions on this private key file are restrictive (e.g., `chmod 400 ssh_key_demo05`) for your SSH client to use it.

## Security Warning - IMPORTANT!

*   **SAMPLE KEYS FOR DEMONSTRATION ONLY:**
    The SSH key pair provided in this directory (`ssh_key_demo05` and `ssh_key_demo05.pub`) is intended **solely for demonstration and testing purposes for this specific Terraform project.**

*   **DO NOT USE FOR PRODUCTION OR SENSITIVE ENVIRONMENTS:**
    **You should NEVER use this sample private key (`ssh_key_demo05`) or its corresponding public key for any real, production, or sensitive environments.** Since this private key is publicly available as part of this project, anyone who has access to it could potentially gain access to any instance configured to use the corresponding public key.

*   **RECOMMENDATION FOR REAL USE:**
    1.  **Generate Your Own Secure SSH Key Pair:** Use a tool like `ssh-keygen` on your local machine to create your own unique and secure public/private key pair.
        ```bash
        ssh-keygen -t rsa -b 4096 -C "your_email@example.com" -f ~/.ssh/my_secure_key
        ```
        (This creates `my_secure_key` and `my_secure_key.pub` in your `~/.ssh/` directory).
    2.  **Use Your Own Public Key:**
        *   **Option A (Replace Sample):** Replace the content of `ssh_key_demo05.pub` in this directory with the content of **your own public key** (e.g., `cat ~/.ssh/my_secure_key.pub > ssh_key_demo05.pub`).
        *   **Option B (Update Terraform Variable):** Modify the Terraform configuration in the parent directory. If it uses a variable like `var.public_sshkey_path`, update your `terraform.tfvars` file or the variable's default value to point to the path of **your own public key file** (e.g., `public_sshkey_path = "~/.ssh/my_secure_key.pub"`).

By using your own key pair, you ensure that only you (or those you explicitly grant access to your private key) can access the EC2 instances provisioned by this Terraform project.
