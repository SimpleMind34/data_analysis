select gender, avg(salary)
from employee_demographics
join employee_salary
on employee_demographics.employee_id = employee_salary.employee_id
group by gender;

select gender, employee_demographics.first_name, avg(salary) over(partition by gender)
from employee_demographics
join employee_salary
on employee_demographics.employee_id = employee_salary.employee_id;