# Terraform AWS: Managed Streaming for Kafka (MSK) Cluster with SASL/IAM Authentication

This Terraform project provisions an **AWS Managed Streaming for Kafka (MSK) cluster** in provisioned mode. The cluster is configured to use **SASL/IAM for client authentication**, providing a secure way to control access to Kafka topics. A Linux EC2 instance (Amazon Linux 2023) is also provisioned and pre-configured as a Kafka client, complete with necessary tools and helper scripts to interact with the MSK cluster using IAM authentication.

## Purpose

The primary goals of this project are to:
1.  Demonstrate the provisioning of an MSK cluster in a multi-AZ setup.
2.  Illustrate how to configure SASL/IAM authentication for secure client connections to MSK brokers.
3.  Provide a ready-to-use EC2 client instance with Kafka tools and scripts, pre-configured for IAM-based authentication with the MSK cluster.
4.  Showcase the necessary IAM roles and policies for both MSK broker permissions (implicitly handled by MSK service) and client IAM authentication.

## Key Components

1.  **VPC Infrastructure:**
    *   A VPC with **three public subnets**, each in a different Availability Zone (`var.az_list`). These subnets are used for deploying the MSK broker nodes and the EC2 Kafka client instance.
    *   An Internet Gateway (IGW) is attached to the VPC for internet access (e.g., for the EC2 client to download software and for users to SSH).
2.  **AWS MSK Cluster (`aws_msk_cluster.demo35_provisioned`):**
    *   **Provisioned Mode:** The cluster is created with a fixed number of broker nodes and resources.
    *   **Kafka Version:** Configurable via `var.msk_kafka_version`.
    *   **Broker Nodes:** Three broker nodes are provisioned, one in each of the specified public subnets, ensuring multi-AZ distribution.
        *   **Instance Type:** Configurable via `var.msk_node_type`.
        *   **EBS Volume Size:** Configurable per broker via `var.msk_ebs_size_gb`.
    *   **Client Authentication (`client_authentication` block):**
        *   **SASL/IAM Enabled:** `sasl { iam = true }`. This enforces that clients must use SASL (Simple Authentication and Security Layer) with IAM credentials to authenticate.
        *   **TLS Encryption:** While SASL/IAM is for authentication, client-broker communication is also typically encrypted using TLS (implicitly enabled when SASL is used, or can be explicitly configured).
    *   **Public Access:** `public_access { type = "DISABLED" }` ensures brokers are not directly accessible from the public internet.
    *   **Security Group:** Associated with a dedicated MSK security group (`aws_security_group.demo35_msk`).
    *   **Enhanced Monitoring:** Enabled for detailed metrics (e.g., `PER_TOPIC_PER_PARTITION`).
3.  **MSK Security Group (`aws_security_group.demo35_msk` - named `demo35-msk-sg`):**
    *   Allows all inbound traffic from within the VPC (using the VPC's CIDR block as a source or from specific security groups like the EC2 client's SG). This permits Kafka clients within the VPC to communicate with the MSK brokers on all necessary Kafka ports.
    *   Allows all outbound traffic.
4.  **IAM for MSK Client Authentication:**
    *   **IAM Policy (`aws_iam_policy.demo35_msk_client_policy`):**
        *   Grants necessary Kafka client actions (e.g., `kafka-cluster:Connect`, `kafka-cluster:DescribeCluster`, `kafka:DescribeTopic`, `kafka:CreateTopic`, `kafka:WriteData`, `kafka:ReadData`) on the specific MSK cluster resource.
    *   **IAM Role (`aws_iam_role.demo35_msk_ec2_role`):**
        *   Created for EC2 instances, allowing them to be assumed by EC2.
        *   The `aws_iam_policy.demo35_msk_client_policy` is attached to this role.
    *   **IAM Instance Profile (`aws_iam_instance_profile.demo35_msk_ec2_instance_profile`):**
        *   Wraps the IAM role, making it attachable to EC2 instances.
5.  **Linux EC2 Kafka Client Instance:**
    *   An Amazon Linux 2023 instance launched in one of the public subnets.
    *   An **Elastic IP (EIP)** is associated for a static public IP address.
    *   **IAM Instance Profile Attached:** The `aws_iam_instance_profile.demo35_msk_ec2_instance_profile` is attached, granting the EC2 instance permissions to authenticate with MSK via IAM.
    *   **Cloud-Init Script (`cloud_init_TEMPLATE.sh` via `var.al2023_cloud_init_script`):**
        *   Installs Java (a Kafka dependency) and Apache Kafka client tools.
        *   Downloads the AWS MSK IAM Auth JAR (`aws-msk-iam-auth-*.jar`), which is required for IAM-based SASL authentication.
        *   Creates a `client.properties` file. This file is configured for:
            *   `security.protocol=SASL_SSL`
            *   `sasl.mechanism=AWS_MSK_IAM`
            *   `sasl.jaas.config` pointing to the AWS MSK IAM SASL module.
            *   `sasl.client.callback.handler.class` for the IAM callback handler.
        *   Creates helper shell scripts on the instance (`/home/ec2-user/kafka_scripts/`):
            *   `01_create_kafka_topic.sh`: Creates a Kafka topic using the IAM bootstrap brokers and client properties.
            *   `02_kafka_producer.sh`: Starts a console producer to send messages to a topic using IAM authentication.
            *   `03_kafka_consumer.sh`: Starts a console consumer to read messages from a topic using IAM authentication.
            These scripts are pre-configured with the MSK cluster's IAM bootstrap brokers string.
    *   **Security Group:** Uses the VPC's default security group, which is typically modified by Terraform to allow inbound SSH from `authorized_ips`.

