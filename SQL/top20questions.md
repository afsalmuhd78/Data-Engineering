
# Top 20 SQL Interview Questions
---

### **1. What is the difference between WHERE and HAVING?**

> - `WHERE` filters rows **before aggregation**.
>     
> - `HAVING` filters groups **after aggregation**.
>     

```
SELECT department, COUNT(*)  
FROM employees 
WHERE salary > 30000 
GROUP BY department 
HAVING COUNT(*) > 5;
```

---

### **2. What is the difference between INNER JOIN and LEFT JOIN?**

> - **INNER JOIN**: Only matching records.
>     
> - **LEFT JOIN**: All left table records + matched right records.
>     

---

### **3. What is a CTE (Common Table Expression)?**

> A CTE is a **temporary result set** that can be referenced in the main query.  
> Improves readability and avoids repeating subqueries.

`WITH high_salary AS (   SELECT * FROM employees WHERE salary > 50000 ) SELECT * FROM high_salary WHERE department = 'IT';`

---

### **4. What are Window Functions?**

> Window functions perform calculations **across a set of table rows** related to the current row.

**Example:**

`SELECT    name, department, salary,   RANK() OVER (PARTITION BY department ORDER BY salary DESC) AS rank_in_dept FROM employees;`

---

### **5. Difference between RANK(), DENSE_RANK(), and ROW_NUMBER()?**

|Function|Duplicate Handling|Example Output|
|---|---|---|
|**RANK()**|Skips ranks|1, 2, 2, 4|
|**DENSE_RANK()**|No skip|1, 2, 2, 3|
|**ROW_NUMBER()**|Unique|1, 2, 3, 4|

---

### **6. How to find duplicate records in a table?**

`SELECT name, COUNT(*) FROM employees GROUP BY name HAVING COUNT(*) > 1;`

---

### **7. How to delete duplicate records?**

`DELETE FROM employees WHERE id NOT IN (   SELECT MIN(id)    FROM employees    GROUP BY name );`

---

### **8. What is a self join?**

> Joining a table with itself — used for hierarchical data (e.g., employee-manager).

`SELECT e.name AS employee, m.name AS manager FROM employees e JOIN employees m ON e.manager_id = m.id;`

---

### **9. What is Normalization and why is it used?**

> - Normalization reduces redundancy and improves consistency.
>     
> - **1NF, 2NF, 3NF** are common forms.
>     
>     - 1NF: Remove repeating columns
>         
>     - 2NF: Remove partial dependency
>         
>     - 3NF: Remove transitive dependency
>         

---

### **10. What is Denormalization?**

> Denormalization adds redundancy **for performance**, often used in **data warehouses** for faster querying.

---

### **11. How to get the 2nd highest salary?**

```
SELECT MAX(salary) AS second_highest FROM employees WHERE salary < (SELECT MAX(salary) FROM employees);
```

Or using **RANK():**

```
SELECT name, salary FROM (   SELECT name, salary, RANK() OVER (ORDER BY salary DESC) AS rnk   FROM employees ) tmp WHERE rnk = 2;
```

---

### **12. What is a Primary Key, Foreign Key, and Unique Key?**

| Key Type        | Description                                        |
| --------------- | -------------------------------------------------- |
| **Primary Key** | Uniquely identifies each row (no NULLs).           |
| **Foreign Key** | Links to a primary key in another table.           |
| **Unique Key**  | Ensures all values are unique (can have one NULL). |

---

### **13. What is a View?**

> A **View** is a virtual table created using a SQL query.  
> It doesn’t store data, but shows dynamic results.

```
CREATE VIEW active_employees AS SELECT name, department FROM employees WHERE status = 'Active';
```

---

### **14. How to get running totals or cumulative sums?**

```
SELECT    customer_id,   order_date,   
SUM(amount) OVER (PARTITION BY customer_id ORDER BY order_date) AS running_total 
FROM orders;
```

---

### **15. Difference between DELETE, TRUNCATE, and DROP**

|Command|Function|Rollback|Structure Removed|
|---|---|---|---|
|DELETE|Removes specific rows|✅ Yes|❌ No|
|TRUNCATE|Removes all rows|❌ No|❌ No|
|DROP|Deletes entire table|❌ No|✅ Yes|

---

### **16. How to find employees who earn more than their department average?**

`SELECT name, department, salary FROM employees e WHERE salary > (   SELECT AVG(salary)   FROM employees   WHERE department = e.department );`

---

### **17. How to get top N records per group?**

`SELECT name, department, salary FROM (   SELECT name, department, salary,          ROW_NUMBER() OVER (PARTITION BY department ORDER BY salary DESC) AS rn   FROM employees ) tmp WHERE rn <= 3;`

---

### **18. How to find missing IDs in a sequence?**

`SELECT t1.id + 1 AS missing_id FROM employees t1 LEFT JOIN employees t2 ON t1.id + 1 = t2.id WHERE t2.id IS NULL;`

---

### **19. What is a Materialized View?**

> A **Materialized View** stores the query result physically (unlike a normal view).  
> Used in **data warehouses** for fast access to large, pre-aggregated data.

---

### **20. How do you handle Incremental Data Load in SQL?**

> Use a timestamp column like `last_updated` and load only records changed after last load.

`SELECT * FROM orders WHERE last_updated > '2025-10-10';`


### **21. What is an Index and why is it used?**

**Answer:**

> An **index** speeds up data retrieval by creating a quick lookup structure for a column.  
> It works like a book’s index — helps find data faster, but slightly slows down inserts and updates.