# Terraform AWS: ElastiCache for Memcached Cluster with EC2 Client

This Terraform project demonstrates how to provision an **AWS ElastiCache for Memcached cluster** within a private subnet of a new VPC. It also includes an Amazon Linux 2 EC2 instance launched in a public subnet, pre-configured with `telnet` to act as a client for interacting with the Memcached cluster.

## Purpose

The primary goals of this project are to illustrate:
1.  The deployment of an ElastiCache for Memcached cluster.
2.  Placement of the Memcached cluster in a private subnet for enhanced security, making it accessible only from within the VPC.
3.  Configuration of network components (VPC, subnets, NAT Gateway, Security Groups) to allow controlled access to the Memcached cluster.
4.  Provisioning an EC2 client instance with tools (`telnet`) to connect to and interact with the Memcached cluster.

This setup is common for applications that need a fast, in-memory caching layer to reduce latency and database load.

## Key Components

1.  **VPC Infrastructure:**
    *   A new VPC configured with:
        *   A **public subnet**: Hosts a NAT Gateway and the EC2 client instance.
        *   A **private subnet**: Where the ElastiCache for Memcached cluster nodes are deployed.
    *   An Internet Gateway (IGW) attached to the VPC for the public subnet.
2.  **NAT Gateway:**
    *   Deployed in the public subnet with an Elastic IP.
    *   Provides outbound internet connectivity for resources in the private subnet. While Memcached itself typically doesn't initiate many outbound connections, this allows for potential OS updates or other needs if instances were directly in the private subnet (though ElastiCache nodes are managed by AWS).
