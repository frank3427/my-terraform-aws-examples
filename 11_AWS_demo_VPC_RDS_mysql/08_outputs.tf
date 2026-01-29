# ------ Display the complete ssh command needed to connect to the instance
locals {
  username   = "ec2-user"
}

output Instructions {
  value = <<EOF

---- MySQL details
Endpoint: ${aws_db_instance.demo11_mysql.endpoint}
User    : ${aws_db_instance.demo11_mysql.username}
Password: ${random_string.demo11-db-passwd.result}

---- You can SSH directly to the Linux instance with Oracle Instance Client by typing the following ssh command
ssh -i ${var.private_sshkey_path} ${local.username}@${aws_eip.demo11_al2023.public_ip}

---- Once connected, you can connect to the MySQL database using the following command
export MYSQL_PWD="${random_string.demo11-db-passwd.result}"
./mysql.sh

Notes: 
- use password shown above to connect
- you can list databases with the following command:
      show databases;
- you can select the database we created with the following command:
      use ${var.mysql_db_name};
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

- you can run an infinite loop with select command with the following command:


DELIMITER //

DROP PROCEDURE IF EXISTS infinite_select//

CREATE PROCEDURE infinite_select()
BEGIN
    WHILE 1 DO
        SELECT CURRENT_TIME, tblEmployee.* FROM tblEmployee;
        DO SLEEP(1);
    END WHILE;
END //

DELIMITER ;

CALL infinite_select();

EOF
}