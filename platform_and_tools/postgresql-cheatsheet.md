# PostgreSQL Cheatsheet

> Quick reference for all key terms, concepts, commands, and components of PostgreSQL.

---

## Architecture Overview

```
Client (psql / app)
        ↓
Postmaster (listener process)
        ↓
Backend Process (one per connection)
        ↓
Shared Memory ──────────────────────────────────────────────
  ├── Shared Buffer Pool    (data page cache)
  ├── WAL Buffer            (write-ahead log buffer)
  └── Lock Table / Catalog Cache
        ↓
Storage (Disk)
  ├── Data Files            ($PGDATA/base/)
  ├── WAL Files             ($PGDATA/pg_wal/)
  ├── Config Files          (postgresql.conf, pg_hba.conf)
  └── System Catalogs       (pg_class, pg_attribute, ...)
```

---

## Core Concepts

| Term | Description |
|------|-------------|
| **Cluster** | A PostgreSQL installation managing multiple databases. One `$PGDATA` directory. |
| **Database** | Isolated namespace within a cluster. Has its own schemas, tables, roles. |
| **Schema** | Namespace inside a database. Default is `public`. Used to organise objects. |
| **Table** | Relation storing rows and columns. Core storage object. |
| **Relation** | Generic term for any table, view, index, sequence, or materialized view. |
| **Tablespace** | Defines physical storage location on disk. Allows spreading data across volumes. |
| **Postmaster** | Master process that listens for connections and forks backend processes. |
| **Backend** | Per-connection server process. Runs queries, manages transactions. |
| **WAL** | Write-Ahead Log. All changes written to WAL before data files. Basis for durability and replication. |
| **MVCC** | Multi-Version Concurrency Control. Readers never block writers; each transaction sees a consistent snapshot. |
| **Vacuum** | Reclaims storage from dead tuples created by MVCC. Essential for table health. |
| **Autovacuum** | Background daemon that runs VACUUM and ANALYZE automatically. |
| **TOAST** | The Oversized-Attribute Storage Technique. Stores large column values (>2KB) out-of-line. |
| **OID** | Object Identifier. Internal unique ID for database objects. |
| **Tuple** | A single row in a table (PostgreSQL internal term). |

---

## Data Types

### Numeric

| Type | Description |
|------|-------------|
| `smallint` | 2-byte integer. Range: -32,768 to 32,767 |
| `integer` / `int` | 4-byte integer. Range: ~±2.1 billion |
| `bigint` | 8-byte integer. Range: ~±9.2 quintillion |
| `numeric(p, s)` | Arbitrary precision. Use for money/financial data. |
| `real` | 4-byte float. ~6 decimal digits precision. |
| `double precision` | 8-byte float. ~15 decimal digits precision. |
| `serial` / `bigserial` | Auto-incrementing integer (wraps a sequence). |

### String

| Type | Description |
|------|-------------|
| `char(n)` | Fixed-length, blank-padded. |
| `varchar(n)` | Variable-length with limit. |
| `text` | Unlimited variable-length. Preferred in PostgreSQL. |

### Date / Time

| Type | Description |
|------|-------------|
| `date` | Calendar date only (no time). |
| `time` | Time of day (no date). |
| `timestamp` | Date + time, no timezone. |
| `timestamptz` | Date + time with timezone (stores UTC). Preferred. |
| `interval` | Duration. e.g. `'3 days'`, `'2 hours 30 minutes'` |

### Other Common Types

| Type | Description |
|------|-------------|
| `boolean` | `true` / `false` / `null` |
| `uuid` | 128-bit universally unique identifier |
| `json` / `jsonb` | JSON data. `jsonb` is binary, indexed, preferred. |
| `array` | Array of any type. e.g. `integer[]`, `text[]` |
| `hstore` | Key-value pairs (requires extension). |
| `inet` / `cidr` | IPv4/IPv6 network addresses. |
| `bytea` | Binary data (byte array). |
| `enum` | User-defined ordered set of string values. |
| `tsvector` / `tsquery` | Full-text search types. |
| `point` / `polygon` | Geometric types. |
| `money` | Currency (locale-dependent). Prefer `numeric` instead. |

---

## DDL — Data Definition Language

