--Creating summary table
    CREATE TABLE emp_channel_sales_summary (
      employee_id     int,
      employee_name   VARCHAR(50),
      department_name VARCHAR(50),
      channel_desc    VARCHAR(50),
      total_sales     NUMBER,
      total_quantity  INT
    );

--Calling Procedure

    BEGIN
      generate_emp_channel_summary;
    END;
    
    SELECT * FROM emp_channel_sales_summary order by total_sales desc;
    
    SELECT * FROM SALES;

--There was no data in sales table for channe_id 5, so generating dummy data for channel 5
    BEGIN
      FOR i IN 1..10 LOOP
        INSERT INTO sales (
          prod_id,
          cust_id,
          time_id,
          channel_id,
          promo_id,
          quantity_sold,
          amount_sold
        ) values (
          15,  -- valid product
          1260, -- valid customer
          '98-02-25',  -- valid time
          5,    -- CATALOG channel_id
          999,
          TRUNC(DBMS_RANDOM.VALUE(1, 10)),         -- quantity_sold
          ROUND(DBMS_RANDOM.VALUE(100, 500), 2)    -- amount_sold
        );
      End loop;
      Commit;
    END;

--RERUN PROCEDURE
    BEGIN
      generate_emp_channel_summary;
    END;


    UPDATE emp_channel_sales_summary
    Set channel_desc = 'Unknown'
    WHERE channel_desc Is Null;

--Adding Surrogate PK
    ALTER TABLE emp_channel_sales_summary
    ADD summary_id INT;
    CREATE Sequence emp_summary_seq START WITH 1 Increment by 1;
    UPDATE emp_channel_sales_summary
    SET summary_id = emp_summary_seq.NEXTVAL;
    
    ALTER TABLE emp_channel_sales_summary
    Modify summary_id Not null;
    
    ALTER TABLE emp_channel_sales_summary
    ADD CONSTRAINT pk_emp_summary_id PRIMARY KEY (summary_id);

--exporting results as csv for dashboard
    SELECT * FROM emp_channel_sales_summary ORDER BY SUMMARY_id;
    
--ARRANGING DATA IN NEW TABLE to copy to csv
    CREATE TABLE emp_channel_sales_summary_new (
      summary_id      int PRIMARY KEY,
      employee_id     int,
      employee_name   VARCHAR(50),
      department_name VARCHAR(50),
      channel_desc    VARCHAR(50),
      total_sales     INT,
      total_quantity  INT
    );
    
    INSERT INTO emp_channel_sales_summary_new (
      summary_id,
      employee_id,
      employee_name,
      department_name,
      channel_desc,
      total_sales,
      total_quantity
    )
    SELECT
      summary_id,
      employee_id,
      employee_name,
      department_name,
      channel_desc,
      total_sales,
      total_quantity
    FROM emp_channel_sales_summary;

    select * from emp_channel_sales_summary_new; 
    
--Sales totals are proportionally distributed among mapped employees so Making changes in sales table to include 
--employee_id to make data more realistic

ALTER TABLE sales ADD employee_id INT;

 UPDATE sales s
SET employee_id = (
  SELECT employee_id
  from (
    select employee_id
    from employee_channel_map
    where channel_id = s.channel_id
    order by dbms_random.value
  )
  where rownum = 1
);
   
    
 
select * from sales;   
    
    
BEGIN
      generate_emp_channel_summary;
END;  
    
--making appropriate changes
ALTER TABLE emp_channel_sales_summary Drop Constraint pk_emp_summary_id;

ALTER TABLE emp_channel_sales_summary Drop Column summary_id;



SELECT COUNT(DISTINCT employee_id)
FROM employee_channel_map;
    
--Since it only included 5 employees from employees table now using round robin to distribute sales

DECLARE
  CURSOR sales_cur IS
    SELECT rowid AS rid, channel_id FROM sales ORDER BY channel_id;

  TYPE emp_array IS Table of employees.employee_id%Type index by int;
  emp_ids emp_array;

  current_channel INT := NULL;
  emp_count INT := 0;
  emp_index PLS_INTEGER := 1;
BEGIN
  FOR s in sales_cur Loop
    -- New channel: load employee list
    IF s.channel_id != current_channel Then
      current_channel := s.channel_id;
      emp_count := 0;
      emp_index := 1;

      -- Load mapped employees for this channel
      SELECT employee_id
      Bulk Collect INTO emp_ids
      FROM employee_channel_map
      Where channel_id = current_channel;

      emp_count := emp_ids.Count;
    END IF;

    -- Only assign if there are mapped employees
    IF emp_count > 0 THEN
      UPDATE sales
      Set employee_id = emp_ids(emp_index)
      WHERE rowid = s.rid;

      emp_index := emp_index + 1;
      IF emp_index > emp_count THEN
        emp_index := 1;
      END IF;
    END IF;
  END LOOP;

  COMMIT;
