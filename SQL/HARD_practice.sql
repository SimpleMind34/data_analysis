with DeptAvgSalary as (
select dept_id, avg(salary) average_departement_salary
from employee_salary
group by dept_id
having dept_id is not null
) select first_name, last_name, salary, average_departement_salary 
from employee_salary
join DeptAvgSalary
	on employee_salary.dept_id = DeptAvgSalary.dept_id
where salary > average_departement_salary;

drop table if exists temp_young_employees;
create temporary table temp_young_employees(
id int, 
name varchar(100), 
age int
);
insert into temp_young_employees(id, name, age) select employee_id, concat(first_name, ' ', last_name), age
from employee_demographics
where age < 38;
select * from temp_young_employees;

DELIMITER $$
create procedure GetEmployeesBySalary(input_salary int)
begin
	select first_name, last_name, occupation, salary
    from employee_salary
    where salary >= input_salary;
end $$
DELIMITER ;
call GetEmployeesBySalary(60000);

DELIMITER //
create procedure GenerateDeptPerformanceReport()
	begin
		create temporary table temp_dept_summary(
		dept_id int,
		total_employees int,
		total_payroll int
		);	
		insert into temp_dept_summary(dept_id, total_employees, total_payroll) 
        select dept_id, count(employee_id), sum(salary)
        from employee_salary
        group by dept_id
        having dept_id is not null;
        with HighEarnerCount as (
        select dept_id, count(employee_id) high_earners_count
        from employee_salary
        where salary > 60000
        group by dept_id)
        select department_name, total_employees, total_payroll, high_earners_count 
        from parks_departments
        join temp_dept_summary
        on parks_departments.department_id = temp_dept_summary.dept_id
        join HighEarnerCount
        on HighEarnerCount.dept_id = temp_dept_summary.dept_id;
        drop temporary table temp_dept_summary;
    end //
    
DELIMITER ;

call GenerateDeptPerformanceReport();
drop temporary table temp_dept_summary;