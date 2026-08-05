# ------ Display the complete ssh command needed to connect to the instance
locals {
  username = "ec2-user"
}

output "Instructions" {
  value = <<EOF

---- Oracle details
Endpoint: ${aws_db_instance.demo10_oracle.endpoint}
User    : ${aws_db_instance.demo10_oracle.username}
Password: ${random_string.demo10-db-passwd.result}
SID     : ${var.oracle_sid}

---- You can SSH directly to the Linux instance with Oracle Instance Client by typing the following ssh command
ssh -i ${var.private_sshkey_path} ${local.username}@${aws_eip.demo10_al2023.public_ip}

---- Once connected, you can connect to the Oracle database using sqlplus with following command
./sqlplus.sh
Password is ${random_string.demo10-db-passwd.result}

---- Once connected to sqlplus, you can run the following SQL commands:

- Create a table:
      CREATE TABLE tblEmployee (
        Employee_id       NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
        Employee_first_name VARCHAR2(500) NOT NULL,
        Employee_last_name  VARCHAR2(500) NOT NULL,
        Employee_Address    VARCHAR2(1000),
        Employee_emailID    VARCHAR2(500),
        Employee_department_ID NUMBER DEFAULT 9,
        Employee_Joining_date DATE
      );

- Insert rows:
      INSERT INTO tblEmployee (Employee_first_name, Employee_last_name, Employee_Joining_date)
      VALUES ('Christophe', 'Pauliat', TO_DATE('2022-10-03','YYYY-MM-DD'));

      INSERT INTO tblEmployee (Employee_first_name, Employee_last_name, Employee_Joining_date)
      VALUES ('Pierre', 'Martin', TO_DATE('2022-12-30','YYYY-MM-DD'));

      COMMIT;

- Format output before listing rows:
      COLUMN Employee_first_name FORMAT A20;
      COLUMN Employee_last_name  FORMAT A20;
      COLUMN Employee_Address    FORMAT A30;
      COLUMN Employee_emailID    FORMAT A30;
      SET LINESIZE 150;

- List rows:
      SELECT * FROM tblEmployee;

- Delete all rows:
      DELETE FROM tblEmployee;
      COMMIT;

- Drop the table:
      DROP TABLE tblEmployee PURGE;

EOF
}