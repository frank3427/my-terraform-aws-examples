# ------ Display the complete ssh command needed to connect to the instance
locals {
  username   = "ec2-user"
}

output Instructions {
  value = <<EOF



---- You can SSH directly to the Linux instance with Oracle Instance Client by typing the following ssh command
ssh -i ${var.private_sshkey_path} ${local.username}@${aws_eip.demo13_db_client.public_ip}

---- Once connected, you can connect to the MySQL database using the following command
export MYSQL_PASSWD=${random_string.demo13-db-passwd.result}
./mysql.sh

Notes: 
- you can list existing databases with the following command:
      show databases;
- you can select the new database for use with the following command:
      use ${var.aurora_mysql_db_name};
- you can list tables with the following command:
      show tables;
- you can create a new table with the following multi-line command:
      create table tblEmployee
      (
      Employee_id int auto_increment primary key,
      Employee_first_name varchar(500) NOT null,
      Employee_last_name varchar(500) NOT null,
      Employee_Address varchar(1000),
      Employee_emailID varchar(500),
      Employee_department_ID int default 9,
      Employee_Joining_date date 
      );
- you can insert rows with the following commands:
      insert into tblEmployee (employee_first_name, employee_last_name, employee_joining_date) 
      values ('Christophe','Pauliat','2022-10-03');

      insert into tblEmployee (employee_first_name, employee_last_name, employee_joining_date) 
      values ('Pierre','Martin','2022-12-30');
- you can list rows inside the table with the following command:
      select * from tblEmployee;


EOF
}

      # use ${var.mysql_db_name};

# ---- MySQL details
# Endpoint: ${aws_db_instance.demo13_mysql.endpoint}
# User    : ${aws_db_instance.demo13_mysql.username}
# Password: ${random_string.demo13-db-passwd.result}