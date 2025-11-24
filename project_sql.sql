create database project;

use project;

-- Table 1 :Job Department
create table jobdepartment(
job_id int primary key,
jobdept varchar(50),
name varchar(100),
description text,
salaryrange varchar(50)
);

select * from jobdepartment;


-- Table 2 : Salary ? Bonus
create table salarybonus(
salary_id int primary key,
job_id int,
amount decimal(10,2),
annual decimal(10,2),
bonus decimal(10,2),
constraint fk_salary_job foreign key (job_id) references jobdepartment(job_id)
on delete cascade on update cascade
);

select * from salarybonus;

-- Table 3 : Employee
create table employee(
emp_id int primary key,
firstname varchar(50),
lastname varchar(50),
gender varchar(10),
age int,
concat_add varchar(100),
emp_email varchar(100) unique,
emp_pass varchar(50),
job_id int,
constraint fk_employee_job foreign key (job_id) references jobdepartment(job_id)
on delete set null on update cascade
);


select * from employee;

-- Table 4 : Qualification

create table Qualification(
qualid int primary key,
emp_id int,
position varchar(50),
requirements varchar(225),
date_in date,
constraint fk_qualification_emp foreign key (emp_id) references employee(emp_id)
on delete cascade
on update cascade
);

select * from qualification;


-- Table 5: Leaves
create table leaves(
leave_id int primary key,
emp_id int,
date date,
reason text,
constraint fk_leave_emp foreign key(emp_id) references employee(emp_id)
on delete cascade
on update cascade
);

select * from leaves;

-- Table 6: Payroll

create table payroll(
payroll_id int primary key,
emp_id int,
job_id int,
salary_id int,
leave_id int,
date date,
report text,
total_amount decimal(10,2),
constraint fk_payroll_emp foreign key (emp_id) references employee(emp_id)
on delete cascade on update cascade,
constraint fk_payroll_job foreign key (job_id) references jobdepartment(job_id)
on delete cascade on update cascade,
constraint fk_payroll_salary foreign key (salary_id) references salarybonus(salary_id)
on delete cascade on update cascade,
constraint fk_payroll_leave foreign key(leave_id) references leaves(leave_id)
on delete set null on update cascade
);


select * from payroll;


-- 1. EMPLOYEE INSIGHTS
-- How many unique employees are currently in the system?

select count(distinct(emp_id)) distinct_employees from employee;

-- Which departments have the highest number of employees?

select jobdept,count(emp_id) from employee
inner join jobdepartment on
jobdepartment.job_id = employee.job_id
group by jobdept
order by count(emp_id) desc;

-- What is the average salary per department?

select jobdept,avg(annual) average_sal_dept from salarybonus
inner join jobdepartment on
salarybonus.job_id = jobdepartment.job_id
group by jobdept;

-- Who are the top 5 highest-paid employees?
select e.emp_id,e.firstname,e.lastname,sb.amount from employee e
join salarybonus sb
on e.job_id=sb.job_id
order by sb.amount desc
limit 5;
-- What is the total salary expenditure across the company?

select sum(amount + bonus) total_sal_company from salarybonus;

-- 2. JOB ROLE AND DEPARTMENT ANALYSIS
-- How many different job roles exist in each department?
select jobdept,count(name) different_roles from jobdepartment
group by jobdept;

-- What is the average salary range per department?

SELECT jobdept,CONCAT('$', AVG(CAST(REPLACE(SUBSTRING_INDEX(salaryrange, '-', 1), '$', '') AS UNSIGNED)),
' - $',AVG(CAST(REPLACE(TRIM(SUBSTRING_INDEX(salaryrange, '-', -1)), '$', '') AS UNSIGNED))) AS avg_salary_range
FROM jobdepartment
GROUP BY jobdept;

-- Which job roles offer the highest salary?
select name,max(amount) highest_salary from salarybonus
join jobdepartment on
jobdepartment.job_id = salarybonus.job_id
group by jobdepartment.name
order by max(amount) desc;


-- Which departments have the highest total salary allocation?
select jobdept,max(amount+bonus) highest_salary_allocation from salarybonus
join jobdepartment on
jobdepartment.job_id = salarybonus.job_id
group by jobdepartment.jobdept
order by max(amount) desc limit 5;

-- 3. QUALIFICATION AND SKILLS ANALYSIS
-- How many employees have at least one qualification listed?
select count(distinct(emp_id)) as employee_at_qualification from qualification;

-- Which positions require the most qualifications?

select position,count(*) from qualification
group by position
order by count(*);


-- Which employees have the highest number of qualifications?
select concat(firstname," ",lastname),count(q.emp_id) from qualification q
inner join employee e on
q.emp_id = e.emp_id
group by q.emp_id
order by count(q.emp_id);

-- 4. LEAVE AND ABSENCE PATTERNS
-- Which year had the most employees taking leaves?

select year(date),count(year(date)) count_employees from leaves
group by year(date);

-- What is the average number of leave days taken by its employees per department?

select j.jobdept,avg(leave_emp.total_leaves) average_leaves_department from jobdepartment j
join employee e on
e.job_id = j.job_id
left join(
select emp_id,count(*) total_leaves from leaves
group by emp_id) leave_emp
on e.emp_id = leave_emp.emp_id
group by j.jobdept;

-- Which employees have taken the most leaves?
select e.emp_id,concat(firstname," ",lastname) emp_name,count(*) total_leaves from employee e
left join leaves l on
e.emp_id = l.emp_id
group by e.emp_id,emp_name
order by total_leaves desc;


-- What is the total number of leave days taken company-wide?
select count(*) total_leaves from leaves;

-- How do leave days correlate with payroll amounts?

select e.emp_id,concat(e.firstname," ",e.lastname) emp_name,count(l.leave_id),sum(p.total_amount)  from employee e
left join leaves l on
e.emp_id = l.emp_id
left join payroll p on
e.emp_id = p.emp_id
group by e.emp_id,emp_name
order by count(l.emp_id) desc;

-- 5. PAYROLL AND COMPENSATION ANALYSIS
-- What is the total monthly payroll processed?
select date_format(date,"%Y-%M") month,sum(total_amount) total_amount from payroll
group by month
order by month desc;

-- What is the average bonus given per department?
select j.jobdept dept_name,avg(s.bonus) average_bonus_dept from jobdepartment j
join salarybonus s on
j.job_id = s.job_id
group by j.jobdept;

-- Which department receives the highest total bonuses?
select j.jobdept,sum(s.bonus) highest_total_bonus from jobdepartment j
join salarybonus s on
j.job_id = s.job_id
group by j.jobdept
order by highest_total_bonus desc limit 1;

-- What is the average value of total_amount after considering leave deductions?
select j.jobdept department ,avg(p.total_amount) avg_total_amount from jobdepartment j
inner join payroll p on
j.job_id = p.job_id
group by j.jobdept;
