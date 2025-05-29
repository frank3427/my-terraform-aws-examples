# Terraform AWS: EC2 Instances in Private Subnet Managed by AWS Systems Manager via VPC Endpoints

This Terraform project demonstrates how to provision Linux EC2 instances (Amazon Linux 2) in a **private subnet** and configure them to be managed by **AWS Systems Manager (SSM)** using **VPC Interface Endpoints**. This setup ensures that communication between your private instances and the SSM service occurs within your VPC, without requiring internet access for SSM operations.

## Purpose

The primary goal is to showcase a secure method for managing EC2 instances that do not have direct internet connectivity. By using VPC Interface Endpoints for Systems Manager, you can:
*   Keep instances in private subnets without assigning public IP addresses.
*   Enable full SSM functionality (Run Command, Session Manager, Patch Manager, etc.) for these private instances.
*   Enhance security by ensuring SSM traffic does not traverse the public internet.
*   Reduce reliance on bastion hosts for routine command execution or session management, although a bastion is included for direct SSH access if needed.

## Key Components

1.  **VPC Infrastructure:**
    *   A VPC with both a **public subnet** and a **private subnet**.
    *   **Public Subnet:** Hosts a Bastion Host and a NAT Gateway.
    *   **Private Subnet:** Hosts the EC2 instances that will be managed by SSM. These instances do not have public IP addresses.
    *   An Internet Gateway (IGW) is attached to the VPC for the public subnet and NAT Gateway.
2.  **NAT Gateway:**
    *   Deployed in the public subnet with an Elastic IP.
    *   Provides outbound internet connectivity for instances in the private subnet (e.g., for OS updates, downloading packages). This is separate from SSM traffic, which will use VPC Endpoints.
3.  **VPC Interface Endpoints for Systems Manager:**
    *   Three crucial **Interface Endpoints (`aws_vpc_endpoint`)** are created within the **private subnet**:
        *   `com.amazonaws.<region>.ssm`: For core Systems Manager service interactions.
        *   `com.amazonaws.<region>.ec2messages`: Used by the SSM Agent to communicate with the Systems Manager service.
        *   `com.amazonaws.<region>.ssmmessages`: Used by the SSM Agent for various communication channels, including Session Manager.
    *   `private_dns_enabled = true`: This is set for each endpoint. It allows instances within the VPC to use the standard AWS service DNS names (e.g., `ssm.region.amazonaws.com`), and these names will resolve to the private IP addresses of the VPC Interface Endpoints.
    *   These endpoints ensure that traffic from the SSM agent on private instances to the SSM service stays within the AWS network.
4.  **EC2 Instances (Managed Nodes):**
    *   A configurable number (`var.nb_instances_linux`) of Amazon Linux 2 EC2 instances are launched in the **private subnet**.
    *   These instances do **not** have associated Elastic IPs or public IP addresses.
5.  **IAM Role for Systems Manager (`aws_iam_role.demo20b_ssm_for_ec2`):**
    *   An IAM role is created and associated with both the private EC2 instances and the bastion host.
    *   **Policy Attachments:**
        *   `AmazonSSMManagedInstanceCore`: Grants core permissions for SSM management.
        *   `AmazonEC2RoleforSSM`: Older policy, often included for compatibility.
    *   **Instance Profile:** An `aws_iam_instance_profile` associates this role with the EC2 instances.
6.  **Bastion Host:**
    *   An Amazon Linux 2 EC2 instance launched in the **public subnet** with an Elastic IP.
    *   Allows secure SSH access to the private EC2 instances (by SSHing to the bastion first, then to private instances using their private IPs).
    *   This bastion host is also configured with the same IAM role, making it manageable via SSM as well.
