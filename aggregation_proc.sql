--PROCEDURE TO POPULATE Summary TABLE
/*CREATE OR REPLACE PROCEDURE generate_emp_channel_summary as
BEGIN
  DELETE from emp_channel_sales_summary;

  INSERT INTO emp_channel_sales_summary (
    employee_id,
    employee_name,
    department_name,
    channel_desc,
    total_sales,
    total_quantity
  )
  SELECT 
    e.employee_id,
    e.first_name || ' ' || e.last_name as employee_name,
    d.department_name,
    c.channel_desc,
    NVL(SUM(s.amount_sold), 0) as total_sales,
    NVL(SUM(s.quantity_sold), 0) as total_quantity
  from employee_channel_map m
  join employees e  ON m.employee_id = e.employee_id
  join departments d ON e.department_id = d.department_id
  join channels c ON m.channel_id = c.channel_id
  LEFT join sales s ON s.channel_id = m.channel_id
  GROUP BY e.employee_id, e.first_name, e.last_name, d.department_name, c.channel_desc;

  COMMIT;
END;*/

--UPDATED PROCEDURE

Create or replace procedure generate_emp_channel_summary as
BEGIN
  Delete from emp_channel_sales_summary;

  Insert into emp_channel_sales_summary (
    employee_id,
    employee_name,
    department_name,
    channel_desc,
    total_sales,
    total_quantity
  )
  SELECT 
    e.employee_id,
    e.first_name || ' ' || e.last_name as employee_name,
    d.department_name,
    c.channel_desc,
    ROUND(SUM(s.amount_sold), 2) as total_sales,
    SUM(s.quantity_sold) as total_quantity
  from employees e
  join departments d ON e.department_id = d.department_id
  join sales s ON s.employee_id = e.employee_id  
  join channels c ON s.channel_id = c.channel_id
  GROUP BY 
    e.employee_id,
    e.first_name,
    e.last_name,
    d.department_name,
    c.channel_desc;

  COMMIT;
END;