## Authentication (SASL/IAM)

This project uses SASL/IAM for authenticating clients to the MSK cluster. Here's how it works:
1.  **IAM Permissions:** The Kafka client (in this case, the EC2 instance) needs IAM permissions to perform Kafka actions (like connect, describe, read, write) on the MSK cluster. This is achieved by attaching an IAM role with the appropriate policy to the EC2 instance.
2.  **AWS MSK IAM Auth JAR:** Clients use a special JAR (`aws-msk-iam-auth`) that handles the IAM authentication process. This JAR, along with specific JAAS configuration and client properties, enables the Kafka client libraries to use AWS credentials (obtained from the EC2 instance profile) to sign requests to MSK.
3.  **MSK Broker Validation:** The MSK brokers are configured to expect IAM-authenticated SASL connections. They validate the IAM signature of the client requests against AWS IAM.
4.  **Secure Connection:** Communication is typically over SASL/SSL, ensuring both authentication and encryption in transit.

## Highlights

*   **Provisioned MSK Cluster:** Demonstrates the setup of a managed Kafka cluster with defined broker resources.
*   **SASL/IAM Authentication:** Provides a robust and AWS-native way to secure access to your Kafka cluster, integrating with existing IAM identities and policies.
*   **Pre-configured EC2 Client:** The EC2 instance is ready-to-use with Kafka tools and helper scripts tailored for IAM authentication, simplifying interaction with the MSK cluster.
*   **Multi-AZ Setup:** Both MSK brokers and the subnets they reside in are distributed across multiple Availability Zones for resilience.

## Key Configuration Variables

*   **General AWS & VPC:**
    *   `aws_region`: AWS region (e.g., "us-east-1").
    *   `az_list`: List of three Availability Zones for subnets and MSK brokers.
    *   `cidr_vpc`, `cidrs_subnet_public`: CIDR blocks.
    *   `authorized_ips`: IPs/CIDRs for SSH access to the EC2 client.
*   **MSK Cluster Specific:**
    *   `msk_cluster_name`: Name for the MSK cluster.
    *   `msk_kafka_version`: Kafka version (e.g., "3.5.1").
    *   `msk_node_type`: EC2 instance type for MSK brokers (e.g., "kafka.m5.large").
    *   `msk_ebs_size_gb`: EBS volume size for each broker.
*   **EC2 Client Specific:**
    *   `al2023_inst_type`: EC2 instance type (e.g., "t3.micro").
    *   `al2023_ssh_key_name`: Name of an existing EC2 Key Pair.
    *   `al2023_cloud_init_script`: Path to the cloud-init template file.

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
    Provision the AWS resources. This may take some time as MSK cluster creation is not immediate.
    ```bash
    terraform apply
    ```
    Confirm by typing `yes`. Terraform will output the EIP of the EC2 client and MSK broker endpoints.

## Interacting with MSK

After successful deployment and the EC2 instance is ready (cloud-init script completed):

1.  **SSH into the EC2 Kafka Client Instance:**
    Use the Elastic IP (EIP) provided in the Terraform output and your SSH key.
    ```bash
    ssh -i /path/to/your/ssh-key.pem ec2-user@<EIP_EC2_Instance>
    ```

2.  **Navigate to Helper Scripts:**
    The cloud-init script places the helper scripts in `/home/ec2-user/kafka_scripts/`.
    ```bash
    cd /home/ec2-user/kafka_scripts/
    ```
    These scripts are already configured with the IAM bootstrap brokers string and use the `client.properties` file for IAM authentication.

3.  **Create a Kafka Topic:**
    Execute the topic creation script. You might need to make it executable first (`chmod +x *.sh`).
    ```bash
    ./01_create_kafka_topic.sh your_topic_name
    # Example: ./01_create_kafka_topic.sh demo-topic
    ```
    Verify the topic creation by listing topics:
    ```bash
    # Using Kafka's kafka-topics.sh script (path might vary based on installation)
    /opt/kafka/bin/kafka-topics.sh --bootstrap-server $(cat /tmp/iam_bootstrap_brokers.txt) --command-config client.properties --list
    ```

4.  **Produce Messages:**
    Run the producer script. It will start an interactive console where you can type messages.
    ```bash
    ./02_kafka_producer.sh your_topic_name
    # Example: ./02_kafka_producer.sh demo-topic
    > Hello from EC2 client using IAM!
    > This is another message.
    (Ctrl+C to exit)
    ```

5.  **Consume Messages:**
    Open another terminal session to the EC2 client or run in the background. Run the consumer script.
    ```bash
    ./03_kafka_consumer.sh your_topic_name
    # Example: ./03_kafka_consumer.sh demo-topic
    # You should see the messages you produced:
    # Hello from EC2 client using IAM!
    # This is another message.
    (Ctrl+C to exit)
    ```

This demonstrates that the EC2 client can successfully authenticate with the MSK cluster using SASL/IAM and perform basic Kafka operations. Remember that MSK cluster creation and updates can take a significant amount of time.