```sql
-- Databases
CREATE DATABASE mydb;
DROP DATABASE mydb;
ALTER DATABASE mydb RENAME TO newname;

-- Schemas
CREATE SCHEMA myschema;
SET search_path TO myschema, public;

-- Tables
CREATE TABLE users (
    id          BIGSERIAL PRIMARY KEY,
    email       TEXT        NOT NULL UNIQUE,
    name        VARCHAR(100),
    age         INTEGER     CHECK (age >= 0),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    metadata    JSONB
);

-- Column modifications
ALTER TABLE users ADD COLUMN phone TEXT;
ALTER TABLE users DROP COLUMN phone;
ALTER TABLE users ALTER COLUMN name TYPE VARCHAR(200);
ALTER TABLE users ALTER COLUMN name SET NOT NULL;
ALTER TABLE users ALTER COLUMN name DROP NOT NULL;
ALTER TABLE users ALTER COLUMN name SET DEFAULT 'unknown';
ALTER TABLE users RENAME COLUMN name TO full_name;
ALTER TABLE users RENAME TO customers;

-- Constraints
ALTER TABLE orders ADD CONSTRAINT fk_user
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
ALTER TABLE users ADD CONSTRAINT chk_age CHECK (age BETWEEN 0 AND 150);
ALTER TABLE users ADD CONSTRAINT uq_email UNIQUE (email);
ALTER TABLE users DROP CONSTRAINT uq_email;

-- Drop
DROP TABLE users;
DROP TABLE IF EXISTS users CASCADE;   -- CASCADE drops dependent objects

-- Truncate (fast delete all rows, resets sequences)
TRUNCATE TABLE users RESTART IDENTITY CASCADE;
```

---

## DML — Data Manipulation Language

```sql
-- Insert
INSERT INTO users (email, name, age) VALUES ('a@b.com', 'Alice', 30);
INSERT INTO users (email, name) VALUES
    ('b@c.com', 'Bob'),
    ('c@d.com', 'Carol');

-- Insert from select
INSERT INTO archive_users SELECT * FROM users WHERE created_at < '2023-01-01';

-- Upsert (INSERT ... ON CONFLICT)
INSERT INTO users (email, name)
VALUES ('a@b.com', 'Alice Updated')
ON CONFLICT (email) DO UPDATE
    SET name = EXCLUDED.name,
        updated_at = now();

-- Do nothing on conflict
INSERT INTO users (email, name)
VALUES ('a@b.com', 'Alice')
ON CONFLICT (email) DO NOTHING;

-- Update
UPDATE users SET name = 'Alice Smith', age = 31 WHERE id = 1;

-- Update with join (using FROM)
UPDATE orders o
SET status = 'verified'
FROM users u
WHERE o.user_id = u.id AND u.verified = true;

-- Delete
DELETE FROM users WHERE id = 1;
DELETE FROM users WHERE created_at < now() - INTERVAL '1 year';

-- Delete with join (using USING)
DELETE FROM orders o
USING users u
WHERE o.user_id = u.id AND u.active = false;

-- Returning (get affected rows back)
INSERT INTO users (email) VALUES ('x@y.com') RETURNING id, created_at;
UPDATE users SET name = 'New' WHERE id = 1 RETURNING *;
DELETE FROM users WHERE id = 1 RETURNING id;
```

---

## DQL — Querying

```sql
-- Basic select
SELECT id, name, age FROM users WHERE age > 25 ORDER BY name ASC LIMIT 10 OFFSET 20;

-- Aliases
SELECT u.name AS user_name, o.total AS order_total
FROM users u JOIN orders o ON u.id = o.user_id;

-- Distinct
SELECT DISTINCT city FROM users;
SELECT DISTINCT ON (dept) dept, name, salary FROM employees ORDER BY dept, salary DESC;

-- Aggregations
SELECT dept, COUNT(*) AS cnt, AVG(salary) AS avg_sal, SUM(salary) AS total
FROM employees
GROUP BY dept
HAVING COUNT(*) > 5;

-- Case expression
SELECT name,
    CASE
        WHEN age < 18 THEN 'minor'
        WHEN age < 65 THEN 'adult'
        ELSE 'senior'
    END AS age_group
FROM users;

-- Subqueries
SELECT * FROM users WHERE id IN (SELECT user_id FROM orders WHERE total > 1000);
SELECT *, (SELECT COUNT(*) FROM orders WHERE user_id = u.id) AS order_count FROM users u;

-- EXISTS
SELECT * FROM users u WHERE EXISTS (
    SELECT 1 FROM orders o WHERE o.user_id = u.id AND o.status = 'pending'
);

-- CTEs (Common Table Expressions)
WITH active_users AS (
    SELECT * FROM users WHERE active = true
),
user_orders AS (
    SELECT user_id, COUNT(*) AS cnt FROM orders GROUP BY user_id
)
SELECT u.name, uo.cnt
FROM active_users u
LEFT JOIN user_orders uo ON u.id = uo.user_id;

-- Recursive CTE (hierarchy / tree traversal)
WITH RECURSIVE org_tree AS (
    SELECT id, name, manager_id, 0 AS depth
    FROM employees WHERE manager_id IS NULL
    UNION ALL
    SELECT e.id, e.name, e.manager_id, ot.depth + 1
    FROM employees e
    JOIN org_tree ot ON e.manager_id = ot.id
)
SELECT * FROM org_tree ORDER BY depth;
```

