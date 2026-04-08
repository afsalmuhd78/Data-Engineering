# PostgreSQL Setup and Administration Cheat Sheet


## 1. System & Login Commands (Ubuntu Terminal)

```
# Install PostgreSQL
sudo apt update
sudo apt install postgresql postgresql-contrib

# Enable and start the service
sudo systemctl enable --now postgresql

# Log in as the superuser (postgres)
sudo -u postgres psql

# Log in as a specific user to a specific database (forces password prompt)
psql -U app_readwrite_user -h localhost -d company_db
```

## 2. Basic Setup (Run inside psql)

```
# Create database
CREATE DATABASE company_db;


# Connect to database (MUST DO THIS BEFORE GRANTING PERMISSIONS)
\c company_db


# Create group roles (No login)
CREATE ROLE admin_group;
CREATE ROLE readwrite_group;
CREATE ROLE readonly_group;


# Create user roles (With login)
CREATE ROLE app_admin_user WITH LOGIN PASSWORD 'Password123!';
CREATE ROLE app_readwrite_user WITH LOGIN PASSWORD 'Password456!';

```

## 3. Managing Group Permissions

```
# --- ADMIN GROUP ---
# Grant server-level privileges
ALTER ROLE admin_group WITH CREATEDB CREATEROLE;


# Grant database-level privileges
GRANT ALL PRIVILEGES ON DATABASE company_db TO admin_group;
GRANT ALL PRIVILEGES ON SCHEMA public TO admin_group;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO admin_group;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO admin_group;


# --- READ/WRITE GROUP (No Delete) ---
GRANT CONNECT ON DATABASE company_db TO readwrite_group;
GRANT USAGE, CREATE ON SCHEMA public TO readwrite_group;
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO readwrite_group;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO readwrite_group;


# Apply to future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE ON TABLES TO readwrite_group;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE, SELECT ON SEQUENCES TO readwrite_group;

# --- READ-ONLY GROUP ---
GRANT CONNECT ON DATABASE company_db TO readonly_group;
GRANT USAGE ON SCHEMA public TO readonly_group;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO readonly_group;


# Apply to future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO readonly_group;
```

## 4. Modifying Roles & Permissions

```
# Assign a user to a group
GRANT admin_group TO app_admin_user;


# Remove a user from a group
REVOKE readwrite_group FROM app_admin_user;


# Rename a user (or group)
ALTER ROLE app_readwirte_user RENAME TO app_readwrite_user;


# Reset/Change a user's password
ALTER ROLE app_readwrite_user WITH PASSWORD 'NewPassword789!';


# Delete/Drop a role or group
DROP ROLE ddl_admin_group;


# Revoke a specific privilege (e.g., Delete) from existing tables
REVOKE DELETE ON ALL TABLES IN SCHEMA public FROM readwrite_group;


# Revoke a specific privilege from future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE DELETE ON TABLES FROM readwrite_group;


# Transfer table ownership (Required for another user to ALTER/DROP it)
ALTER TABLE existing_table_name OWNER TO new_owner_username;

```

## 5. Inspection & Meta-Commands

```
\c dbname     # Connect to a different database
\conninfo     # Show current connection info
\l            # List all databases
\du           # List all roles (users & groups)
\dt           # List all tables in current database
\dp           # List table access privileges
\d tablename  # Describe specific table structure
\q            # Quit psql
\pset pager off # Turn off the pager (prevents having to press 'q' to exit long lists)
```

## 6. Useful Admin Queries

```
# Check which users belong to which groups

SELECT 
    g.rolname AS "Group Name",
    u.rolname AS "User Name"
FROM pg_catalog.pg_auth_members m
JOIN pg_catalog.pg_roles g ON (m.roleid = g.oid)
JOIN pg_catalog.pg_roles u ON (m.member = u.oid)
ORDER BY g.rolname;


# Check password hashes (Must be logged in as superuser)
SELECT usename, passwd FROM pg_shadow;


# View active database connections
SELECT pid, usename, datname, client_addr, state FROM pg_stat_activity;

```