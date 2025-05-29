# Terraform AWS: Protecting Application Load Balancer with AWS WAFv2

This Terraform project demonstrates how to enhance the security of an Application Load Balancer (ALB) by integrating it with **AWS WAFv2 (Web Application Firewall)**. The example focuses on implementing a geographic match rule to control access based on the originating country of requests.

## Purpose

The primary goal of this project is to illustrate how AWS WAFv2 can be used to protect web applications fronted by an ALB from common web exploits and to enforce custom access control rules. By deploying a Web ACL with specific rules, you can filter traffic before it reaches your application instances.

This project showcases:
*   Setting up a standard web application infrastructure with an ALB and backend EC2 instances.
*   Creating a WAFv2 Web ACL with a default blocking action.
*   Defining a specific rule within the Web ACL to allow traffic from certain countries (geographic matching).
*   Associating the Web ACL with an Application Load Balancer.

## Key Components

### 1. Web Application Infrastructure (Similar to Project `04` or `18`)

*   **VPC (Virtual Private Cloud):**
    *   Configured with public and private subnets across multiple Availability Zones for high availability.
    *   Includes an Internet Gateway (IGW) for the public subnets.
*   **NAT Gateway:**
    *   Deployed in a public subnet to provide outbound internet connectivity for instances in the private subnets (e.g., for OS updates).
*   **Bastion Host:**
    *   An EC2 instance in a public subnet for secure SSH access to instances in private subnets.
*   **Application Load Balancer (ALB) (`aws_lb.demo21_alb`):**
    *   Public-facing, deployed across the public subnets.
    *   Listens for HTTP traffic on port 80.
    *   Distributes traffic to a target group consisting of the EC2 web server instances.
*   **EC2 Web Server Instances:**
    *   Launched by an Auto Scaling Group (or as individual instances) into the private subnets.
    *   Run a simple web application (e.g., Apache or Nginx serving a test page).
*   **Security Groups:**
    *   Appropriate security groups for the ALB (allowing HTTP from the internet), web servers (allowing HTTP from the ALB, SSH from bastion), and bastion (allowing SSH from authorized IPs).

### 2. AWS WAFv2 Configuration (`10_waf_webacl.tf`)

*   **Web ACL (`aws_wafv2_web_acl.demo21`):**
    *   **Scope:** `REGIONAL` – This is required because the Web ACL is being associated with a regional resource (the Application Load Balancer).
    *   **Default Action:** Configured with `block {}`. This means that any request that does not match an explicit `allow` rule within the Web ACL will be blocked by default.
    *   **Rules:**
        *   **`rule1_allow_from_france_and_germany` (Example Rule):**
            *   **Priority:** `1` (lower numbers are evaluated first).
            *   **Action:** `allow {}`. If a request matches this rule, it will be allowed.
            *   **Statement (`geo_match_statement`):** This rule uses a geographic match statement. It is configured to allow requests only if they originate from specified `country_codes` (e.g., "FR" for France, "DE" for Germany).
    *   **Visibility Configuration (CloudWatch Metrics):**
        *   CloudWatch metrics for this Web ACL are disabled in this example (`cloudwatch_metrics_enabled = false`, `sampled_requests_enabled = false`) to simplify the demo and avoid incurring CloudWatch costs for metrics. In a production environment, enabling these is highly recommended for monitoring WAF activity.
*   **Web ACL Association (`aws_wafv2_web_acl_association.demo21`):**
    *   This resource links the created Web ACL (`aws_wafv2_web_acl.demo21`) with the Application Load Balancer (`aws_lb.demo21_alb.arn`). Once associated, the ALB will send incoming requests through the WAFv2 Web ACL for inspection according to its rules.

## Highlights

*   **ALB Protection with WAFv2:** Demonstrates the integration of WAFv2 as a protective layer for applications behind an ALB.
*   **Default Deny Approach:** The Web ACL uses a "default block" action, which is a security best practice. Only explicitly allowed traffic (matching an allow rule) can pass.
*   **Geographic Match Rule:** Provides a practical example of controlling access based on the geographic origin of requests using `geo_match_statement`.
*   **Clear Association:** Shows how a Web ACL is explicitly associated with an ALB to enforce the defined rules.

