# Topics to Note & Practice


**What is a Schema?**

In SQL, a schema is a logical container or namespace within a database. If a database is like a computer's hard drive, a schema is like a folder used to organize the files (tables, views, functions) inside it.

**Advantages of Using Schemas:**

- **Namespace Organization:** Schemas prevent naming collisions. You can have multiple tables with the exact same name in a single database, as long as they are in different schemas (e.g., `sales.users` and `hr.users`).
    
- **Centralized Security(RBAC):** Instead of managing permissions for dozens of individual tables, you can grant or restrict access at the schema level. For example, you can give an analytics tool access only to the `reporting` schema, keeping the rest of the database secure.
    
- **Easier Backups and Maintenance:** Schemas allow database administrators to isolate parts of the database. You can easily back up, restore, or migrate a specific schema (like `archive_2023`) without affecting the entire database.
    
- **Multi-Tenant Architecture:** For applications serving multiple clients (SaaS), schemas provide a clean way to isolate client data. Each client gets their own schema (e.g., `client_a.data`, `client_b.data`), ensuring data separation while sharing the same underlying database infrastructure.


# PostgreSQL Schema Inspection Cheat Sheet

When building your API, you need to verify your database schema matches your Python Pydantic models. Here are the two ways to inspect your tables, columns, and data types.

## Method 1: The Fast Way (psql Meta-Commands)

Use these shortcuts when you are actively working inside the Ubuntu `psql` terminal.

```
# List all tables in the current database
\dt

# List all views
\dv

# Describe a specific table in detail
# (Shows columns, data types, modifiers, indexes, foreign keys, and triggers)
\d table_name

# Example: Inspect the issues table
\d issues
```

## Method 2: The Pure SQL Way (information_schema)

Use these standard SQL queries if you want to pull metadata programmatically (e.g., from a Python script) or if you want a clean, tabular result.

### 1. List All Tables

```
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;
```

### 2. Inspect Columns and Data Types for a Specific Table

_Replace `'issues'` with your target table name._

```
SELECT 
    column_name, 
    data_type, 
    character_maximum_length AS max_length, 
    column_default, 
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'issues'
ORDER BY ordinal_position;
```

### 3. List All Foreign Keys

```
SELECT
    tc.table_name, 
    kcu.column_name, 
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name 
FROM 
    information_schema.table_constraints AS tc 
    JOIN information_schema.key_column_usage AS kcu
      ON tc.constraint_name = kcu.constraint_name
      AND tc.table_schema = kcu.table_schema
    JOIN information_schema.constraint_column_usage AS ccu
      ON ccu.constraint_name = tc.constraint_name
      AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY';
```