END;

--still showing 5 employees so regenerating channel map

DECLARE
  TYPE ch_array is Table of channels.channel_id%type index by int;
  ch_list ch_array;
  ch_count PLS_INTEGER := 0;
BEGIN
  -- Loading valid channel IDs into array
  Select  channel_id
  Bulk collect into ch_list
  from channels
  order by channel_id;

  ch_count := ch_list.count;

  -- Clear old mappings
  DELETE FROM employee_channel_map;

  -- Assign 1–2 channels per employee
  FOR emp IN (SELECT employee_id FROM employees) LOOP
    DECLARE
      ch1 int;
      ch2 int;
    BEGIN
      ch1 := ch_list(TRUNC(DBMS_RANDOM.VALUE(1, ch_count + 1)));
      INSERT INTO employee_channel_map (employee_id, channel_id)
      VALUES (emp.employee_id, ch1);

      IF DBMS_RANDOM.VALUE < 0.4 THEN
        LOOP
          ch2 := ch_list(TRUNC(DBMS_RANDOM.VALUE(1, ch_count + 1)));
          EXIT WHEN ch2 != ch1;
        END LOOP;

        Insert into employee_channel_map (employee_id, channel_id)
        values (emp.employee_id, ch2);
      END IF;
    EXCEPTION
      WHEN DUP_VAL_ON_INDEX THEN NULL;
    END;
  END LOOP;

  COMMIT;
END;

--running round robin assignment in sales table
SELECT DISTINCT(employee_id) from SALES;

--calling procedure again
BEGIN
          generate_emp_channel_summary;
END;

SELECT * FROM emp_channel_sales_summary


SELECT COUNT(DISTINCT employee_id) FROM sales WHERE employee_id IS Not Null;

DECLARE
  CURSOR c_sales IS
    SELECT rowid AS rid, channel_id FROM sales ORDER BY channel_id;

  TYPE emp_array IS TABLE OF employees.employee_id%type index by int;
  emp_ids emp_array;

  current_channel int := -1;
  emp_index int := 1;
  emp_count int := 0;
BEGIN
  FOR sale_rec IN c_sales LOOP
    -- Only reload when channel changes
    IF sale_rec.channel_id != current_channel THEN
      current_channel := sale_rec.channel_id;

      SELECT employee_id
    bulk collect into emp_ids
      FROM employee_channel_map
      WHERE channel_id = current_channel;

      emp_count := emp_ids.count;
      emp_index := 1;
    END IF;

    -- Only assign if channel has mapped employees
    IF emp_count > 0 THEN
      UPDATE sales
      SET employee_id = emp_ids(emp_index)
      WHERE rowid = sale_rec.rid;

      emp_index := emp_index + 1;
      IF emp_index > emp_count THEN
        emp_index := 1;
      END IF;
    END IF;
  END LOOP;

  COMMIT;
END;

BEGIN
  generate_emp_channel_summary;
END;

SELECT count(distinct employee_id) FROM emp_channel_sales_summary;

SELECT * FROM emp_channel_sales_summary;

alter table emp_channel_sales_summary drop column summary_id;

alter table emp_channel_sales_summary drop column summary_id;
--Adding Surrogate PK again
    ALTER TABLE emp_channel_sales_summary
    ADD summary_id INT;
    CREATE Sequence emp_sum START WITH 1 Increment by 1;
    UPDATE emp_channel_sales_summary
    SET summary_id = emp_sum.NEXTVAL;
    
    select * from emp_channel_sales_summary;
--ARRANGING DATA IN NEW TABLE to copy to csv
    Create table summary_updated (
      summary_id      int primary key,
      employee_id     int,
      employee_name   varchar(50),
      department_name varchar(50),
      channel_desc    varchar(50),
      total_sales     int,
      total_quantity  int
    );
    
    insert into summary_updated (
      summary_id,
      employee_id,
      employee_name,
      department_name,
      channel_desc,
      total_sales,
      total_quantity
    )
    select
      summary_id,
      employee_id,
      employee_name,
      department_name,
      channel_desc,
      total_sales,
      total_quantity
   from emp_channel_sales_summary;

    select * from summary_updated order by summary_id; 
    
    