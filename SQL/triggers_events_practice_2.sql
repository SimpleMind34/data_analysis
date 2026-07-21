ALTER TABLE employee_demographics
ADD email_address varchar(100);
DELIMITER $$
create trigger auto_generate_email
after insert on employee_demographics
for each row
begin
update employee_demographics
set new.email_address = concat(lower(first_name),'.',lower(last_name),'@pawnee.gov');
end $$
DELIMITER ;

drop trigger auto_generate_email;
drop trigger assign_default_email;

DELIMITER $$
create trigger assign_default_email
before insert on employee_demographics
for each row
begin 
	
SET NEW.email_address = CONCAT(LOWER(NEW.first_name), '.', LOWER(NEW.last_name), '@pawnee.gov');
end $$
DELIMITER ;

insert into employee_demographics (employee_id, first_name, last_name, age, birth_date) values
(16,'John', 'Doe',23, '2003-12-14');
select * from employee_demographics;

select * from employee_salary;
drop trigger prevent_executive_deletion;

DELIMITER $$
create trigger prevent_executive_deletion
before delete on employee_salary
for each row
begin
if old.salary > 100000 then
SIGNAL SQLSTATE '45000' 
SET MESSAGE_TEXT = 'wtf are you doing';
end if;
end $$
DELIMITER ;

describe employee_salary;

delete from employee_salary
where employee_id = 13;

create table active_sessions(
last_activity timestamp);

DELIMITER $$
create event purge_old_sessions
on schedule every 1 day 
do 
begin 
delete from active_sessions
where last_activity < NOW() - INTERVAL 30 DAY;
end $$
DELIMITER ;

DELIMITER $$
create event end_of_year_flag_update
ON SCHEDULE AT '2026-12-31 23:59:59'do 
begin 
update system_status
set  fiscal_year_locked = 1;
end $$
DELIMITER ;