# Terraform AWS: Multi-Region Web Application with Primary/DR Sites and VPC Peering

This Terraform project demonstrates a multi-region web application architecture with a primary site in a main AWS region (Region 1) and a simpler disaster recovery (DR) site in a secondary AWS region (Region 2). The two regional VPCs are connected via VPC Peering. DNS records are created for both sites, but **automatic DNS failover requires manual configuration in AWS Route 53 beyond what this Terraform project provisions.**

## Purpose

The primary goals of this project are to illustrate:
1.  A common multi-region architecture for web applications, enhancing availability and disaster recovery capabilities.
2.  The use of Amazon EFS for shared web content in the primary, more complex site.
3.  A simplified DR site with static content deployment.
4.  Inter-region VPC connectivity using VPC Peering.
5.  Basic DNS setup for primary and DR sites, with clarification on the manual steps needed for true DNS failover.

## Architecture Overview

*   **Region 1 (Primary Site):** Hosts the main, fully-featured web application. This includes an Application Load Balancer (ALB), multiple EC2 web server instances in private subnets across Availability Zones, and Amazon EFS for shared web content.
*   **Region 2 (Disaster Recovery Site):** Hosts a simplified, standby version of the web application. This typically involves a single EC2 instance serving static content.
*   **VPC Peering:** Connects the VPC in Region 1 with the VPC in Region 2, allowing private IP communication between resources in these VPCs (e.g., for data replication, administrative access, though web content replication is handled differently here).
*   **DNS:** AWS Route 53 is used to create DNS records pointing to the primary ALB and the DR EC2 instance. However, routing policies for failover (e.g., Failover, Geolocation, Latency-based routing with health checks) are **not** configured by this Terraform project and would need to be set up manually in Route 53.

## Region 1 (Primary Site - `var.aws_region1`) Details

Managed by the AWS provider alias `aws.r1`.

*   **VPC (`aws_vpc.cr3_r1_vpc` - named `cr3-r1-vpc`):**
    *   Configured with public subnets (for bastion, ALB) and private subnets (for web servers) across multiple Availability Zones for high availability.
    *   Includes an Internet Gateway (`aws_internet_gateway.cr3_r1_igw`) for the public subnets.
    *   Includes a NAT Gateway (`aws_nat_gateway.cr3_r1_ngw`) in a public subnet to provide outbound internet access for instances in the private subnets.
*   **Bastion Host (`aws_instance.cr3_r1_bastion`):**
    *   An EC2 instance in a public subnet for secure SSH access to resources within the VPC, particularly the web servers in private subnets.
*   **Amazon EFS (`aws_efs_file_system.cr3_r1_efs`):**
    *   Provides shared, elastic file storage for web content (e.g., mounted at `/var/www/html`).
    *   **EFS Mount Targets (`aws_efs_mount_target.cr3_r1_efs_mt`)**: Created in the private subnets where the web server EC2 instances reside, allowing these instances to mount the EFS file system.
    *   Security group for EFS mount targets allows NFS traffic from the web servers' security group.
*   **EC2 Web Servers (`aws_instance.cr3_r1_websrv`):**
    *   Multiple Amazon Linux 2 instances (e.g., 3 as per original notes, count configurable via `var.r1_nb_web_instances`) launched in the private subnets across different AZs.
    *   **User Data:** Configured to install Apache (`httpd`), PHP, and the EFS utilities (`amazon-efs-utils`). It mounts the EFS file system to `/var/www/html` to serve shared web content.
*   **Application Load Balancer (ALB - `aws_lb.cr3_r1_alb`):**
    *   Public-facing, deployed across the public subnets in multiple Availability Zones.
    *   **Listeners:**
        *   An HTTP/80 listener that redirects all traffic to HTTPS/443.
        *   An HTTPS/443 listener that uses an ACM certificate (see below) and forwards traffic to a target group consisting of the EC2 web server instances.
