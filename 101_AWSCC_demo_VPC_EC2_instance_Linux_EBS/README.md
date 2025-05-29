# Terraform AWS: Linux EC2 Instance with EBS using AWS Cloud Control (awscc) and AWS Providers

This Terraform project demonstrates provisioning a Linux EC2 instance with an attached EBS volume within a new VPC. The primary goal is to utilize the **AWS Cloud Control (awscc) provider** for as many resources as possible. However, due to certain limitations in the `awscc` provider at the time of this project's creation, the traditional **AWS (aws) provider** is used as a fallback for specific resources or features not yet fully supported by `awscc`.

This project serves as an example of integrating both providers to leverage the newer `awscc` capabilities while ensuring full infrastructure deployment by filling gaps with the mature `aws` provider.

## Provider Usage and `awscc` Limitations

The `awscc` provider offers a direct interface to AWS Cloud Control API, providing access to the latest AWS services and features. However, it may not yet cover all resources or functionalities available in the traditional `aws` provider.

Based on observations during the creation of this project (referencing notes from `README_AWSCC.md`):

*   **Resources Managed by `aws` Provider due to `awscc` Limitations:**
    *   **EC2 Instance (`aws_instance`):** The `awscc` provider lacked a direct equivalent for creating EC2 instances.
    *   **Internet Gateway Attachment (`aws_internet_gateway_attachment`):** While `awscc` could create an IGW, attaching it to the VPC required the `aws` provider.
    *   **Route Table and Routes (`aws_route_table`):** Modifying the default route table or reliably adding specific route rules (like a default route to an IGW) was more straightforward or only possible with the `aws` provider. `awscc` can associate a subnet with a route table.
    *   **Default Network ACL (`aws_default_network_acl`):** Direct modification of the default NACL was handled by the `aws` provider.
    *   **Default Security Group (`aws_default_security_group`):** Direct modification of the default security group was handled by the `aws` provider. `awscc` generally requires creating new security groups rather than modifying defaults.
    *   **SSH Key Pair (`aws_key_pair`):** Management of EC2 key pairs was done using the `aws` provider.
*   **Data Sources Managed by `aws` Provider:**
    *   **AMI (`data.aws_ami`):** The `awscc` provider did not offer a direct data source for querying AMIs.

## Tag Formatting Differences

A notable difference between the providers is the syntax for tags:

*   **`aws` provider:**
    ```terraform
    tags = {
      Name = "example-resource-name"
    }
    ```
*   **`awscc` provider:**
    ```terraform
    tags = [
      {
        key   = "Name",
        value = "example-resource-name"
      }
    ]
    ```
This project uses the respective formats when defining tags for resources managed by each provider.

## AWS Resources Provisioned

Below is a list of key resources created, specifying which Terraform provider manages them:

*   **VPC and Subnet:**
    *   `awscc_ec2_vpc` (**awscc**): The Virtual Private Cloud.
    *   `awscc_ec2_subnet` (**awscc**): A public subnet within the VPC.
*   **Internet Access:**
    *   `awscc_ec2_internet_gateway` (**awscc**): The Internet Gateway for the VPC.
    *   `aws_internet_gateway_attachment` (**aws**): Attaches the IGW to the VPC.
    *   `aws_route_table` (**aws**): A new route table created to manage routing for the public subnet.
    *   `aws_route` (**aws**): A default route (`0.0.0.0/0`) pointing to the IGW, added to the `aws_route_table`.
    *   `awscc_ec2_subnet_route_table_association` (**awscc**): Associates the `awscc_ec2_subnet` with the `aws_route_table`.
*   **EC2 Instance:**
    *   `data.aws_ami` (**aws**): Data source to find an appropriate Amazon Machine Image.
    *   `aws_key_pair` (**aws**): Manages the SSH key pair for EC2 instance access.
    *   `aws_instance` (**aws**): The Linux EC2 instance.
    *   `awscc_ec2_eip` (**awscc**): An Elastic IP address associated with the EC2 instance.
