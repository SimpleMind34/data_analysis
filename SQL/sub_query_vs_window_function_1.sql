select first_name, salary,
(select avg(salary) from employee_salary)
from employee_salary;

select first_name, salary, avg(salary) over() avg_salary
from employee_salary;
