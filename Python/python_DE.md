# Python Data Engineering Notes


# Threading

1. Threading allows your program to run multiple functions or tasks concurrently
2. Only Execute **I/O Bounded** task not CPU Bounded
3. Network requests, Read or write file, Accessing a database
4. **CPU Bounded Tasks** - Mathematical calculation, Data processing in memory, Algorithm execution

# Generators

1. it doesn't execute the entire code at once. Instead, it returns a generator object
2. using the **`yield`** keyword instead of **`return`**
3. This makes them highly memory-efficient, especially when dealing with large datasets, as they don't store the entire sequence in memory.
4. Eg: Processing large data files, Pipelines, Infinite sequences

## Data Warehouse vs. Data Lake

| Feature          | Data Warehouse                                                                                                                            | Data Lake                                                                                                                                    |
| ---------------- | ----------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- |
| **Data Type**    | Stores **structured**, processed data.                                                                                                    | Stores **raw** data of any type (structured, semi-structured, and unstructured).                                                             |
| **Schema**       | **Schema-on-write:** The schema (data model) is defined and data is transformed **before** it's loaded into the warehouse.                | **Schema-on-read:** Data is stored in its original format. A schema is applied **only when** the data is read or analyzed.                   |
| **Purpose**      | Designed for **business intelligence** (BI), reporting, and analysis. It provides a "single source of truth" for decision-making.         | Designed for **data science**, machine learning (ML), and exploratory analytics. It stores data for future, as-yet-unknown use cases.        |
| **Process**      | Uses an **ETL** (Extract, Transform, Load) process. Data is cleaned and transformed before it's loaded.                                   | Uses an **ELT** (Extract, Load, Transform) process. Data is loaded in its raw form and transformed only when needed for a specific analysis. |
| **Users**        | Typically used by **business analysts**, executives, and other non-technical users who need pre-analyzed data for reports and dashboards. | Used by **data scientists**, data engineers, and developers who need raw data to build models and perform deep analysis.                     |
| **Data Quality** | High. Data is cleaned, validated, and highly curated to ensure accuracy.                                                                  | Variable. Can be a mix of high-quality, trusted data and raw, unverified data.                                                               |
| **Cost**         | More expensive per GB because of the processing, structuring, and management required.                                                    | Generally lower cost per GB because it uses inexpensive storage and requires less upfront processing.                                        |
| **Agility**      | Less agile. Making changes to the schema or data structure requires a lot of effort and can be time-consuming.                            | Highly agile and flexible. It can quickly ingest new data sources without complex planning or changes to the data model.                     |

# OLTP and OLAP

| Feature                      | **OLTP (Online Transaction Processing)**                              | **OLAP (Online Analytical Processing)**                                            |
| ---------------------------- | --------------------------------------------------------------------- | ---------------------------------------------------------------------------------- |
| **Purpose**                  | Handles day-to-day transactional operations (insert, update, delete). | Performs complex queries and analysis for decision-making.                         |
| **Data Source**              | Operational databases (ERP, CRM, POS systems, banking apps).          | Data warehouses, data lakes, or lakehouses.                                        |
| **Data Type**                | Current, real-time transactional data.                                | Historical, aggregated, and summarized data.                                       |
| **Query Type**               | Simple, read/write queries (CRUD).                                    | Complex, read-intensive queries (aggregations, joins, multi-dimensional analysis). |
| **Data Volume**              | Smaller, frequently changing datasets.                                | Very large, historical datasets spanning years.                                    |
| **Normalization**            | Highly normalized schema (3NF or more) to reduce redundancy.          | Denormalized/star or snowflake schema for faster querying.                         |
| **Transaction Handling**     | ACID compliance (ensures data integrity).                             | Not transaction-focused, more emphasis on query performance.                       |
| **Users**                    | Operational staff, clerks, and customer-facing applications.          | Data analysts, data scientists, business intelligence teams.                       |
| **Performance Optimization** | Optimized for fast write operations and quick transaction processing. | Optimized for fast read operations and analytical queries.                         |
| **Response Time**            | Milliseconds (sub-second).                                            | Seconds to minutes (depending on query complexity).                                |
| **Concurrency**              | Supports thousands/millions of concurrent users.                      | Supports fewer concurrent users compared to OLTP.                                  |
| **Example Use Cases**        | Banking transactions, e-commerce order processing, ticket booking.    | Sales forecasting, customer behavior analysis, risk analysis, trend reporting.     |

# Optimizing Table and Query speed
1. Indexing
2. Partitioning
3. Denormalization (Star Schema Approach)
4. Materialized Views
5. Query Optimization
6. Caching
7. Columnar Storage (OLAP Systems)
8. Data Distribution & Sharding
9. Compression & Encoding

# Data Modeling

**Data Modeling** is the process of **designing and structuring data** in a way that represents how it will be **stored, organized, and accessed** in databases or data warehouses.

