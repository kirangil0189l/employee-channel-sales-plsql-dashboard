# employee-channel-sales-plsql-dashboard
This project demonstrates a complete analytics pipeline using Oracle PL/SQL, integrating HR and Sales data from two sample schemas (`HR` and `SH`), simulating realistic sales assignments to employees, and visualizing the results in Tableau.
Objective is to simulate a realistic sales organization by:
- Mapping employees to sales channels
- Distributing actual sales transactions to employees
- Aggregating performance metrics per employee
- Visualizing team and department-level performance in an interactive dashboard.
  
  
In the original Oracle sample data, sales transactions are not linked to specific employees. To analyze performance realistically, this project introduces a controlled simulation:
- Employees are mapped to sales channels randomly (1–2 each)
- Sales are distributed to employees using  round-robin logic within each channel
- Employee-level totals are computed based on  actual assigned transactions

Tool              :                   	Use Case

Oracle SQL Developer	: Data Integration, transformation, Pl/SQL procedures

PL/SQL	: Table creation, mapping logic, aggregation

Tableau Desktop	: Dashboard creation and insights visualization

Workflow

Step 1: Data Integration
- Copied tables from `HR` and `SH` schemas:
  - `employees`, `departments` (HR)
  - `sales`, `channels`, `times` (SH)

Step 2: Custom Table Setup
- `employee_channel_map`: maps each employee to one or two channels
- `sales.employee_id`: added to store actual assigned sales responsibility
- `emp_channel_sales_summary`: aggregates results for dashboarding

Step 3: PL/SQL Logic
- `mapping.sql`: creates and populates `employee_channel_map`
- `round_robin_assignment.sql`: distributes sales evenly per channel
- `aggregation_proc.sql`: summarizes total sales and quantity per employee
- `summary.sql`: defines output structure for visualization

Dashboard Features (Tableau)

![image](https://github.com/user-attachments/assets/ab4880db-bd06-46c6-8dd7-536442102e9e)

KPIs
- **Total Sales**
- **Total Quantity Sold**
- **Average Sales per Employee**
- **Top Sales Performer**

  Visuals
-  Sales by Department
- Average Sales per Employee by Department
- Sales vs Quantity in Sales Department
- Top 5 Employees by Sales
-  Sales by Channel (Pie Chart)

Project Structure

employee-channel-sales-dashboard/

├── mapping.sql -- PL/SQL to create & populate mappings

├── round_robin_assignment.sql -- Distributes sales to employees per channel

├── summary.sql -- Table for dashboard-level summary

├── aggregation_proc.sql -- Procedure to summarize per-employee sales

├── emp_channel_sales_summary.csv -- Exported summary used in Tableau

├── dashboard.twbx -- Tableau packaged workbook

├── README.md -- Project overview

Key Assumptions

Key Assumptions

- Employees do not have assigned sales in the SH schema, so all assignments are simulated
- Round-robin logic ensures fairness in distribution per channel
- Average sales per employee is affected by both volume and department size
  

  Future Enhancements

- Add `times` dimension to enable **time-series KPIs** (e.g., monthly trends)
- Introduce performance bands or targets (e.g., highlight employees above target)
- Include **customer or product-level breakdown** in future analysis

  Author
  **Sukhkirandeep Kaur Sidhu**
  sukhkirandeep.kaur@gmail.com