3.  **AWS ElastiCache for Memcached Cluster (`aws_elasticache_cluster.memcached_cluster`):**
    *   **Engine:** `memcached`.
    *   **Engine Version:** Configurable via `var.memcached_version` (e.g., "1.6.17").
    *   **Node Type:** Configurable via `var.elasticache_node_type` (e.g., "cache.t3.micro").
    *   **Number of Nodes:** Configurable via `var.elasticache_nb_nodes` (e.g., 2).
    *   **ElastiCache Subnet Group (`aws_elasticache_subnet_group.memcached_subnet_group`):**
        *   Created using the **private subnet**. The Memcached cluster nodes will be launched within this subnet.
    *   **ElastiCache Security Group (`aws_security_group.memcached_sg`):**
        *   A dedicated security group for the Memcached cluster.
        *   Allows inbound traffic on the Memcached port (default 11211, configurable via `var.memcached_port`) from within the VPC (specifically, from the EC2 client's security group or VPC CIDR).
    *   **Parameter Group:** Uses a default parameter group corresponding to the chosen Memcached engine version (e.g., `default.memcached1.6`).
    *   `az_mode = "cross-az"` if `var.elasticache_nb_nodes > 1` to distribute nodes, or `"single-az"` otherwise.
4.  **Linux EC2 Client Instance:**
    *   An Amazon Linux 2 instance (or other OS as configured by `var.ami_id`, instance type `var.al2_inst_type`) launched in the public subnet.
    *   An **Elastic IP (EIP)** is associated for a static public IP address.
    *   **Cloud-Init Script (`user_data`):**
        *   A simple cloud-init script installs `telnet`, which is a common utility for basic interaction with Memcached servers.
    *   **Security Group:** Uses the VPC's default security group (`aws_default_security_group.default_sg_for_client`). This group is configured to:
        *   Allow inbound SSH (TCP port 22) from `authorized_ips`.
        *   Allow all outbound traffic, enabling it to connect to the Memcached cluster in the private subnet.

## Network Configuration

*   **Memcached in Private Subnet:** The ElastiCache Memcached cluster nodes are deployed into a private subnet. This means they do not have direct inbound or outbound internet access via an Internet Gateway, enhancing security.
*   **NAT Gateway:** Provides general outbound internet access for any resources within the private subnet that might require it (less critical for managed ElastiCache nodes themselves, but good practice for private subnets that might host other application components).
*   **Controlled Inbound Access (Security Groups):**
    *   The Memcached cluster's security group (`aws_security_group.memcached_sg`) is configured to allow inbound connections on the Memcached port (e.g., 11211) only from sources within the VPC, typically from the security group of the EC2 client instance.
    *   The EC2 client's security group allows outbound connections to the Memcached cluster.

## Highlights

*   **Private Memcached Cluster:** Demonstrates deploying ElastiCache for Memcached in a secure private subnet.
*   **EC2 Client with `telnet`:** Provides a simple client setup for direct interaction and testing of the Memcached cluster.
*   **Security Group Control:** Emphasizes the use of security groups to manage network access between the EC2 client and the Memcached nodes.
*   **Scalability:** The number of nodes in the Memcached cluster is configurable.

## Key Configuration Variables

*   **General AWS & VPC:**
    *   `aws_region`: AWS region for deployment.
    *   `az_list`: List of Availability Zones (used for subnet creation).
    *   `cidr_vpc`, `cidr_subnet_public`, `cidr_subnet_private`: CIDR blocks.
    *   `authorized_ips`: IPs/CIDRs for SSH access to the EC2 client.
*   **ElastiCache Memcached Specific:**
    *   `memcached_cluster_id`: Identifier for the Memcached cluster.
    *   `memcached_version`: Memcached engine version (e.g., "1.6.17").
    *   `elasticache_node_type`: Node type for Memcached nodes (e.g., "cache.t3.micro").
    *   `elasticache_nb_nodes`: Number of nodes in the cluster.
    *   `memcached_port`: Port for Memcached (default 11211).
*   **EC2 Client Specific:**
    *   `al2_inst_type`: EC2 instance type.
    *   `al2_ssh_key_name`: Name of an existing EC2 Key Pair.
    *   `ami_id`: AMI for the EC2 client (defaults to Amazon Linux 2).

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
    Provision the AWS resources. ElastiCache cluster provisioning can take a few minutes.
    ```bash
    terraform apply
    ```
    Confirm by typing `yes`. Terraform will output the EC2 client's public IP and the Memcached cluster's configuration endpoint and node addresses.

## Connecting to Memcached

After successful deployment and the ElastiCache cluster status is "available":

1.  **SSH into the EC2 Client Instance:**
    Use the Elastic IP (EIP) provided in the Terraform output and your SSH key.
    ```bash
    ssh -i /path/to/your/ssh-key.pem <user>@<EIP_EC2_Instance> 
    # Default user for Amazon Linux 2 is ec2-user
    ```

2.  **Connect to a Memcached Node using `telnet`:**
    The cloud-init script installs `telnet`. You can connect to any of the Memcached node endpoints or the cluster's configuration endpoint (for clusters with multiple nodes, the configuration endpoint helps with auto-discovery, but `telnet` connects to a single node at a time).
    *   Obtain a node endpoint from the Terraform output `memcached_cluster_nodes_address_port` or the ElastiCache console.
    *   The `memcached_cluster_config_endpoint_address_port` output provides the configuration endpoint.

    Example connecting to a specific node:
    ```bash
    telnet <memcached_node_address> <memcached_node_port>
    # Example: telnet my-memcached-node1.xxxxxx.cache.awsregion.amazonaws.com 11211
    ```
    If connecting to the configuration endpoint with `telnet`, it will resolve to one of the nodes.

3.  **Basic Memcached Commands via `telnet`:**
    Once connected via `telnet`, you can issue basic Memcached commands. Remember that Memcached commands are text-based and require specific formatting (including `\r\n` which is entered by pressing Enter).

    *   **Store a key-value pair:**
        ```
        set mykey 0 0 5
        hello
        ```
        (Press Enter after `5`, then type `hello`, then press Enter again)
        *   `set`: command
        *   `mykey`: the key
        *   `0`: flags (usually 0)
        *   `0`: expiry time in seconds (0 means no expiry)
        *   `5`: number of bytes in the value ("hello")
        *   `hello`: the value
        *   Expected response: `STORED`

    *   **Retrieve a key:**
        ```
        get mykey
        ```
        *   Expected response:
            ```
            VALUE mykey 0 5
            hello
            END
            ```

    *   **Get statistics:**
        ```
        stats
        ```
        *   This will output various statistics about the Memcached server.

    *   **Quit `telnet` session:**
        Type `quit` and press Enter, or use Ctrl+] and then type `quit`.

This testing procedure confirms basic connectivity and interaction with your ElastiCache for Memcached cluster from the EC2 client instance. For application use, you would use a Memcached client library in your programming language of choice.