*   **ACM Certificate (`aws_acm_certificate.cr3_r1_cert`):**
    *   An SSL/TLS certificate is provisioned via AWS Certificate Manager for the primary application's domain name (`var.dns_name_primary`).
    *   DNS validation is used to validate ownership of the domain. This requires appropriate CNAME records to be created in the Route 53 public hosted zone (managed by Terraform or pre-existing).

## Region 2 (Disaster Recovery Site - `var.aws_region2`) Details

Managed by the AWS provider alias `aws.r2`.

*   **VPC (`aws_vpc.cr3_r2_vpc` - named `cr3-r2-vpc`):**
    *   A simpler VPC configuration, typically with a single public subnet.
    *   Includes an Internet Gateway (`aws_internet_gateway.cr3_r2_igw`).
*   **DR EC2 Instance (`aws_instance.cr3_r2_dr_instance`):**
    *   A single Amazon Linux 2 instance launched in the public subnet.
    *   An Elastic IP (`aws_eip.cr3_r2_dr_eip`) is associated with it for a static public IP address.
    *   This instance serves as the DR web server.
    *   **Static Content Deployment:**
        *   The `website.zip` file (located in the root of the Terraform project directory) is copied to this EC2 instance using `provisioner "file"`.
        *   A `provisioner "remote-exec"` then unzips `website.zip` into `/var/www/html/` and starts the Apache (`httpd`) web server. This means the DR site serves a static version of the web content, which must be packaged in `website.zip`.

## Cross-Region Peering & DNS

*   **VPC Peering (`aws_vpc_peering_connection.cr3_r1_r2_peering`):**
    *   A VPC peering connection is established between `cr3-r1-vpc` (Region 1) and `cr3-r2-vpc` (Region 2).
    *   Route tables in both VPCs are updated to add routes for the peered VPC's CIDR block, enabling private IP communication between resources in the two VPCs. This could be used for data replication mechanisms (not implemented in this project for web content), administrative access, or other backend traffic.
*   **Route 53 DNS Records (`10_dns_and_cert.tf` - managed in Region 1 provider context):**
    *   Assumes a pre-existing public hosted zone in Route 53 for `var.r53_domain`.
    *   **Primary Site Record:** A CNAME record is created for the primary application's FQDN (`var.dns_name_primary`, e.g., `app.yourdomain.com`) pointing to the DNS name of the ALB in Region 1.
    *   **DR Site Record:** A CNAME record is created for the DR site's FQDN (`var.dns_name_secondary`, e.g., `dr.app.yourdomain.com`) pointing to the Elastic IP of the DR EC2 instance in Region 2.

## Manual DNS Failover Configuration (Important)

This Terraform project **provisions the basic DNS records** for the primary and DR sites but **does NOT implement automatic DNS failover.**

To achieve automatic failover from the primary site (Region 1 ALB) to the DR site (Region 2 EC2 instance), you would need to manually configure this in AWS Route 53 after the Terraform deployment. This typically involves:

1.  **Route 53 Health Checks:**
    *   Create health checks for the primary ALB endpoint in Region 1.
    *   Optionally, create a health check for the DR EC2 instance's EIP in Region 2 (though for a simple failover, the DR site is often assumed to be available or brought up during a DR event).
2.  **Failover Routing Policy:**
    *   Modify the DNS record for your main application FQDN (e.g., `var.dns_name_primary`).
    *   Change its routing policy to "Failover".
    *   **Primary Record:** Set the Region 1 ALB DNS name as the primary record, associated with its health check.
    *   **Secondary Record:** Set the Region 2 DR EC2 instance's EIP (or its DNS name `var.dns_name_secondary`) as the secondary record.
    *   Route 53 will then automatically route traffic to the secondary record if the primary record's health check fails.

Alternatively, other DNS strategies like latency-based routing or weighted routing could be used with health checks for more sophisticated traffic management and failover scenarios. These configurations are outside the scope of this Terraform automation.

