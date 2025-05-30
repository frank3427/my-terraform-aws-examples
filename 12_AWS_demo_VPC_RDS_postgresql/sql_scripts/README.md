# SQL Scripts for RDS PostgreSQL Database Interaction

## Purpose of this Directory

This directory (`sql_scripts/`) contains a collection of SQL scripts designed for interacting with the AWS RDS for PostgreSQL database instance provisioned by the parent Terraform project (`12_AWS_demo_VPC_RDS_postgresql/`).

These scripts are intended to be:
1.  Copied to the EC2 client instance (which is also provisioned by the parent project).
2.  Executed using the `psql` command-line client on the EC2 instance to perform basic database operations, such as creating tables, inserting data, querying data, and cleaning up.

They serve as examples and simple tools for verifying database connectivity and basic functionality from the client instance.

## Script Descriptions

The scripts are typically numbered to suggest an order of execution for a complete demonstration cycle:

*   **`01_create_table.sql`**:
    *   **Purpose:** This script likely contains SQL DDL (Data Definition Language) statements to create a sample table within the connected PostgreSQL database (e.g., the database specified by `var.pg_db_name` in the parent project).
    *   **Common Content:** `CREATE TABLE ...` statements defining columns and data types for a test table.

*   **`02_select_from_table.sql`**:
    *   **Purpose:** This script likely contains SQL DML (Data Manipulation Language) statements, specifically a `SELECT` query, to retrieve and display data from the sample table created by `01_create_table.sql`.
    *   **Common Content:** `SELECT * FROM <sample_table_name>;` or more specific select queries.

*   **`03_insert_into_table.sql`**:
    *   **Purpose:** This script likely contains SQL DML statements to insert sample data (rows) into the table created by `01_create_table.sql`.
    *   **Common Content:** `INSERT INTO <sample_table_name> (column1, column2) VALUES ('value1', 'value2');` statements.

*   **`04_drop_table.sql`**:
    *   **Purpose:** This script likely contains SQL DDL statements to remove or drop the sample table created by `01_create_table.sql` from the database. This is useful for cleaning up test objects.
    *   **Common Content:** `DROP TABLE IF EXISTS <sample_table_name>;` statement.

## Deployment to EC2 Client Instance by Terraform

These SQL scripts are copied to the EC2 client instance by the Terraform configuration in the parent directory. This is typically handled using a `null_resource` in a file like `07_instance_linux_al2.tf` (or a similarly named file responsible for the EC2 client instance).

The deployment process within the `null_resource` usually involves:

1.  **Connection Establishment:** Terraform establishes an SSH connection to the newly created EC2 instance using the specified private key.
2.  **Copying Scripts Directory (`provisioner "file"`):**
    *   The `provisioner "file"` block, with `type = "dir"`, is used to copy the entire local `sql_scripts/` directory (containing all these SQL files) to a specified location on the EC2 instance (e.g., `/home/ec2-user/sql_scripts/`).
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

Once the EC2 client instance is provisioned and these scripts have been successfully copied:

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
    You can run each SQL script using the `psql` command-line tool. The EC2 instance should have `psql` installed and configured by its cloud-init script (as detailed in the `cloud_init/README.md`).
    The general command format is:
    ```bash
    psql -h <rds_endpoint_address> -U <pg_user> -d <pg_db_name> -f <script_name>.sql
    ```
    *   Replace `<rds_endpoint_address>`, `<pg_user>`, and `<pg_db_name>` with the actual connection details for your RDS PostgreSQL instance (these are typically outputted by Terraform or available as variables).
    *   The cloud-init script for the EC2 client might have configured a `.pgpass` file. If so, you may not be prompted for a password when running these `psql` commands. Otherwise, `psql` will prompt for the password for `<pg_user>`.

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

These scripts provide a straightforward way to perform initial database setup, load sample data, and verify basic operations against the RDS PostgreSQL instance from the configured client.
