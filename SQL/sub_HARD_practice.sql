DROP PROCEDURE IF EXISTS GenerateDeptPerformanceReport;
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