*   **EBS Volume:**
    *   `awscc_ec2_volume` (**awscc**): An Elastic Block Store volume.
    *   `awscc_ec2_volume_attachment` (**awscc**): Attaches the EBS volume to the EC2 instance.
*   **Security:**
    *   `aws_default_network_acl` (**aws**): Configuration of the default Network ACL for the VPC.
    *   `aws_default_security_group` (**aws**): Configuration of the default Security Group for the VPC, used by the EC2 instance.

## Architecture

The architecture is a standard single VPC with a public subnet hosting an EC2 instance and an attached EBS volume. The key aspect here is the hybrid provider approach:

```
        [ AWS Cloud - Region: var.aws_region ]
                         |
        +---------------------------------------------------+
        |         VPC (awscc_ec2_vpc - by awscc)            |
        |                (var.cidr_vpc)                   |
        |                                                 |
        |  +-------------------------------------------+  |
        |  |      Public Subnet (awscc_ec2_subnet)     |  |  (Managed by awscc)
        |  |         (var.cidr_subnet1)                |  |
        |  |                                           |  |  Route Table Association
        |  |  +-------------------+                   |  |  (awscc_ec2_subnet_route_table_association - awscc)
        |  |  |  EC2 Instance     |                   |  |        |
        |  |  |  (aws_instance)   |<---> EBS Volume    |  |        ▼
        |  |  |  - by aws         | (awscc_ec2_volume)|  |  +-----------------+
        |  |  |  - EIP (awscc)    | (by awscc)        |  |  | Route Table     |
        |  |  +-------------------+                   |  |  | (aws_route_table)|
        |  |          | (Default SG - by aws)         |  |  | - by aws        |
        |  +----------|-------------------------------+  |  | - Default Route |
        |             | (Default NACL - by aws)         |  |   (to IGW)      |
        |             ▼                                 |  +-----------------+
        |  [Internet Gateway (awscc_ec2_internet_gateway - by awscc)] |
        |      | (Attachment: aws_internet_gateway_attachment - by aws)
        +------|---------------------------------------------+
               |
            (Internet)
```

- **`awscc` Provider Manages:** VPC, Subnet, Internet Gateway (resource itself), EIP, EBS Volume, Volume Attachment, Subnet-Route Table Association.
- **`aws` Provider Manages:** IGW Attachment, Route Table and its routes, EC2 Instance, AMI data lookup, SSH Key Pair, Default Network ACL, Default Security Group modifications.

## Key Configuration Variables

*   `aws_region`: The AWS region for resource deployment (e.g., "us-east-1").
*   `az`: The Availability Zone for the public subnet and EC2 instance (e.g., "us-east-1a").
*   `cidr_vpc`: The CIDR block for the new VPC (e.g., "10.0.0.0/16").
*   `cidr_subnet1`: The CIDR block for the public subnet (e.g., "10.0.1.0/24").
*   `authorized_ips`: A list of IP addresses or CIDR blocks authorized for SSH access (e.g., `["YOUR_PUBLIC_IP/32"]`).
*   `inst1_type`: The EC2 instance type (e.g., "t3.micro").
*   `ebs_vol_size`: Size of the EBS volume in GiB (e.g., 8).
*   `ssh_key_name_to_upload_public_key`: Name for the EC2 key pair to be created by uploading a public key.
*   `ssh_public_key_path`: Path to the public SSH key file to be uploaded for the EC2 instance.
*   `cloud_init_script_path`: Path to the cloud-init script for EC2 instance setup (e.g., for EBS volume formatting/mounting if needed).

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

After deployment, you can SSH into the EC2 instance using its Elastic IP. The EBS volume will be attached and can be formatted and mounted as needed (potentially handled by the cloud-init script). This setup primarily demonstrates the co-existence and selective use of the `awscc` and `aws` Terraform providers.
