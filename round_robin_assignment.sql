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