# SQL Theory & FAQ


# Window Function

It is a analytical tool used in SQL
A **window function** in SQL performs calculations across a set of rows related to the current row, without collapsing the result into a single output like `GROUP BY` does.  
It is commonly used for **ranking, running totals, moving averages, and partition-based calculations**.

| Student | Score | ROW_NUMBER | RANK | DENSE_RANK |
| ------- | ----- | ---------- | ---- | ---------- |
| A       | 100   | 1          | 1    | 1          |
| B       | 95    | 2          | 2    | 2          |
| C       | 95    | 3          | 2    | 2          |
| D       | 90    | 4          | 4    | 3          |
| E       | 85    | 5          | 5    | 4          |

# Case Example

```
select salary, department, name,
case
    when salary > 100000 then 'High Salary'
    when salary between 50000 and 100000 then 'Medium Salary'
    else 'Low Salary'
end as salary_category
from employees
where department = 'Engineering';
```


# DDL, DML, DCL, TCL AND DQL

***They are categories of SQL commands, grouped by what they do inside a database.***

| Category | Full Form                    | Purpose                       | Key Commands                                    |
| -------- | ---------------------------- | ----------------------------- | ----------------------------------------------- |
| **DDL**  | Data Definition Language     | Defines database structure    | `CREATE`, `ALTER`, `DROP`, `TRUNCATE`, `RENAME` |
| **DML**  | Data Manipulation Language   | Manipulates data              | `INSERT`, `UPDATE`, `DELETE`, `MERGE`           |
| **DCL**  | Data Control Language        | Controls access & permissions | `GRANT`, `REVOKE`                               |
| **TCL**  | Transaction Control Language | Manages transactions          | `COMMIT`, `ROLLBACK`, `SAVEPOINT`               |
| **DQL**  | Data Query Language          | Retrieves data                | `SELECT`                                        |


**🗣️ Interviewer:** What’s the difference between `WHERE` and `HAVING` in SQL?

**🧑‍💻 You:**

> The main difference is that **`WHERE`** is used to filter **rows before** any grouping or aggregation happens, while **`HAVING`** is used to filter **groups or aggregate results** after the `GROUP BY` clause.
> 
> In other words, `WHERE` works on **individual rows**, and `HAVING` works on **aggregated data**.

> For example:
> 
> `SELECT department, COUNT(*) AS emp_count 
> FROM employees 
> WHERE salary > 50000 GROUP BY department 
> HAVING COUNT(*) > 5;`
> 
> Here,
> 
> - `WHERE salary > 50000` filters employees before grouping,
>     
> - `HAVING COUNT(*) > 5` filters out departments that have fewer than 5 employees after grouping.
>     

> So `WHERE` can’t use aggregate functions like `COUNT()` or `SUM()`, but `HAVING` can.


**🗣️ Interviewer:** What’s the difference between `UNION` and `UNION ALL` in SQL?

**🧑‍💻 You:**

> The key difference is that **`UNION` removes duplicate rows**, while **`UNION ALL` keeps all rows including duplicates**.
> 
> Both are used to combine results from two or more `SELECT` queries — but they handle duplicates differently.
> 
> For example:
> 
> `SELECT city FROM customers UNION SELECT city FROM suppliers;`
> 
> This will return a **distinct list** of cities (no duplicates).
> 
> Whereas:
> 
> `SELECT city FROM customers UNION ALL SELECT city FROM suppliers;`
> 
> This will return **all rows**, even if the same city appears in both tables.
> 
> In terms of performance, `UNION ALL` is **faster** because it doesn’t perform the extra step of removing duplicates.


**🗣️ Interviewer:** What is incremental load in SQL?

**🧑‍💻 You:**

> Incremental load in SQL means loading **only the new or updated records** from a source table into a target table (like a data warehouse), instead of reloading the entire data every time.
> 
> It’s used in **ETL processes** to keep data synchronized efficiently — saving time, storage, and processing power.


**🗣️ Interviewer:** What are the different types of joins in SQL?

**🧑‍💻 You:**

> In SQL, **joins** are used to combine rows from two or more tables based on a related column between them — usually a key.
> 
> The main types of joins are **INNER JOIN, LEFT JOIN, RIGHT JOIN, and FULL OUTER JOIN**.
> 
> Let me explain each one simply 👇

---

### 🔹 **1. INNER JOIN**

✅ Returns **only the matching rows** from both tables.

**Example:**

`SELECT employees.name, departments.dept_name FROM employees INNER JOIN departments ON employees.dept_id = departments.id;`

🟢 **Output:** Only employees who belong to a valid department.

---

### 🔹 **2. LEFT JOIN (or LEFT OUTER JOIN)**

✅ Returns **all rows from the left table**, and the **matching rows** from the right table.  
If no match is found, the right side shows **NULL**.

**Example:**

`SELECT employees.name, departments.dept_name FROM employees LEFT JOIN departments ON employees.dept_id = departments.id;`

🟢 **Output:** All employees — even those who are not assigned to any department.

---

### 🔹 **3. RIGHT JOIN (or RIGHT OUTER JOIN)**

✅ Opposite of LEFT JOIN.  
Returns **all rows from the right table**, and matching rows from the left table.

**Example:**

`SELECT employees.name, departments.dept_name FROM employees RIGHT JOIN departments ON employees.dept_id = departments.id;`

🟢 **Output:** All departments — even if they have no employees.

---

### 🔹 **4. FULL OUTER JOIN**

✅ Returns **all rows from both tables** — matches and non-matches.  
Where there’s no match, it shows **NULL** on the missing side.

**Example:**

`SELECT employees.name, departments.dept_name FROM employees FULL OUTER JOIN departments ON employees.dept_id = departments.id;`

🟢 **Output:**  
All employees + all departments (including unmatched ones).

---

### 🔹 **5. CROSS JOIN**

✅ Returns **all possible combinations** of both tables — also known as a **Cartesian product**.

**Example:**

`SELECT employees.name, departments.dept_name FROM employees CROSS JOIN departments;`

🟢 **Output:** Every employee paired with every department.

---

### 🔹 **6. SELF JOIN**

✅ A table joined with **itself** — useful for comparing rows within the same table.

**Example:**

`SELECT a.name AS employee, b.name AS manager FROM employees a JOIN employees b ON a.manager_id = b.id;`

🟢 **Output:** Employee–Manager relationships from the same table.

---

### 🧭 **Summary Table**

| Join Type           | Returns                            |
| ------------------- | ---------------------------------- |
| **INNER JOIN**      | Only matching rows                 |
| **LEFT JOIN**       | All from left + matched from right |
| **RIGHT JOIN**      | All from right + matched from left |
| **FULL OUTER JOIN** | All rows from both tables          |
| **CROSS JOIN**      | All combinations                   |
| **SELF JOIN**       | Join within the same table         |

