# ------ Display the complete ssh command needed to connect to the instance
locals {
  username   = "ec2-user"
}

output Instructions {
  value = <<EOF
  

---- You can SSH directly to the Linux instance with PostgreSQL client by typing the following ssh command
ssh -i ${var.private_sshkey_path} ${local.username}@${aws_eip.demo13d_db_client.public_ip}

---- Once connected, you can connect to the PostgreSQL database using the following command
./psql.sh

Notes: 
- no password needed as this script uses .pgpass file
- you can create a new table with the following multi-line command:
      CREATE TABLE tblEmployee
      (
            Employee_id int primary key,
            Employee_first_name varchar(500) NOT null,
            Employee_last_name varchar(500) NOT null,
            Employee_Address varchar(1000),
            Employee_emailID varchar(500),
            Employee_department_ID int default 9,
            Employee_Joining_date date 
      );

  OR
      ./psql.sh 01_create_table.sql

- you can insert rows with the following commands:
      INSERT INTO tblEmployee (employee_id, employee_first_name, employee_last_name, employee_joining_date)
      VALUES (1, 'Christophe','Pauliat','2022-10-03');

      INSERT INTO tblEmployee (employee_id, employee_first_name, employee_last_name, employee_joining_date)
      VALUES (2, 'Jean','Bon','2021-10-03'); 

      INSERT INTO tblEmployee (employee_id, employee_first_name, employee_last_name, employee_joining_date)
      VALUES (3, 'Pierre','Martin','2020-12-30');
  OR
      ./psql.sh 03_insert_into_table.sql

- you can list rows inside the table with the following command:
      SELECT * FROM tblEmployee;
  OR
      ./psql.sh 02_select_from_table.sql

- you can delete the table with the following command:
      DROP TABLE tblEmployee;
  OR
      ./psql.sh 04_drop_table.sql


EOF
}