---

## Joins

| Type | Description |
|------|-------------|
| `INNER JOIN` | Rows with matches in both tables (default). |
| `LEFT JOIN` | All rows from left + matched from right. Nulls if no match. |
| `RIGHT JOIN` | All rows from right + matched from left. |
| `FULL OUTER JOIN` | All rows from both. Nulls where no match. |
| `CROSS JOIN` | Cartesian product. Every row × every row. |
| `SELF JOIN` | Join a table to itself (use aliases). |
| `LATERAL JOIN` | Subquery can reference columns of preceding `FROM` items. |
| `NATURAL JOIN` | Auto-joins on all columns with the same name. Avoid in production. |

```sql
-- LATERAL join example
SELECT u.name, latest.total
FROM users u
JOIN LATERAL (
    SELECT total FROM orders WHERE user_id = u.id ORDER BY created_at DESC LIMIT 1
) latest ON true;

-- Self join (employee and manager)
SELECT e.name AS employee, m.name AS manager
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.id;
```

---

## Window Functions

```sql
-- Syntax
function() OVER (
    PARTITION BY col
    ORDER BY col
    ROWS/RANGE BETWEEN ... AND ...
)

-- Ranking
SELECT name, dept, salary,
    ROW_NUMBER()   OVER (PARTITION BY dept ORDER BY salary DESC) AS row_num,
    RANK()         OVER (PARTITION BY dept ORDER BY salary DESC) AS rnk,
    DENSE_RANK()   OVER (PARTITION BY dept ORDER BY salary DESC) AS dense_rnk,
    NTILE(4)       OVER (ORDER BY salary DESC)                   AS quartile,
    PERCENT_RANK() OVER (PARTITION BY dept ORDER BY salary)      AS pct_rnk
FROM employees;

-- Navigation
SELECT name, salary,
    LAG(salary,  1) OVER (ORDER BY hire_date) AS prev_salary,
    LEAD(salary, 1) OVER (ORDER BY hire_date) AS next_salary,
    FIRST_VALUE(salary) OVER w AS dept_min,
    LAST_VALUE(salary)  OVER w AS dept_max
FROM employees
WINDOW w AS (PARTITION BY dept ORDER BY salary ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING);

-- Running totals and moving averages
SELECT date, amount,
    SUM(amount)  OVER (ORDER BY date ROWS UNBOUNDED PRECEDING)  AS running_total,
    AVG(amount)  OVER (ORDER BY date ROWS 6 PRECEDING)           AS moving_avg_7d
FROM sales;
```

---

## Indexes

### Index Types

| Type | Use Case |
|------|----------|
| `B-Tree` | Default. Equality and range queries. Works with `=`, `<`, `>`, `BETWEEN`, `LIKE 'prefix%'`. |
| `Hash` | Equality only (`=`). Faster than B-Tree for pure equality. |
| `GIN` | Generalised Inverted Index. `jsonb`, arrays, full-text search. |
| `GiST` | Generalised Search Tree. Geometric types, full-text, range types. |
| `BRIN` | Block Range INdex. Very large tables with naturally ordered data (e.g. timestamps). Tiny size. |
| `SP-GiST` | Space-partitioned GiST. Good for non-balanced structures (quad-trees, k-d trees). |

### Index DDL

```sql
-- Basic
CREATE INDEX idx_users_email ON users (email);
CREATE UNIQUE INDEX idx_users_email_uniq ON users (email);

-- Multi-column (order matters — put most selective first)
CREATE INDEX idx_orders_user_date ON orders (user_id, created_at DESC);

-- Partial index (index only a subset of rows)
CREATE INDEX idx_active_users ON users (email) WHERE active = true;

-- Expression / functional index
CREATE INDEX idx_lower_email ON users (lower(email));

-- GIN index for JSONB
CREATE INDEX idx_metadata ON users USING GIN (metadata);
CREATE INDEX idx_metadata_path ON users USING GIN (metadata jsonb_path_ops);

-- Concurrent build (no table lock)
CREATE INDEX CONCURRENTLY idx_users_name ON users (name);

-- Drop
DROP INDEX idx_users_email;
DROP INDEX CONCURRENTLY idx_users_email;

-- Inspect index usage
SELECT schemaname, tablename, indexname, idx_scan, idx_tup_read
FROM pg_stat_user_indexes
ORDER BY idx_scan DESC;
```

---

## Transactions & Isolation Levels

