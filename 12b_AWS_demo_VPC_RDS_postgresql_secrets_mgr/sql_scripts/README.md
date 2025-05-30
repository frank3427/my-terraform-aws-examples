# SQL Scripts for RDS PostgreSQL Database Interaction (with Secrets Manager Auth)

## Purpose of this Directory

This directory (`sql_scripts/`) contains a collection of SQL scripts designed for interacting with the AWS RDS for PostgreSQL database instance. This database is provisioned by the parent Terraform project (`12b_AWS_demo_VPC_RDS_postgresql_secrets_mgr/`), which notably configures the master user credentials to be managed by **AWS Secrets Manager**.

These SQL scripts are:
1.  Copied to the EC2 client instance (also provisioned by the parent project).
2.  Intended to be executed using the `psql` command-line client on that EC2 instance. The `psql` client on the EC2 instance is pre-configured by its cloud-init script to use the credentials fetched from AWS Secrets Manager, typically enabling password-less command-line execution.

They serve as examples and simple tools for verifying database connectivity and performing basic operations.

## Script Descriptions

The scripts are typically numbered to suggest an order of execution for a complete demonstration cycle:

*   **`01_create_table.sql`**:
    *   **Purpose:** Contains SQL DDL (Data Definition Language) statements to create a sample table in the connected PostgreSQL database.
    *   **Common Content:** `CREATE TABLE ...` statements defining columns and data types for a test table.

*   **`02_select_from_table.sql`**:
    *   **Purpose:** Contains a `SELECT` query to retrieve and display data from the sample table created by `01_create_table.sql`.
    *   **Common Content:** `SELECT * FROM <sample_table_name>;` or similar queries.

*   **`03_insert_into_table.sql`**:
    *   **Purpose:** Contains SQL DML (Data Manipulation Language) statements to insert sample data (rows) into the table created by `01_create_table.sql`.
    *   **Common Content:** `INSERT INTO <sample_table_name> (column1, column2) VALUES ('value1', 'value2');` statements.

*   **`04_drop_table.sql`**:
    *   **Purpose:** Contains SQL DDL statements to remove or drop the sample table, useful for cleaning up test objects.
    *   **Common Content:** `DROP TABLE IF EXISTS <sample_table_name>;` statement.

## Deployment to EC2 Client Instance by Terraform

These SQL scripts are copied to the EC2 client instance by the Terraform configuration in the parent directory. This is typically handled using a `null_resource` in a file like `07_instance_linux_al2.tf` (or a similarly named file responsible for the EC2 client instance).

The deployment process within the `null_resource` usually involves:

1.  **Connection Establishment:** Terraform establishes an SSH connection to the newly created EC2 instance.
2.  **Copying Scripts Directory (`provisioner "file"`):**
    *   The `provisioner "file"` block, with `type = "dir"`, copies the entire local `sql_scripts/` directory to a specified location on the EC2 instance (e.g., `/home/ec2-user/sql_scripts/`).
    ```terraform
    // Example snippet from the null_resource in the parent project
    resource "null_resource" "ec2_provisioners_sql_scripts" {
      // ... depends_on and connection details ...

      provisioner "file" {
        source      = "${path.module}/sql_scripts/" // Source is this directory
        destination = "/home/ec2-user/sql_scripts/" // Destination on the EC2 instance
        // ... connection details ...
      }
    }
    ```

## Execution on EC2 Client Instance

Once the EC2 client instance is provisioned, its cloud-init script has configured `psql` with credentials from Secrets Manager (likely via a `.pgpass` file), and these SQL scripts have been copied:

1.  **SSH into the EC2 Client Instance:**
    Use the Elastic IP (EIP) of the instance and your SSH key.
    ```bash
    ssh -i /path/to/your/ssh-key.pem ec2-user@<EIP_EC2_Instance>
    # Default user for Amazon Linux 2 is ec2-user
    ```

2.  **Navigate to the Scripts Directory:**
    Change to the directory where the scripts were copied:
    ```bash
    cd /home/ec2-user/sql_scripts/
    ```

3.  **Execute Scripts using `psql`:**
    You can run each SQL script using the `psql` command-line tool.
    The general command format is:
    ```bash
    psql -h <rds_endpoint_address> -U <pg_user> -d <pg_db_name> -f <script_name>.sql
    ```
    *   Replace `<rds_endpoint_address>`, `<pg_user>`, and `<pg_db_name>` with the actual connection details for your RDS PostgreSQL instance (these are typically outputted by Terraform or available as variables).
    *   **Password Handling:** Because the EC2 client's cloud-init script (from the sibling `cloud_init/` directory) is designed to set up a `.pgpass` file using the master credentials retrieved by Terraform from AWS Secrets Manager, you **should generally not be prompted for a password** when running these `psql` commands as the `ec2-user`.

    **Example Execution Order:**
    *   Create the table:
        ```bash
        psql -h your-rds-pg-endpoint.xxxxxxxx.awsregion.rds.amazonaws.com -U adm -d demodb -f 01_create_table.sql
        ```
    *   Insert data:
        ```bash
        psql -h your-rds-pg-endpoint.xxxxxxxx.awsregion.rds.amazonaws.com -U adm -d demodb -f 03_insert_into_table.sql
        ```
    *   Select data:
        ```bash
        psql -h your-rds-pg-endpoint.xxxxxxxx.awsregion.rds.amazonaws.com -U adm -d demodb -f 02_select_from_table.sql
        ```
    *   Drop the table (for cleanup):
        ```bash
        psql -h your-rds-pg-endpoint.xxxxxxxx.awsregion.rds.amazonaws.com -U adm -d demodb -f 04_drop_table.sql
        ```

These scripts, in conjunction with the pre-configured EC2 client, provide a convenient way to perform initial database setup, load sample data, and verify basic operations against the RDS PostgreSQL instance whose credentials are securely managed by AWS Secrets Manager.
