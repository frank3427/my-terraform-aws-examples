# ------ Display the complete ssh command needed to connect to the instance
locals {
  username   = "ec2-user"
}

output Instructions {
  value = <<EOF

---- PostgreSQL details
Endpoint: ${aws_db_instance.demo12_postgresql.endpoint}
User    : ${aws_db_instance.demo12_postgresql.username}
Password: ${random_string.demo12-db-passwd.result}

---- You can SSH directly to the Linux instance with PostgreSQL Client by typing the following ssh command:
ssh -i ${var.private_sshkey_path} ${local.username}@${aws_eip.demo12_al2.public_ip}

---- Once connected, you can connect to the PostgreSQL database using the following command:
./psql.sh

Notes: 
- use password shown above to connect
- you can create a new table with the following multi-line command:
      create table tblEmployee
      (
      Employee_id int primary key,
      Employee_first_name varchar(500) NOT null,
      Employee_last_name varchar(500) NOT null,
      Employee_Address varchar(1000),
      Employee_emailID varchar(500),
      Employee_department_ID int default 9,
      Employee_Joining_date date 
      );
- you can insert rows with the following commands:
      insert into tblEmployee (employee_id, employee_first_name, employee_last_name, employee_joining_date) 
      values (100, 'Christophe','Pauliat','2022-10-03');

      insert into tblEmployee (employee_id, employee_first_name, employee_last_name, employee_joining_date) 
      values (101, 'Pierre','Martin','2022-12-30');

- you can list rows inside the table with the following command:
      select * from tblEmployee;


EOF
}