```sql
-- Basic transaction
BEGIN;
UPDATE accounts SET balance = balance - 100 WHERE id = 1;
UPDATE accounts SET balance = balance + 100 WHERE id = 2;
COMMIT;          -- or ROLLBACK;

-- Savepoints
BEGIN;
UPDATE users SET name = 'Alice' WHERE id = 1;
SAVEPOINT sp1;
UPDATE users SET name = 'Bob' WHERE id = 2;
ROLLBACK TO SAVEPOINT sp1;   -- undo only since sp1
COMMIT;                       -- commits Alice update only

-- Set isolation level
BEGIN ISOLATION LEVEL SERIALIZABLE;
BEGIN ISOLATION LEVEL REPEATABLE READ;
BEGIN ISOLATION LEVEL READ COMMITTED;   -- default
BEGIN ISOLATION LEVEL READ UNCOMMITTED; -- same as READ COMMITTED in PostgreSQL
```

### Isolation Levels & Anomalies

| Level | Dirty Read | Non-repeatable Read | Phantom Read | Serialization Anomaly |
|-------|-----------|--------------------|--------------|-----------------------|
| Read Uncommitted | Not possible* | Possible | Possible | Possible |
| Read Committed | Not possible | Possible | Possible | Possible |
| Repeatable Read | Not possible | Not possible | Not possible* | Possible |
| Serializable | Not possible | Not possible | Not possible | Not possible |

*PostgreSQL prevents dirty reads at all levels and phantom reads at Repeatable Read.

### Locking

```sql
-- Explicit row lock
SELECT * FROM users WHERE id = 1 FOR UPDATE;
SELECT * FROM users WHERE id = 1 FOR UPDATE SKIP LOCKED;   -- skip locked rows
SELECT * FROM users WHERE id = 1 FOR SHARE;                 -- shared lock

-- Table lock
LOCK TABLE users IN ACCESS EXCLUSIVE MODE;
LOCK TABLE users IN ROW EXCLUSIVE MODE;

-- Advisory locks (application-level)
SELECT pg_advisory_lock(12345);
SELECT pg_advisory_unlock(12345);
SELECT pg_try_advisory_lock(12345);   -- non-blocking
```

---

## Views & Materialized Views

```sql
-- View (always up to date, no storage)
CREATE OR REPLACE VIEW active_users AS
SELECT id, email, name FROM users WHERE active = true;

-- Updatable view (simple views are auto-updatable)
UPDATE active_users SET name = 'Alice' WHERE id = 1;

-- Materialized view (snapshot stored on disk, must be refreshed)
CREATE MATERIALIZED VIEW monthly_revenue AS
SELECT DATE_TRUNC('month', created_at) AS month, SUM(total) AS revenue
FROM orders GROUP BY 1;

-- Refresh
REFRESH MATERIALIZED VIEW monthly_revenue;
REFRESH MATERIALIZED VIEW CONCURRENTLY monthly_revenue;  -- no lock on read

-- Drop
DROP VIEW active_users;
DROP MATERIALIZED VIEW monthly_revenue;
```

---

## Stored Procedures & Functions

```sql
-- Function (returns a value)
CREATE OR REPLACE FUNCTION get_user_count(dept_name TEXT)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    cnt INTEGER;
BEGIN
    SELECT COUNT(*) INTO cnt FROM users WHERE dept = dept_name;
    RETURN cnt;
END;
$$;

-- Call function
SELECT get_user_count('engineering');

-- Procedure (no return value, supports COMMIT inside)
CREATE OR REPLACE PROCEDURE archive_old_orders(cutoff DATE)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO orders_archive SELECT * FROM orders WHERE created_at < cutoff;
    DELETE FROM orders WHERE created_at < cutoff;
    COMMIT;
END;
$$;

-- Call procedure
CALL archive_old_orders('2023-01-01');

-- Function returning a table
CREATE OR REPLACE FUNCTION get_user_orders(uid BIGINT)
RETURNS TABLE (order_id BIGINT, total NUMERIC, status TEXT)
LANGUAGE sql
AS $$
    SELECT id, total, status FROM orders WHERE user_id = uid;
$$;

SELECT * FROM get_user_orders(42);

-- Drop
DROP FUNCTION get_user_count(TEXT);
DROP PROCEDURE archive_old_orders(DATE);
```

---

## Triggers

```sql
-- Trigger function
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;

-- Attach trigger
CREATE TRIGGER trg_users_updated_at
BEFORE UPDATE ON users
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Audit log trigger
CREATE OR REPLACE FUNCTION audit_log()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO audit (table_name, operation, old_data, new_data, changed_at)
    VALUES (TG_TABLE_NAME, TG_OP, row_to_json(OLD), row_to_json(NEW), now());
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_users_audit
AFTER INSERT OR UPDATE OR DELETE ON users
FOR EACH ROW EXECUTE FUNCTION audit_log();

-- Drop trigger
DROP TRIGGER trg_users_updated_at ON users;
```

