select concat(upper(demo.first_name),' ', upper(demo.last_name)) full_name, occupation, salary
from employee_demographics demo
join employee_salary sal
on demo.employee_id = sal.employee_id
where demo.age > 35 and sal.salary > 55000
and (sal.occupation like '%Manager%' OR sal.occupation LIKE '%Director%')
order by sal.salary desc
limit 2;