# Terraform AWS: EC2 Instance for NICE DCV (Desktop Cloud Visualization)

This Terraform project provisions a Linux EC2 instance (Amazon Linux 2) intended for use with **NICE DCV (Desktop Cloud Visualization)**. NICE DCV is a high-performance remote display protocol that provides customers with a secure way to deliver remote desktops and application streaming from any cloud or data center to any device, over varying network conditions.

**Important Note:** This project sets up the necessary infrastructure (VPC, EC2 instance, security groups). The configuration of users, their passwords, and the creation of DCV sessions on the instance are **manual post-provisioning steps**, guided by commands provided in the Terraform output.

## Purpose

The primary goal of this project is to:
1.  Provision an EC2 instance suitable for hosting NICE DCV server software.
2.  Configure the necessary network access (security groups) for DCV.
3.  Provide clear instructions and outputs to manually set up users and DCV sessions on the provisioned instance.

This setup allows users to connect to a graphical desktop environment or specific applications running on the EC2 instance from a remote client using a NICE DCV client or a web browser.

## Key Components & Assumptions

1.  **VPC Infrastructure:**
    *   A standard VPC with a public subnet and an Internet Gateway (IGW).
2.  **EC2 Instance:**
    *   An Amazon Linux 2 EC2 instance launched in the public subnet.
    *   An Elastic IP (EIP) is associated for a static public IP address.
    *   The instance type is configurable via `var.inst1_type`. For GPU-accelerated DCV sessions (e.g., for graphics-intensive applications), a GPU-equipped instance type (like G4dn, G5) would be required, along with appropriate AMI and GPU drivers. This basic setup does not explicitly configure GPU drivers.
3.  **NICE DCV Server Software Assumption:**
    *   **CRITICAL ASSUMPTION:** This project **assumes that the chosen Amazon Machine Image (AMI) comes with the NICE DCV server software pre-installed and configured to start on boot.**
    *   Many official AWS AMIs for specific purposes (e.g., some Amazon Linux 2 based AMIs, or specialized workstation AMIs) include DCV. If the chosen AMI does not have DCV pre-installed, you would need to add steps (e.g., in user data or manually) to download and install the NICE DCV server.
4.  **Cloud-Init Script (`cloud_init_al2.sh`):**
    *   The provided cloud-init script (`user_data`) performs basic package installations like `zsh`, `nmap`, and Docker.
    *   It does **not** install the NICE DCV server software itself, relying on the AMI assumption above.
5.  **Security Group (`aws_security_group.demo34_dcv`):**
    *   Allows inbound SSH (TCP port 22) from `authorized_ips` for instance management.
    *   Allows inbound traffic for NICE DCV:
        *   TCP port 8443 (for browser-based client access and session management).
        *   UDP port 8443 (for QUIC-based transport, enhancing performance over lossy networks).
    *   Allows all outbound traffic.

## Post-Provisioning Manual Setup (Crucial Steps)

After Terraform successfully provisions the EC2 instance, you **must perform the following manual steps by SSHing into the instance**. The necessary commands and generated passwords will be provided in the Terraform output.

1.  **SSH into the EC2 Instance:**
    Use the EIP address provided in the Terraform output and your SSH key.
    ```bash
    ssh -i /path/to/your/ssh-key.pem ec2-user@<EIP_of_EC2_Instance>
    ```

2.  **Set User Passwords:**
    Terraform generates random passwords for the default `ec2-user` and a new user `chris`. You need to set these passwords on the system. The Terraform output will provide commands similar to these:
    ```bash
    # Example commands from Terraform output:
    sudo passwd ec2-user # Then enter the password provided in output: <random_password_for_ec2_user>
    sudo useradd chris -m -s /bin/bash # If user 'chris' doesn't exist
    sudo passwd chris  # Then enter the password provided in output: <random_password_for_chris>
    ```
    Follow the prompts to set/confirm the passwords.

