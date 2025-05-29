# Terraform AWS: Global Accelerator with Internal ALB and Custom Header Verification

This Terraform project demonstrates an advanced networking setup using **AWS Global Accelerator** to provide a global, static entry point to an **internal Application Load Balancer (ALB)**. The internal ALB serves a web application running on EC2 instances in private subnets. A key feature of this setup is a custom HTTP header (`X-Origin-Verify`) validation mechanism at the internal ALB to ensure that traffic originates from a trusted path.

## Overview

The primary goal is to showcase how AWS Global Accelerator can improve the availability and performance of applications by directing traffic to optimal regional endpoints, in this case, an internal ALB. The internal nature of the ALB enhances security by not exposing it directly to the public internet.

To ensure that requests reaching the internal ALB have come through an intended path (e.g., via Global Accelerator, potentially fronted by a service like AWS CloudFront), the ALB's listener rules are configured to check for a custom HTTP header (`X-Origin-Verify`) containing a secret value.

This project provisions:
*   A VPC with public and private subnets.
*   An internal Application Load Balancer.
*   EC2 instances as web servers for the internal ALB.
*   AWS Global Accelerator configured to point to the internal ALB.
*   A bastion host for administrative access.
*   An additional public Application Load Balancer (its role will be discussed).

## Core Infrastructure

*   **VPC:** Configured with:
    *   A **public subnet**: Hosts the Bastion Host.
    *   Multiple **private subnets** (across different Availability Zones): Host the internal Application Load Balancer and the EC2 web server instances.
*   **NAT Gateway:** Deployed in the public subnet to provide outbound internet connectivity for instances in the private subnets (e.g., for OS updates).
*   **Bastion Host:** An EC2 instance in the public subnet for secure SSH access to web servers.
*   **EC2 Web Servers:** Two Amazon Linux 2 instances launched in the private subnets, serving a simple web page.

## Internal Application Load Balancer (`aws_lb.demo41_alb_private`)

*   **`internal = true`**: This ALB is internal and only accessible from within the VPC or via services like Global Accelerator that can route to internal IPs/ENIs.
*   **Deployment:** Deployed across the private subnets.
*   **Listener (HTTP Port 80):**
    *   **Default Action:** Configured to return an **HTTP 403 Forbidden** response. This means any request that doesn't match a specific rule with higher priority will be denied.
    *   **Listener Rule (Priority 1):**
        *   **Condition:** Checks for the presence of an HTTP header `X-Origin-Verify` whose value matches a predefined secret (`var.header_secret_value`).
        *   **Action:** If the header condition is met, the request is forwarded to a target group consisting of the EC2 web server instances.
*   **Purpose of `X-Origin-Verify` Header:** This mechanism ensures that only requests containing the correct secret in the `X-Origin-Verify` header are processed by the backend web servers. It acts as a simple shared secret validation layer.

## AWS Global Accelerator (`aws_globalaccelerator_accelerator.demo41`)

*   **Static Anycast IP Addresses:** Provides two static IP addresses that serve as a fixed entry point to your application, regardless of changes to your backend infrastructure.
*   **Listener (`aws_globalaccelerator_listener.demo41_listener_tcp80`):**
    *   Listens on TCP port 80.
    *   Directs traffic to the configured endpoint group.
*   **Endpoint Group (`aws_globalaccelerator_endpoint_group.demo41_group1_region1`):**
    *   **Endpoint:** The **internal ALB (`aws_lb.demo41_alb_private.arn`)** is specified as the endpoint for this group. Global Accelerator routes traffic to the ENIs of this internal ALB.
    *   **`client_ip_preservation_enabled = true`**: When traffic is routed to ALB endpoints, this setting preserves the client's original IP address, which is then visible to the ALB and backend application.

## Traffic Flow and `X-Origin-Verify` Header

1.  Users/Clients send requests to one of the static IP addresses provided by Global Accelerator.
2.  Global Accelerator routes this traffic to the internal Application Load Balancer in the private subnets.
3.  The internal ALB inspects the incoming request:
    *   If the request contains the `X-Origin-Verify` header with the correct secret value (matching `var.header_secret_value`), the listener rule (priority 1) matches, and the request is forwarded to the EC2 web servers.
    *   If the header is missing or has an incorrect value, the priority rule does not match, and the listener's default action is triggered, returning an HTTP 403 Forbidden response.

