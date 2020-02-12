require(DBI)
require(openxlsx)

#---- Read Data From Excel File
employees = read.xlsx("./employee_table.xlsx")
head(employees)


#---- SQLite DB connection
con = dbConnect(RSQLite::SQLite(), "employee_db.sqlite")

#---- Create table using SQL

create_employee_table_sql = "
CREATE TABLE employees (
  employee_id INT PRIMARY KEY,
  name TEXT,
  role TEXT,
  manager_id INT,
  dept_id INT,
  salary REAL
);
"
dbSendQuery(con, create_employee_table_sql)


#---- Write the records into the table with R
dbWriteTable(con, "employees", employees, append=T)

#---- SELECT All data from Table
select_all_q = "
SELECT * 
FROM employees;
"
dbGetQuery(con, select_all_q)

#---- SELECT ALL employees with high salary
high_paid_q = "
SELECT name, salary
FROM employees
WHERE salary >= 100000;"
dbGetQuery(con, high_paid_q)


#---- SELECT the names of all managers (SubQueries)
manager_q = "
SELECT DISTINCT name
FROM employees
WHERE employee_id IN (
    SELECT manager_id 
    FROM employees
  );"
dbGetQuery(con, manager_q)

#---- Select the salary budget per department
dept_budget_q = "
SELECT dept_id, SUM(salary) as dept_budget
FROM employees
GROUP BY dept_id;"
dbGetQuery(con, dept_budget_q)


#---- Get the highest paid employee within each department
max_sal_q = "
SELECT E.name, E.salary
FROM employees as E, (SELECT dept_id, max(salary) as highest_salary 
                      FROM employees 
                      GROUP BY dept_id) as max_sal_table
WHERE 
  E.dept_id = max_sal_table.dept_id AND 
  E.salary=max_sal_table.highest_salary;
"

dbGetQuery(con, max_sal_q)
#---- Finally close the connection
dbDisconnect(con)
unlink("employee_db.sqlite")