3.  **Create NICE DCV Sessions:**
    Once user passwords are set, create DCV sessions for them. The Terraform output will provide commands like:
    ```bash
    # Example commands from Terraform output for creating sessions:
    sudo dcv create-session ec2-user-session --user ec2-user --type CONSOLE
    sudo dcv create-session chris-session --user chris --type VIRTUAL
    # (CONSOLE for physical display, VIRTUAL for virtual X display)
    ```
    *   `CONSOLE` session: Attaches to the main X server display (display :0). Only one console session can run at a time per server.
    *   `VIRTUAL` session: Creates a new virtual X server display. Multiple virtual sessions can run concurrently.

4.  **Manage DCV Sessions (Optional Info):**
    The Terraform output also provides commands to list and close sessions:
    *   **List Sessions:** `sudo dcv list-sessions`
    *   **Close a Session:** `sudo dcv close-session <session_id_to_close>` (e.g., `sudo dcv close-session ec2-user-session`)

## Accessing DCV Sessions

Once a DCV session is created and running for a user:

1.  **Using a Web Browser (Recommended for ease of use):**
    *   Open a web browser and navigate to:
        `https://<EIP_of_EC2_Instance>:8443/#<session_id>`
        *   Replace `<EIP_of_EC2_Instance>` with the Elastic IP of your instance.
        *   Replace `<session_id>` with the ID of the session you want to connect to (e.g., `ec2-user-session` or `chris-session`).
    *   **Self-Signed Certificate Warning:** By default, the NICE DCV server uses a self-signed SSL certificate. Your browser will display a warning about this. You'll need to accept the risk or proceed (the specific steps vary by browser) to connect. For production, you should install a valid SSL certificate.
    *   You will be prompted for the username and the password you set in the "Post-Provisioning Manual Setup" steps.

2.  **Using the NICE DCV Native Client:**
    *   Download and install the NICE DCV client for your operating system from the AWS NICE DCV website.
    *   Launch the client and connect to `<EIP_of_EC2_Instance>:8443`.
    *   Enter the `<session_id>` when prompted, followed by the username and password.

## Highlights

*   **EC2 for Remote Desktops:** Sets up the foundation for using NICE DCV to stream remote desktops.
*   **CRITICAL: DCV Server Pre-Installed Assumption:** Success heavily relies on the chosen AMI having the NICE DCV server software already installed and configured.
*   **Manual Post-Setup:** User password setting and DCV session creation are essential manual steps guided by Terraform outputs.
*   **Browser & Client Access:** Supports connection via web browser (HTTPS on port 8443) and native NICE DCV clients.

## Key Configuration Variables

*   `aws_region`: The AWS region for deploying all resources (e.g., "us-east-1").
*   `az`: The Availability Zone for the public subnet and EC2 instance (e.g., "us-east-1a").
*   `cidr_vpc`: CIDR block for the VPC.
*   `cidr_subnet1`: CIDR block for the public subnet.
*   `authorized_ips`: List of IPs/CIDRs for SSH access to the EC2 instance and potentially for DCV access (though the DCV SG might be more open).
*   `inst1_type`: EC2 instance type (e.g., "t3.medium"). Ensure it's suitable for your DCV workload; GPU instances for graphics.
*   `al2_ssh_key_name`: Name of an existing EC2 Key Pair in the specified region for SSH access.

## Usage

1.  **Choose an AMI:** Ensure the AMI ID used in your Terraform variables (or selected by default) has NICE DCV server pre-installed.
2.  **Initialize Terraform:**
    ```bash
    terraform init
    ```
3.  **Plan Changes:**
    Review the resources that Terraform will create.
    ```bash
    terraform plan
    ```
4.  **Apply Changes:**
    Provision the AWS resources.
    ```bash
    terraform apply
    ```
    Confirm by typing `yes`. Pay close attention to the **Terraform outputs**, as they will contain the generated passwords and the manual commands needed for post-provisioning setup.

5.  **Perform Post-Provisioning Manual Setup:** SSH into the instance and execute the commands provided in the Terraform output to set user passwords and create DCV sessions.

This setup provides a remote desktop solution. Remember the importance of the AMI choice and the manual setup steps for full functionality. For production environments, consider automating the post-provisioning steps and managing SSL certificates for DCV.