**How is the `X-Origin-Verify` header set?**

*   **This Terraform project does NOT provision AWS CloudFront.**
*   The existing `README.md` (before this update) mentioned a CloudFront distribution that adds this custom header. **AWS CloudFront** is indeed a common and recommended way to achieve this:
    *   You would set up a CloudFront distribution.
    *   Global Accelerator's static IPs (or a custom domain pointing to them) would be the origin for CloudFront.
    *   CloudFront would be configured with an "Origin Request Policy" or Lambda@Edge function to add the `X-Origin-Verify` header with the secret value to requests before forwarding them to the Global Accelerator origin.
*   **Direct Global Accelerator Testing:** For testing the setup deployed by *this specific Terraform project* (without an external CloudFront distribution), clients (e.g., `curl`) **must manually include the `X-Origin-Verify` header** with the correct secret value in their HTTP requests to the Global Accelerator's static IPs. Failure to do so will result in the 403 Forbidden error from the internal ALB.

## Public Application Load Balancer (`aws_lb.demo41_alb_public`)

This project also provisions a **public Application Load Balancer** (via `10_elb_alb_public.tf`).
*   **Purpose:** This public ALB provides an alternative, direct public entry point to the web application (or a similar application, depending on its target group configuration).
*   **Custom Header Requirement:** It is likely that this public ALB is also configured with a similar listener rule that requires the `X-Origin-Verify` header for successful access to the backend, mirroring the security mechanism of the internal ALB. This means direct access via its DNS name would also result in a 403 Forbidden unless the custom header is provided.

## Key Configuration Variables

Refer to `01_variables.tf` for a complete list. Key variables include:

*   `aws_region`: The AWS region for deployment.
*   `az_list`: List of Availability Zones for deploying resources.
*   `cidr_vpc`, `cidrs_subnet_public`, `cidrs_subnet_private_*`: CIDR blocks for VPC and subnets.
*   `authorized_ips`: Your public IP for SSH access to the bastion host.
*   **`header_secret_value`**: The secret string that must be present in the `X-Origin-Verify` header.
*   Instance types, AMI IDs, and SSH key names for EC2 instances.

## Usage Instructions

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
    Confirm by typing `yes`. Note the outputs, especially Global Accelerator static IPs and the `header_secret_value`.

## Testing the Setup

After successful deployment:

1.  **Obtain Global Accelerator Static IPs and Secret Value:**
    *   Get the static IP addresses of the Global Accelerator from the Terraform output (`global_accelerator_static_ips`) or the AWS Global Accelerator console.
    *   Note the `header_secret_value` you configured in your variables (or the default if one was provided).

2.  **Test via Global Accelerator (Manually Adding Header):**
    *   **Without the custom header (Expect 403 Forbidden):**
        ```bash
        GLOBAL_ACCELERATOR_IP="<one_of_the_ga_static_ips>"
        curl -v http://$GLOBAL_ACCELERATOR_IP/
        ```
        You should receive an HTTP 403 Forbidden response from the internal ALB.
    *   **With the custom header (Expect 200 OK):**
        ```bash
        SECRET_VALUE="<your_header_secret_value>" # From var.header_secret_value
        GLOBAL_ACCELERATOR_IP="<one_of_the_ga_static_ips>"
        
        curl -v -H "X-Origin-Verify: $SECRET_VALUE" http://$GLOBAL_ACCELERATOR_IP/
        ```
        You should receive a 200 OK response with the content from your web servers.

3.  **Test Public ALB (Optional):**
    *   Obtain the DNS name of the public ALB (`aws_lb.demo41_alb_public`) from Terraform outputs or the AWS console.
    *   Test with and without the `X-Origin-Verify` header, similar to the Global Accelerator tests. You will likely observe the same behavior (403 without header, 200 with header).

This setup demonstrates a secure way to expose an internal application globally using Global Accelerator, with an additional layer of request validation via a custom header. For a production-grade solution using this pattern, AWS CloudFront would typically be used to manage the addition of the custom header.