---

## JSON / JSONB

```sql
-- Create table with JSONB
CREATE TABLE events (id SERIAL, payload JSONB);
INSERT INTO events (payload) VALUES ('{"type": "click", "user": 42, "tags": ["a","b"]}');

-- Access operators
SELECT payload -> 'user'          FROM events;   -- returns JSON (integer as JSON)
SELECT payload ->> 'type'         FROM events;   -- returns TEXT
SELECT payload -> 'tags' -> 0     FROM events;   -- first array element
SELECT payload #> '{user}'        FROM events;   -- path as JSON
SELECT payload #>> '{type}'       FROM events;   -- path as TEXT

-- Containment & existence
SELECT * FROM events WHERE payload @> '{"type": "click"}';   -- contains
SELECT * FROM events WHERE payload ? 'user';                  -- key exists
SELECT * FROM events WHERE payload ?| ARRAY['user', 'name']; -- any key exists
SELECT * FROM events WHERE payload ?& ARRAY['user', 'type']; -- all keys exist

-- Modify JSONB
UPDATE events SET payload = payload || '{"processed": true}';     -- merge
UPDATE events SET payload = payload - 'tags';                      -- remove key
UPDATE events SET payload = jsonb_set(payload, '{user}', '99');    -- set nested

-- Aggregate to JSON
SELECT jsonb_agg(row_to_json(u)) FROM users u;
SELECT json_object_agg(name, salary) FROM employees;

-- Index JSONB
CREATE INDEX ON events USING GIN (payload);
CREATE INDEX ON events USING GIN (payload jsonb_path_ops);   -- faster @> queries
CREATE INDEX ON events ((payload ->> 'type'));                -- expression index
```

---

## Full-Text Search

```sql
-- to_tsvector / to_tsquery
SELECT to_tsvector('english', 'The quick brown fox jumps');
SELECT to_tsquery('english', 'quick & fox');

-- Search
SELECT * FROM articles
WHERE to_tsvector('english', title || ' ' || body) @@ to_tsquery('english', 'postgres & index');

-- Stored tsvector column (faster)
ALTER TABLE articles ADD COLUMN search_vec TSVECTOR;
UPDATE articles SET search_vec = to_tsvector('english', title || ' ' || body);
CREATE INDEX idx_fts ON articles USING GIN (search_vec);

-- Auto-update with trigger
CREATE TRIGGER trg_articles_fts
BEFORE INSERT OR UPDATE ON articles
FOR EACH ROW EXECUTE FUNCTION
    tsvector_update_trigger(search_vec, 'pg_catalog.english', title, body);

-- Ranking results
SELECT title, ts_rank(search_vec, query) AS rank
FROM articles, to_tsquery('english', 'postgres') query
WHERE search_vec @@ query
ORDER BY rank DESC;

-- Highlighting
SELECT ts_headline('english', body, to_tsquery('postgres')) FROM articles;
```

---

## Partitioning

```sql
-- Range partitioning
CREATE TABLE orders (
    id          BIGSERIAL,
    created_at  TIMESTAMPTZ NOT NULL,
    total       NUMERIC
) PARTITION BY RANGE (created_at);

CREATE TABLE orders_2024 PARTITION OF orders
    FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');
CREATE TABLE orders_2025 PARTITION OF orders
    FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');

-- List partitioning
CREATE TABLE users (
    id      BIGSERIAL,
    region  TEXT NOT NULL
) PARTITION BY LIST (region);

CREATE TABLE users_us  PARTITION OF users FOR VALUES IN ('US', 'CA');
CREATE TABLE users_eu  PARTITION OF users FOR VALUES IN ('UK', 'DE', 'FR');

-- Hash partitioning
CREATE TABLE events (
    id      BIGSERIAL,
    user_id BIGINT
) PARTITION BY HASH (user_id);

CREATE TABLE events_p0 PARTITION OF events FOR VALUES WITH (MODULUS 4, REMAINDER 0);
CREATE TABLE events_p1 PARTITION OF events FOR VALUES WITH (MODULUS 4, REMAINDER 1);
CREATE TABLE events_p2 PARTITION OF events FOR VALUES WITH (MODULUS 4, REMAINDER 2);
CREATE TABLE events_p3 PARTITION OF events FOR VALUES WITH (MODULUS 4, REMAINDER 3);

-- Default partition (catches unmatched rows)
CREATE TABLE orders_default PARTITION OF orders DEFAULT;

-- Detach / attach partitions
ALTER TABLE orders DETACH PARTITION orders_2024;
ALTER TABLE orders ATTACH PARTITION orders_2024 FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');
```

---

## VACUUM & Maintenance