## Key Configuration Variables

Refer to `01_variables.tf` for a complete list. Key variables include:

*   **General AWS & VPC:** `aws_region`, `az_list` (list of AZs), `cidr_vpc`, `cidrs_subnet_public`, `cidrs_subnet_private`, `authorized_ips`.
*   **Bastion Host:** `bastion_inst_type`, `bastion_ssh_key_name`.
*   **Application (Web Server) Instances:** `web_inst_type`, `web_ssh_key_name`, user data script path.
*   **Auto Scaling Group (if used):** Capacities, launch template details.
*   **Application Load Balancer:** ALB name, listener configuration.
*   **WAFv2 Specific:**
    *   `waf_rule_geo_country_codes`: A list of country codes to be allowed by the geographic match rule (e.g., `["FR", "DE"]`).

## Architecture

```
        [ Internet Users ]
               |
               ▼ (HTTP Requests)
        +-----------------------+
        | AWS WAFv2 Web ACL     | (demo21)
        | - Default Action: BLOCK |
        | - Rule1 (GeoMatch):   |
        |   ALLOW FR, DE        |
        +--------+--------------+
                 | (Filtered Traffic)
                 ▼
        +-----------------------+      [ AWS Cloud - Region: var.aws_region ]
        | App Load Balancer     |
        | (demo21_alb)          |
        | (Public Subnets, HTTP/80) |
        +--------+--------------+
                 |
                 ▼ (To Target Group in Private Subnets)
        +-----------------------+
        | EC2 Web Servers       |
        | (Private Subnets)     |
        | - App Code            |
        +-----------------------+

* Bastion Host in Public Subnet for SSH access.
* NAT Gateway in Public Subnet for outbound from Private Subnets.
```
Incoming web requests first hit the AWS WAFv2 Web ACL associated with the ALB. WAFv2 inspects the requests based on the defined rules. If a request matches the "allow from FR, DE" rule, it's forwarded to the ALB. If it doesn't match this rule (and originates from another country), the default "block" action is applied, and the request is denied access (typically with an HTTP 403 Forbidden response).

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

## Testing WAF Protection

After successful deployment:

1.  **Find the ALB DNS Name:**
    Obtain the DNS name of the Application Load Balancer (`aws_lb.demo21_alb`) from the Terraform outputs or the AWS EC2 console under "Load Balancers".

2.  **Test from an Allowed Country:**
    *   If you are physically located in one of the countries specified in `var.waf_rule_geo_country_codes` (e.g., France or Germany in the example), or if you use a VPN or proxy service that makes your traffic appear to originate from one of these allowed countries:
    *   Open a web browser and navigate to `http://<ALB_DNS_Name>`.
    *   **Expected Result:** You should be able to access the web application successfully, and the test page served by the EC2 instances should be displayed.

3.  **Test from a Non-Allowed Country:**
    *   If you are physically located in a country NOT specified in `var.waf_rule_geo_country_codes`, or if you use a VPN/proxy to make your traffic appear from such a country (e.g., a country other than FR or DE):
    *   Open a web browser and navigate to `http://<ALB_DNS_Name>`.
    *   **Expected Result:** Your request should be **blocked** by AWS WAFv2. You will likely receive an **HTTP 403 Forbidden** error page. This indicates that the WAF's default block action is working correctly for traffic not matching the specific allow rule.

4.  **Check WAF Sampled Requests (if enabled):**
    *   If you had enabled `sampled_requests_enabled = true` in the Web ACL's visibility configuration, you could navigate to the AWS WAF console, select your Web ACL, and view sampled requests to see which ones were allowed or blocked and by which rule.

This testing procedure helps verify that the AWS WAFv2 Web ACL is correctly configured and protecting your Application Load Balancer based on the geographic origin of requests. You can further expand the Web ACL with more sophisticated rules (e.g., SQL injection protection, rate limiting) as needed.
