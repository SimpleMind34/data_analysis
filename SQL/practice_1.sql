select distinct occupation from employee_salary
order by occupation;

select gender, avg(age) from employee_demographics
group by gender;


select dept_id, count(employee_id), max(salary)   from  employee_salary
where dept_id is not null
group by dept_id; 

select * from employee_demographics;

select first_name, last_name, age from employee_demographics
where first_name like 'a%' or first_name like 'm%'
order by age desc;

select gender, min(age), max(age) from employee_demographics
group by gender
order by gender desc, max(age) desc;

select * from employee_salary;

select occupation, avg(salary) from employee_salary
where occupation like '%director%'
group by occupation
order by avg(salary) desc;