```sql
-- Manual VACUUM
VACUUM users;                  -- reclaim dead tuples
VACUUM ANALYZE users;          -- reclaim + update stats
VACUUM FULL users;             -- rewrite table, reclaim disk (locks table!)
VACUUM VERBOSE users;          -- detailed output

-- ANALYZE (update planner statistics)
ANALYZE users;
ANALYZE users (email, age);

-- REINDEX (rebuild indexes)
REINDEX TABLE users;
REINDEX INDEX idx_users_email;
REINDEX TABLE CONCURRENTLY users;   -- no lock

-- Check bloat / dead tuples
SELECT relname, n_dead_tup, n_live_tup, last_vacuum, last_autovacuum
FROM pg_stat_user_tables
ORDER BY n_dead_tup DESC;

-- Autovacuum tuning (per table)
ALTER TABLE users SET (
    autovacuum_vacuum_scale_factor = 0.01,   -- vacuum when 1% dead tuples
    autovacuum_analyze_scale_factor = 0.005
);
```

---

## Query Planning & EXPLAIN

```sql
-- Show query plan
EXPLAIN SELECT * FROM users WHERE email = 'a@b.com';

-- Show actual runtime stats
EXPLAIN ANALYZE SELECT * FROM users WHERE email = 'a@b.com';

-- Full output with buffers and settings
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT) SELECT * FROM users WHERE age > 30;

-- JSON format (for tooling)
EXPLAIN (ANALYZE, FORMAT JSON) SELECT * FROM users;
```

### Key Plan Nodes

| Node | Description |
|------|-------------|
| `Seq Scan` | Full table scan. Expected on small tables or without usable index. |
| `Index Scan` | Uses index to find rows, then fetches from heap. |
| `Index Only Scan` | All data from index (covering index). No heap access. Fastest. |
| `Bitmap Heap Scan` | Collects index matches, then fetches heap in bulk. Good for many rows. |
| `Hash Join` | Builds hash table from smaller side, probes with larger. Good for large equi-joins. |
| `Merge Join` | Merge sorted inputs. Good when both sides are already sorted. |
| `Nested Loop` | For each outer row, scan inner. Good for small outer + indexed inner. |
| `Sort` | Explicit sort node. Expensive — often indicates missing index. |
| `Aggregate` | GROUP BY / aggregate functions. |
| `Limit` | Stops after N rows. |

### Cost Model

- **cost=startup..total** — planner estimate (not milliseconds).
- **actual time=startup..total** — real execution time in ms.
- **rows** — estimated vs actual row count. Large deviation = stale statistics → run `ANALYZE`.
- **Buffers: shared hit / read** — hit = from cache, read = from disk.

---

## Roles & Privileges

```sql
-- Create roles / users
CREATE ROLE readonly;
CREATE ROLE app_user LOGIN PASSWORD 'secret';
CREATE USER admin LOGIN PASSWORD 'adminpass' SUPERUSER;

-- Grant privileges
GRANT CONNECT ON DATABASE mydb TO app_user;
GRANT USAGE ON SCHEMA public TO app_user;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO readonly;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE users TO app_user;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO app_user;

-- Grant role to user
GRANT readonly TO app_user;

-- Default privileges (for future objects)
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT SELECT ON TABLES TO readonly;

-- Revoke
REVOKE SELECT ON users FROM readonly;

-- Row-level security (RLS)
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
CREATE POLICY user_isolation ON users
    USING (id = current_setting('app.user_id')::bigint);

-- Check current user privileges
\dp users              -- in psql
SELECT * FROM information_schema.role_table_grants WHERE table_name = 'users';
```

---

## Replication

| Type | Description |
|------|-------------|
| **Streaming replication** | Primary streams WAL to standby in real time. Physical byte-for-byte copy. |
| **Logical replication** | Replicates logical changes (INSERT/UPDATE/DELETE) by publication/subscription. Table-level granularity. |
| **Synchronous replication** | Primary waits for standby to confirm WAL write before commit. Zero data loss. Higher latency. |
| **Asynchronous replication** | Primary does not wait. Possible small data loss on failover. Lower latency (default). |
| **Hot standby** | Read queries allowed on standby. |
| **Cascading replication** | Standby replicates to another standby. |

```sql
-- Logical replication setup
-- On primary:
CREATE PUBLICATION mypub FOR TABLE users, orders;

-- On replica:
CREATE SUBSCRIPTION mysub
    CONNECTION 'host=primary dbname=mydb user=replicator'
    PUBLICATION mypub;

-- Check replication lag
SELECT client_addr, state, sent_lsn, write_lsn, replay_lsn,
    (sent_lsn - replay_lsn) AS lag_bytes
FROM pg_stat_replication;
```

---

## Extensions

