select first_name, last_name, salary,
case
when salary > 70000 then 'Executive'
when salary between 50000 and 70000 then 'Mid_Level'
when salary < 50000 then 'Entry_Level'
end as salary_tier
from employee_salary;

select first_name, last_name, salary
from employee_salary
where salary > (select avg(salary) from employee_salary);

select first_name, last_name, salary, row_number() over(order by salary desc) row_num,
rank() over(order by salary desc) rank_num,
dense_rank() over(order by salary desc) dense_rank_num
from employee_salary;

select * , dense_rank() over(partition by dept_id order by salary desc) rank_num
from employee_salary
where dept_id is not null;

select concat(dem.first_name, ' ', dem.last_name) employee_name,
	sal.dept_id, salary, 
    case
		when age >= 40 then 'Senior'
        when age < 40 then 'Junior'
	end age_group, 
    dense_rank() over(partition by sal.dept_id order by salary desc) salary_ank
    from employee_demographics dem
    join  employee_salary sal
    on dem.employee_id = sal.employee_id
    where sal.dept_id is not null 
    and salary > (select avg(salary) from employee_salary);
