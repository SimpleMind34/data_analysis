select dept_id, avg(salary) average_salary
from employee_salary
group by dept_id
having average_salary> 50000;

select first_name, last_name, salary 
from employee_salary
order by salary desc
limit 1;

select employee_demographics.employee_id, employee_demographics.first_name, employee_demographics.last_name, age, occupation
from employee_demographics
join employee_salary
on employee_demographics.employee_id = employee_salary.employee_id;

select employee_demographics.employee_id, employee_salary.first_name, employee_salary.last_name, age, occupation
from employee_demographics
right join employee_salary
on employee_demographics.employee_id = employee_salary.employee_id;

select * from employee_demographics;

select emd1.first_name, emd1.last_name, emd1.birth_date, emd2.first_name, emd2.last_name 
from employee_demographics emd1
join employee_demographics emd2
on emd1.age = emd2.age
and emd1.employee_id != emd2.employee_id #very important trick
; -- don't know how to do it -- 

select first_name, last_name, 'old' Old
from employee_demographics
where age > 40
union all
select first_name, last_name, 'young' Young
from employee_demographics
where age <= 35;

select occupation, lower(left(occupation, 10)) short_title
from employee_salary;

select first_name, locate('e',first_name), replace(lower(first_name),'a','*')
from employee_demographics;