```sql
-- List available extensions
SELECT * FROM pg_available_extensions ORDER BY name;

-- Install
CREATE EXTENSION IF NOT EXISTS pg_trgm;       -- trigram fuzzy search
CREATE EXTENSION IF NOT EXISTS uuid-ossp;     -- UUID generation
CREATE EXTENSION IF NOT EXISTS pgcrypto;      -- encryption functions
CREATE EXTENSION IF NOT EXISTS postgis;       -- geospatial
CREATE EXTENSION IF NOT EXISTS pg_stat_statements; -- query stats
CREATE EXTENSION IF NOT EXISTS hstore;        -- key-value store
CREATE EXTENSION IF NOT EXISTS citext;        -- case-insensitive text
CREATE EXTENSION IF NOT EXISTS tablefunc;     -- crosstab / pivot

-- Drop
DROP EXTENSION pg_trgm;
```

### Trigram (fuzzy search)

```sql
CREATE EXTENSION pg_trgm;
CREATE INDEX idx_trgm_name ON users USING GIN (name gin_trgm_ops);

SELECT name, similarity(name, 'Alise') AS sim
FROM users
WHERE name % 'Alise'          -- similarity threshold
ORDER BY sim DESC;
```

---

## psql CLI — Essential Commands

```
\l                    -- list databases
\c mydb               -- connect to database
\dn                   -- list schemas
\dt                   -- list tables
\dt myschema.*        -- tables in schema
\d users              -- describe table (columns, indexes, constraints)
\d+ users             -- extended table info
\di                   -- list indexes
\dv                   -- list views
\dm                   -- list materialized views
\df                   -- list functions
\dp users             -- show privileges for table
\du                   -- list roles/users
\timing               -- toggle query timing
\x                    -- toggle expanded output (vertical display)
\e                    -- open query in $EDITOR
\i file.sql           -- execute SQL file
\o output.txt         -- pipe output to file
\copy users TO 'file.csv' CSV HEADER   -- export to CSV
\copy users FROM 'file.csv' CSV HEADER -- import from CSV
\q                    -- quit
```

---

## Key Configuration Parameters (`postgresql.conf`)

### Memory

| Parameter | Description | Typical Value |
|-----------|-------------|---------------|
| `shared_buffers` | Main data page cache. | 25% of RAM |
| `work_mem` | Per-sort / per-hash operation memory. | 4–64 MB |
| `maintenance_work_mem` | For VACUUM, CREATE INDEX, etc. | 256 MB – 1 GB |
| `effective_cache_size` | Planner estimate of OS + PG cache. | 75% of RAM |
| `wal_buffers` | WAL write buffer. | 16 MB |
| `temp_buffers` | Per-session temp table memory. | 8 MB |

### WAL & Checkpoint

| Parameter | Description |
|-----------|-------------|
| `wal_level` | `replica` (default) / `logical` (for logical replication) |
| `max_wal_size` | Max WAL before checkpoint forced (default 1 GB) |
| `checkpoint_completion_target` | Spread checkpoint I/O (default 0.9) |
| `wal_compression` | Compress WAL records to reduce I/O |
| `archive_mode` | Enable WAL archiving for PITR |

### Connections & Performance

| Parameter | Description |
|-----------|-------------|
| `max_connections` | Max concurrent connections (consider PgBouncer) |
| `random_page_cost` | Lower for SSDs (set to 1.1 for NVMe) |
| `effective_io_concurrency` | Concurrent I/O requests (set to 200 for SSDs) |
| `max_parallel_workers_per_gather` | Parallelism per query |
| `max_worker_processes` | Total background worker processes |
| `default_statistics_target` | Planner stats depth (increase to 200+ for skewed data) |
| `log_min_duration_statement` | Log queries slower than N ms |

---

## Performance & Monitoring Queries

