CREATE TABLE employee_log (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    employee_id INT,
    action_taken VARCHAR(50),
    log_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
DELIMITER $$
create trigger after_employee_insert
after insert on employee_salary
for each row
	begin
    insert into employee_log ( employee_id, action_taken)
    values ( new.employee_id, 'New employee salary record created');
    end $$
DELIMITER ;
INSERT INTO `parks_and_recreation`.`employee_salary`
(`employee_id`,
`first_name`,
`last_name`,
`occupation`,
`salary`,
`dept_id`)
VALUES
(13,
'Nacer',
'Benmerah',
'CEO',
1000000,
null);

select * from employee_salary;
select * from employee_log;

DELIMITER $$
create trigger before_salary_update
before update on employee_salary
for each row
	begin
		if new.salary <= 0 then
			set new.salary = old.salary;
		end if;
	end $$
DELIMITER ;

UPDATE employee_salary
SET salary = 0
WHERE employee_id = 2;

select * from employee_salary;

SET GLOBAL event_scheduler = ON;
DELIMITER $$
create event annual_parks_raise
on schedule every 1 year
	do 
		begin
        update employee_salary
        set salary = salary * 1.05
        where dept_id = 1;
        end $$
DELIMITER ;
    

