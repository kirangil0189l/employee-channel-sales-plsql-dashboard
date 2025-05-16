-- 1. Creating tables and copying data from HR and SH schemas

-- HR schema
Create table employees as Select * from hr.employees;
Create table departments as Select * from hr.departments;

-- SH schema
Create table sales     as Select * from sh.sales;
Create table channels  as Select * from sh.channels;
Create table times     as Select * from sh.times;

-- Adding primary keys
Alter table employees   add constraint pk_employees   primary key (employee_id);
Alter table departments add constraint pk_departments primary key (department_id);
Alter table channels    add constraint pk_channels    primary key (channel_id);

-- Create mapping table
Create table employee_channel_map (
  employee_id number references employees(employee_id),
  channel_id  number references channels(channel_id)
);

Alter table employee_channel_map
  add constraint pk_emp_channel primary key (employee_id, channel_id);

-- Quick check
Select * from employees;
Select channel_id from channels;


-- 2. Populating employee_channel_map with 1–2 channels per employee randomly

DECLARE
  type channel_array is table of number index by pls_integer;
  ch_ids channel_array;
  ch_count pls_integer := 0;
begin
  -- Load all valid channel IDs
  for rec in (Select channel_id from channels order by channel_id) LOOP
    ch_count := ch_count + 1;
    ch_ids(ch_count) := rec.channel_id;
  END LOOP;

  -- Assign channels to each employee
  for emp in (Select employee_id from employees) loop
    DECLARE
      ch1 number;
      ch2 number;
    BEGIN
      -- First channel
      ch1 := ch_ids(trunc(dbms_random.value(1, ch_count + 1)));
      insert into employee_channel_map values (emp.employee_id, ch1);

      -- 50% chance for second distinct channel
      if dbms_random.value < 0.5 then
        loop
          ch2 := ch_ids(trunc(dbms_random.value(1, ch_count + 1)));
          exit when ch2 != ch1;
        end loop;

        insert into employee_channel_map values (emp.employee_id, ch2);
      end if;

    exception
      when dup_val_on_index then null; -- skip if duplicate
    end;
  end loop;

  commit;
end;



-- 3. Checking the results

SELECT * FROM employee_channel_map;

Select
  e.employee_id,
  e.first_name || ' ' || e.last_name as employee_name,
  c.channel_desc
from employee_channel_map m
join employees e on m.employee_id = e.employee_id
join channels  c on m.channel_id   = c.channel_id
ORDER BY e.employee_id, c.channel_id;