## Highlights

*   **Multi-Region Primary/DR Architecture:** Provides a foundational example for deploying applications across two AWS regions for disaster recovery.
*   **Shared Web Content with EFS (Primary):** Demonstrates using EFS for shared `/var/www/html` content among web servers in the primary region.
*   **Static Content Deployment (DR):** Shows a simple DR strategy by deploying static content from a zip file to the DR EC2 instance.
*   **VPC Peering:** Enables private network connectivity between the two regional VPCs.
*   **Manual DNS Failover Steps Required:** Clearly states that automatic DNS failover is a manual post-configuration task in Route 53.

## Key Configuration Variables

*   `aws_region1`, `aws_profile1`: AWS region and CLI profile for the primary site (Region 1).
*   `aws_region2`, `aws_profile2`: AWS region and CLI profile for the DR site (Region 2).
*   `r1_cidr_vpc`, `r2_cidr_vpc`: VPC CIDR blocks for Region 1 and Region 2.
*   Subnet CIDRs for public and private subnets in both regions.
*   `r53_domain`: The parent domain name for DNS records (e.g., "yourdomain.com").
*   `dns_name_primary_leaf`, `dns_name_secondary_leaf`: Leaf parts for the primary and secondary DNS names (e.g., "app", "dr-app").
*   `website.zip_path`: Path to the `website.zip` file for the DR site content (defaults to `"./website.zip"`).
*   Instance types, AMI IDs, and SSH key names for EC2 instances in both regions.
*   `authorized_ips`: Your public IP for SSH access to bastion hosts.

## Usage Instructions

1.  **Prerequisites:**
    *   Ensure you have two AWS CLI profiles configured for the two different accounts/regions you intend to use.
    *   The `website.zip` file (containing static web content for the DR site) must exist at the path specified by `var.website.zip_path` (default is the project root).
    *   A public Route 53 hosted zone for `var.r53_domain` must exist in the account/region where DNS is managed (typically Account 1/Region 1 as per provider config for DNS resources).
2.  **Initialize Terraform:**
    ```bash
    terraform init
    ```
3.  **Plan Changes:**
    Review the resources that Terraform will create across both regions.
    ```bash
    terraform plan
    ```
4.  **Apply Changes:**
    Provision the AWS resources. This will take time as it involves creating VPCs, EC2 instances, EFS, ALB, and ACM certificates.
    ```bash
    terraform apply
    ```
    Confirm by typing `yes`.

## Testing

After successful deployment:

1.  **Access Primary Site (Region 1):**
    *   Navigate to `https://<var.dns_name_primary>` (e.g., `https://app.yourdomain.com`) in a web browser.
    *   You should see the web application served by the ALB and EC2 instances in Region 1, with content from EFS.

2.  **Access DR Site (Region 2):**
    *   Navigate to `http://<var.dns_name_secondary>` (e.g., `http://dr.app.yourdomain.com`) or `http://<EIP_of_DR_EC2_Instance>` in a web browser.
    *   You should see the static web content served by the DR EC2 instance in Region 2 (from `website.zip`).

3.  **Simulate DNS Failover (Manual):**
    *   To test the concept of failover, you would typically:
        1.  Manually configure Route 53 Health Checks and a Failover routing policy for `var.dns_name_primary` as described in the "Manual DNS Failover Configuration" section.
        2.  Simulate an outage of the primary site (e.g., stop the ALB or web server instances in Region 1).
        3.  Observe if Route 53 automatically (after health check failures and TTL expiry) starts resolving `var.dns_name_primary` to the DR site's IP/CNAME.
    *   Alternatively, without full failover routing, you could manually update the CNAME record for `var.dns_name_primary` to point to the DR site's CNAME (`var.dns_name_secondary`) or EIP to simulate a manual switch. Remember DNS propagation times.

This project provides a solid foundation for a multi-region application. Implementing robust, automated failover requires additional configuration beyond this Terraform setup.
