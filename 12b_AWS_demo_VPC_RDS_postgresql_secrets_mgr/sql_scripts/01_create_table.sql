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