```sql
-- Active queries
SELECT pid, now() - query_start AS duration, state, query
FROM pg_stat_activity
WHERE state != 'idle'
ORDER BY duration DESC;

-- Long-running queries
SELECT pid, query_start, now() - query_start AS runtime, query
FROM pg_stat_activity
WHERE state = 'active' AND now() - query_start > INTERVAL '30 seconds';

-- Kill a query
SELECT pg_cancel_backend(pid);    -- graceful cancel
SELECT pg_terminate_backend(pid); -- force terminate

-- Blocking locks
SELECT blocked.pid, blocked.query, blocking.pid AS blocking_pid, blocking.query AS blocking_query
FROM pg_stat_activity blocked
JOIN pg_stat_activity blocking ON blocking.pid = ANY(pg_blocking_pids(blocked.pid))
WHERE cardinality(pg_blocking_pids(blocked.pid)) > 0;

-- Table sizes
SELECT relname,
    pg_size_pretty(pg_total_relation_size(oid)) AS total,
    pg_size_pretty(pg_relation_size(oid)) AS table,
    pg_size_pretty(pg_total_relation_size(oid) - pg_relation_size(oid)) AS indexes
FROM pg_class
WHERE relkind = 'r' AND relnamespace = 'public'::regnamespace
ORDER BY pg_total_relation_size(oid) DESC;

-- Database size
SELECT pg_size_pretty(pg_database_size('mydb'));

-- Index usage stats
SELECT relname, indexrelname, idx_scan, idx_tup_read, idx_tup_fetch
FROM pg_stat_user_indexes
ORDER BY idx_scan DESC;

-- Unused indexes (candidates for removal)
SELECT schemaname, relname, indexrelname, idx_scan
FROM pg_stat_user_indexes
WHERE idx_scan = 0 AND indexrelname NOT LIKE '%pkey%'
ORDER BY pg_relation_size(indexrelid) DESC;

-- Top slow queries (requires pg_stat_statements extension)
SELECT query, calls, mean_exec_time, total_exec_time, rows
FROM pg_stat_statements
ORDER BY mean_exec_time DESC LIMIT 20;

-- Cache hit ratio (should be > 99%)
SELECT round(100.0 * blks_hit / (blks_hit + blks_read), 2) AS cache_hit_ratio
FROM pg_stat_database
WHERE datname = current_database();

-- Table bloat estimate
SELECT relname, n_dead_tup, n_live_tup,
    round(100.0 * n_dead_tup / nullif(n_live_tup + n_dead_tup, 0), 1) AS dead_pct,
    last_autovacuum
FROM pg_stat_user_tables
ORDER BY n_dead_tup DESC;
```

---

## Backup & Restore

```bash
# Logical backup (single database)
pg_dump mydb > mydb.sql
pg_dump -Fc mydb > mydb.dump           # custom compressed format
pg_dump -Fc -j 4 mydb > mydb.dump     # parallel dump (4 workers)
pg_dump -t users mydb > users.sql      # single table

# Restore logical backup
psql mydb < mydb.sql
pg_restore -Fc -d mydb mydb.dump
pg_restore -Fc -j 4 -d mydb mydb.dump  # parallel restore

# Cluster-wide backup (all databases + roles)
pg_dumpall > cluster.sql
psql -f cluster.sql postgres

# Physical backup (base backup for PITR)
pg_basebackup -h localhost -U replicator -D /backup/base -Ft -z -P

# Point-in-time recovery (PITR)
# 1. Restore base backup
# 2. Configure recovery.conf / postgresql.conf:
#    restore_command = 'cp /wal_archive/%f %p'
#    recovery_target_time = '2024-06-15 14:00:00'
# 3. Start PostgreSQL — it replays WAL to target time
```

---

## Quick Reference — Default Ports & Files

| Item | Value |
|------|-------|
| Default port | `5432` |
| Data directory | `$PGDATA` (e.g. `/var/lib/postgresql/16/main`) |
| Config file | `$PGDATA/postgresql.conf` |
| Auth config | `$PGDATA/pg_hba.conf` |
| WAL directory | `$PGDATA/pg_wal/` |
| Log directory | `/var/log/postgresql/` |
| Unix socket | `/var/run/postgresql/.s.PGSQL.5432` |

---

## Common Patterns & Tips

### Pagination

```sql
-- Offset pagination (simple, slow for large offsets)
SELECT * FROM users ORDER BY id LIMIT 20 OFFSET 100;

-- Keyset / cursor pagination (fast, consistent)
SELECT * FROM users WHERE id > :last_id ORDER BY id LIMIT 20;
```

### UPSERT Pattern

```sql
INSERT INTO counters (key, value)
VALUES ('clicks', 1)
ON CONFLICT (key) DO UPDATE SET value = counters.value + EXCLUDED.value;
```

### Soft Delete Pattern

```sql
ALTER TABLE users ADD COLUMN deleted_at TIMESTAMPTZ;
CREATE INDEX idx_users_active ON users (id) WHERE deleted_at IS NULL;

-- Soft delete
UPDATE users SET deleted_at = now() WHERE id = 1;

-- Query only active
SELECT * FROM users WHERE deleted_at IS NULL;
```

### Generated Columns

```sql
CREATE TABLE products (
    price_usd  NUMERIC,
    tax_rate   NUMERIC DEFAULT 0.2,
    price_with_tax NUMERIC GENERATED ALWAYS AS (price_usd * (1 + tax_rate)) STORED
);
```

### Sequences

```sql
CREATE SEQUENCE order_seq START 1000 INCREMENT 10;
SELECT nextval('order_seq');
SELECT currval('order_seq');
SELECT setval('order_seq', 5000);
ALTER SEQUENCE order_seq RESTART WITH 1;
```

---

*· PostgreSQL reference · postgresql.org*