7.  **Security Groups and Network ACLs:**
    *   **VPC Endpoint Security Group:** A security group is associated with the VPC Interface Endpoints. It's configured to allow inbound HTTPS (TCP port 443) traffic from resources within the VPC (specifically from the private subnet CIDR or the security group of the private instances).
    *   **Private EC2 Instance Security Group:** Allows inbound SSH (TCP port 22) from the Bastion Host's security group (or VPC CIDR) and potentially other necessary intra-VPC traffic. Outbound rules must allow HTTPS (TCP port 443) to the VPC Endpoint Security Group for SSM communication.
    *   **Bastion Security Group:** Allows inbound SSH (TCP port 22) from `authorized_ips`.
    *   NACLs are configured to permit necessary traffic flows (SSH, HTTPS to endpoints, outbound to NAT GW).

## Highlights

*   **Secure SSM Management for Private Instances:** Demonstrates how VPC Interface Endpoints enable SSM to manage instances without internet gateways directly on the instances or NAT gateways for SSM traffic itself.
*   **Role of NAT Gateway:** Clarifies that the NAT Gateway is still necessary for general outbound internet access from private instances (e.g., OS updates, package downloads), but not for SSM agent communication.
*   **IAM and Security Group Importance:** Emphasizes that the correct IAM role (`AmazonSSMManagedInstanceCore`) and properly configured security groups (allowing HTTPS to the VPC Endpoints) are critical for the setup to function.
*   **Private DNS for Endpoints:** `private_dns_enabled = true` simplifies configuration as instances can use standard AWS service hostnames.

## Key Configuration Variables

*   `aws_region`: The AWS region for deploying all resources (e.g., "us-east-1").
*   `az`: The primary Availability Zone used for subnets (e.g., "us-east-1a").
*   `cidr_vpc`: CIDR block for the VPC (e.g., "10.150.0.0/16").
*   `cidr_subnet_public`: CIDR block for the public subnet.
*   `cidr_subnet_private`: CIDR block for the private subnet.
*   `authorized_ips`: List of IPs/CIDRs for SSH access to the Bastion Host.
*   `inst_type`: EC2 instance type for private instances.
*   `bastion_inst_type`: EC2 instance type for the bastion host.
*   `al2_ssh_key_name`: Name of an existing EC2 Key Pair.
*   `nb_instances_linux`: Number of Linux EC2 instances to provision in the private subnet.

## Usage

1.  **Initialize Terraform:**
    ```bash
    terraform init
    ```
2.  **Plan Changes:**
    Review the resources that Terraform will create.
    ```bash
    terraform plan
    ```
3.  **Apply Changes:**
    Provision the AWS resources.
    ```bash
    terraform apply
    ```
    Confirm by typing `yes`.

## Verifying SSM Management

After successful deployment (allow a few minutes for instances to boot and the SSM agent to register via the VPC endpoints):

1.  **Check Managed Instances in AWS Systems Manager Console:**
    *   Navigate to "Systems Manager" in the AWS Management Console.
    *   Under "Node Management", click on "Managed instances".
    *   Both the **bastion host** and the **EC2 instances in the private subnet** should appear in the list with a "Ping status" of "Online".

2.  **Test with Session Manager (for Private Instances):**
    *   This is a key test for private instance manageability.
    *   In "Managed instances", select one of the **private EC2 instances**.
    *   Click the "Start session" button. This should open a shell session to your private instance directly in the browser or via the AWS CLI if configured. This connection is facilitated through the `ssmmessages` VPC endpoint.
    *   If you can successfully start a session, it confirms that SSM can communicate with the private instance via the VPC endpoints.

3.  **Test with Run Command (for Private Instances):**
    *   In the Systems Manager console, under "Node Management", click on "Run Command".
    *   Click "Run command".
    *   Select the command document `AWS-RunShellScript`.
    *   **Command parameters:** Enter a simple command like `hostname` or `df -h`.
    *   **Targets:** Select the private EC2 instances.
    *   Click "Run".
    *   Verify that the command executes successfully and you can see its output. This confirms core SSM functionality to private instances.

Successful Session Manager connections and Run Command executions on the private instances validate that they are correctly configured for SSM management using VPC Interface Endpoints.
