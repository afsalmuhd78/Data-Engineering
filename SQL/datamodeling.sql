-- ==============================================================================
-- PHASE 1: CUSTOM TYPES & FUNCTIONS
-- (Must be created first so tables can use them)
-- ==============================================================================

-- 1. Create Enums for strict data integrity
CREATE TYPE issue_status AS ENUM (
    'backlog', 'todo', 'in_progress', 'in_review', 'done', 'canceled'
);

CREATE TYPE issue_priority AS ENUM (
    'low', 'medium', 'high', 'urgent'
);

-- 2. Create the reusable function to auto-update the 'updated_at' timestamp
CREATE OR REPLACE FUNCTION trigger_set_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- ==============================================================================
-- PHASE 2: BASE TABLES
-- (Tables that do not depend on any other tables)
-- ==============================================================================

-- 3. Users Table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE DEFAULT NULL
);

-- 4. Projects Table
CREATE TABLE projects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    key VARCHAR(10) UNIQUE NOT NULL, -- e.g., 'ENG', 'MKT'
    description TEXT,
    owner_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE DEFAULT NULL
);


-- ==============================================================================
-- PHASE 3: CORE & RELATIONAL TABLES
-- (Tables that depend on Users and Projects)
-- ==============================================================================

-- 5. Issues Table (The core of the tracker)
CREATE TABLE issues (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    
    -- The numerical part of the ID (e.g., the '123' in 'ENG-123')
    project_sequence_id INTEGER NOT NULL, 
    
    title VARCHAR(255) NOT NULL,
    description TEXT,
    
    status issue_status NOT NULL DEFAULT 'backlog',
    priority issue_priority NOT NULL DEFAULT 'medium',
    
    reporter_id UUID NOT NULL REFERENCES users(id),
    assignee_id UUID REFERENCES users(id) ON DELETE SET NULL,
    
    -- Self-referencing FK for Epics -> Tasks -> Subtasks
    parent_id UUID REFERENCES issues(id) ON DELETE CASCADE,
    
    -- NoSQL JSON capabilities for custom user-defined fields
    custom_fields JSONB DEFAULT '{}'::jsonb, 
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE DEFAULT NULL,
    
    -- Ensure project keys are unique per project (only one ENG-123 can exist)
    UNIQUE (project_id, project_sequence_id)
);

-- 6. Issue Links Table (For blocking/blocked-by relationships)
CREATE TABLE issue_links (
    source_issue_id UUID NOT NULL REFERENCES issues(id) ON DELETE CASCADE,
    target_issue_id UUID NOT NULL REFERENCES issues(id) ON DELETE CASCADE,
    relation_type VARCHAR(50) NOT NULL, -- e.g., 'blocks', 'duplicates'
    
    PRIMARY KEY (source_issue_id, target_issue_id),
    
    -- Prevent an issue from being linked to itself
    CHECK (source_issue_id != target_issue_id) 
);

-- 7. Comments Table
CREATE TABLE comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    issue_id UUID NOT NULL REFERENCES issues(id) ON DELETE CASCADE,
    author_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    body TEXT NOT NULL,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE DEFAULT NULL
);


-- ==========================================
-- 1. FOREIGN KEY INDEXES (Standard B-Tree)
-- ==========================================
-- Essential for fast API filtering and JOINs
CREATE INDEX idx_issues_project_id ON issues(project_id);
CREATE INDEX idx_issues_assignee_id ON issues(assignee_id);
CREATE INDEX idx_issues_reporter_id ON issues(reporter_id);
CREATE INDEX idx_issues_parent_id ON issues(parent_id);

CREATE INDEX idx_projects_owner_id ON projects(owner_id);
CREATE INDEX idx_comments_issue_id ON comments(issue_id);

-- ==========================================
-- 2. PARTIAL INDEXES (For Soft Deletes)
-- ==========================================
-- Only index active issues. Ignore the deleted ones to save memory.
CREATE INDEX idx_active_issues ON issues(project_id, status) 
WHERE deleted_at IS NULL;

-- ==========================================
-- 3. JSONB GIN INDEX
-- ==========================================
-- Allows ultra-fast querying inside the custom_fields JSON object
CREATE INDEX idx_issues_custom_fields ON issues USING GIN (custom_fields);

-- ==========================================
-- 4. TEXT SEARCH OPTIMIZATION
-- ==========================================
-- Enable the trigram extension (requires superuser privileges)
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Create a GIN index using trigrams on the issue title for fast 'ILIKE' searches
CREATE INDEX idx_issues_title_search ON issues USING GIN (title gin_trgm_ops);