***`Data Modeling = Blueprint of your database/warehouse → ensures efficiency, scalability, and consistency.`***

## 📌 **Types of Data Models**

1. **Conceptual Data Model**
    - High-level view of data and relationships.
    - Focuses on _what data is important_ (entities & relationships).
    - Audience: Business stakeholders.
    - Example: _Customers place Orders_.
        
2. **Logical Data Model**
    - More detail than conceptual.
    - Defines attributes, keys, and relationships without worrying about the database engine.
    - Audience: Data architects, engineers.
    - Example: _Customer (customer_id, name, email)_, _Order (order_id, date, customer_id)_.
        
3. **Physical Data Model**
    - Actual implementation in a database.
    - Includes tables, data types, indexes, partitioning, constraints, etc.
    - Audience: Database developers, engineers.
    - Example: PostgreSQL table definitions with indexes, datatypes (`VARCHAR`, `INT`).

## 📌 **Data Modeling Techniques**

- **ER Modeling (Entity-Relationship Model):** Used in OLTP systems.
- **Star Schema:** Central fact table + dimension tables (used in OLAP).
- **Snowflake Schema:** Normalized version of star schema (OLAP).
- **Data Vault Modeling:** Flexible model for modern data warehouses (handles historical tracking well).

# Key Differences: ETL vs ELT

| Feature                          | **ETL**                                                                   | **ELT**                                                                    |
| -------------------------------- | ------------------------------------------------------------------------- | -------------------------------------------------------------------------- |
| **Process Order**                | Extract → Transform → Load                                                | Extract → Load → Transform                                                 |
| **Where Transformation Happens** | In external ETL tools (Informatica, Talend, Spark, Python) before loading | Inside the data warehouse/lake (Snowflake, BigQuery, Redshift, Databricks) |
| **Best For**                     | Smaller datasets, legacy systems, strict compliance needs                 | Large datasets, cloud data warehouses, real-time analytics                 |
| **Performance**                  | Slower (extra staging layer)                                              | Faster (push-down transformations to warehouse)                            |
| **Data Storage**                 | Stores only **processed data** in warehouse                               | Stores **raw + processed data** in warehouse                               |
| **Flexibility**                  | Limited (once loaded, data is transformed & fixed)                        | High (can re-transform raw data anytime)                                   |
| **Tools**                        | Informatica, Talend, SSIS, Apache NiFi                                    | dbt, Spark SQL, BigQuery SQL, Snowflake transformations                    |
✅ **Summary:**

- Use **ETL** when your **warehouse is weak or compliance is strict** (banking, healthcare, government).
    
- Use **ELT** when your **warehouse is powerful & scalable** (cloud data warehouses, real-time analytics, big data).

## 📌 **Types of Data Structures**

Data structures are ways of organizing and storing data efficiently.

### 1. **Linear Data Structures**
Data is arranged sequentially.
- **Array** – Collection of elements stored at contiguous memory locations.
- **Linked List** – Nodes connected with pointers (singly, doubly, circular).
- **Stack** – LIFO (Last In, First Out). Example: Undo/Redo, call stack.
- **Queue** – FIFO (First In, First Out). Variants: Circular Queue, Deque, Priority Queue.
### 2. **Non-Linear Data Structures**

Data is not sequential.
- **Tree** – Hierarchical structure. Variants: Binary Tree, Binary Search Tree (BST), AVL Tree, B-Trees, Heap.
- **Graph** – Collection of nodes and edges (directed, undirected, weighted, unweighted).

### 3. **Hash-based Structures**
- **Hash Table / Hash Map** – Stores key-value pairs for fast lookup.


## 📌 **Types of Algorithms**
Algorithms are step-by-step methods to solve problems efficiently.

### 1. **Sorting Algorithms**
- Bubble Sort, Selection Sort, Insertion Sort (basic).
- Merge Sort, Quick Sort, Heap Sort (efficient, O(n log n)).

### 2. **Searching Algorithms**
- Linear Search (O(n)).
- Binary Search (O(log n), works on sorted arrays).

### 3. **Graph Algorithms**
- BFS (Breadth-First Search).
- DFS (Depth-First Search).
- Dijkstra’s Algorithm (shortest path).
- Bellman-Ford, Floyd-Warshall (all-pairs shortest paths).
- Kruskal’s & Prim’s Algorithm (Minimum Spanning Tree).

### 4. **Dynamic Programming (DP)**
- Fibonacci, Longest Common Subsequence (LCS), Knapsack Problem.

### 5. **Greedy Algorithms**
- Activity Selection, Huffman Coding, Minimum Spanning Tree.

### 6. **Divide and Conquer**
- Merge Sort, Quick Sort, Binary Search.

### 7. **Backtracking**
- N-Queens Problem, Sudoku Solver, Rat in a Maze.

### 8. **Hashing & String Matching**
- Rabin-Karp, KMP Algorithm.