CREATE TABLE IF NOT EXISTS hx_sessions (
    session_id TEXT PRIMARY KEY,
    agent_type TEXT NOT NULL,
    project TEXT NOT NULL,
    started_at TEXT NOT NULL,
    ended_at TEXT,
    status TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS hx_prompts (
    id INTEGER PRIMARY KEY,
    session_id TEXT NOT NULL REFERENCES hx_sessions(session_id) ON DELETE CASCADE,
    ts TEXT NOT NULL,
    role TEXT NOT NULL,
    content TEXT NOT NULL,
    masked INTEGER NOT NULL DEFAULT 0 CHECK (masked IN (0, 1))
);

CREATE TABLE IF NOT EXISTS hx_tool_events (
    id INTEGER PRIMARY KEY,
    session_id TEXT NOT NULL REFERENCES hx_sessions(session_id) ON DELETE CASCADE,
    ts TEXT NOT NULL,
    tool TEXT NOT NULL,
    status TEXT NOT NULL,
    duration_ms INTEGER,
    exit_code INTEGER,
    error_summary TEXT
);

CREATE TABLE IF NOT EXISTS hx_skill_runs (
    id INTEGER PRIMARY KEY,
    session_id TEXT NOT NULL REFERENCES hx_sessions(session_id) ON DELETE CASCADE,
    ts TEXT NOT NULL,
    skill_name TEXT NOT NULL,
    scope TEXT NOT NULL,
    outcome TEXT NOT NULL,
    corrected INTEGER NOT NULL DEFAULT 0 CHECK (corrected IN (0, 1))
);

CREATE TABLE IF NOT EXISTS hx_patterns (
    id INTEGER PRIMARY KEY,
    detected_at TEXT NOT NULL,
    cluster_key TEXT NOT NULL,
    template TEXT NOT NULL,
    freq INTEGER NOT NULL,
    fail_rate REAL NOT NULL,
    avg_duration_ms REAL NOT NULL,
    score REAL NOT NULL,
    artefact_kind TEXT,
    state TEXT NOT NULL,
    reason TEXT
);

CREATE TABLE IF NOT EXISTS hx_audit (
    id INTEGER PRIMARY KEY,
    ts TEXT NOT NULL,
    actor TEXT NOT NULL,
    event TEXT NOT NULL,
    ref TEXT,
    detail TEXT
);

CREATE VIRTUAL TABLE IF NOT EXISTS hx_prompts_fts USING fts5(
    content,
    content='hx_prompts',
    content_rowid='id'
);

CREATE VIRTUAL TABLE IF NOT EXISTS hx_skill_runs_fts USING fts5(
    skill_name,
    outcome,
    content='hx_skill_runs',
    content_rowid='id'
);

CREATE TRIGGER IF NOT EXISTS hx_prompts_fts_ai AFTER INSERT ON hx_prompts BEGIN
    INSERT INTO hx_prompts_fts(rowid, content) VALUES (new.id, new.content);
END;

CREATE TRIGGER IF NOT EXISTS hx_prompts_fts_ad AFTER DELETE ON hx_prompts BEGIN
    INSERT INTO hx_prompts_fts(hx_prompts_fts, rowid, content)
    VALUES ('delete', old.id, old.content);
END;

CREATE TRIGGER IF NOT EXISTS hx_prompts_fts_au AFTER UPDATE ON hx_prompts BEGIN
    INSERT INTO hx_prompts_fts(hx_prompts_fts, rowid, content)
    VALUES ('delete', old.id, old.content);
    INSERT INTO hx_prompts_fts(rowid, content) VALUES (new.id, new.content);
END;

CREATE TRIGGER IF NOT EXISTS hx_skill_runs_fts_ai AFTER INSERT ON hx_skill_runs BEGIN
    INSERT INTO hx_skill_runs_fts(rowid, skill_name, outcome)
    VALUES (new.id, new.skill_name, new.outcome);
END;

CREATE TRIGGER IF NOT EXISTS hx_skill_runs_fts_ad AFTER DELETE ON hx_skill_runs BEGIN
    INSERT INTO hx_skill_runs_fts(hx_skill_runs_fts, rowid, skill_name, outcome)
    VALUES ('delete', old.id, old.skill_name, old.outcome);
END;

CREATE TRIGGER IF NOT EXISTS hx_skill_runs_fts_au AFTER UPDATE ON hx_skill_runs BEGIN
    INSERT INTO hx_skill_runs_fts(hx_skill_runs_fts, rowid, skill_name, outcome)
    VALUES ('delete', old.id, old.skill_name, old.outcome);
    INSERT INTO hx_skill_runs_fts(rowid, skill_name, outcome)
    VALUES (new.id, new.skill_name, new.outcome);
END;

CREATE TRIGGER IF NOT EXISTS hx_audit_no_update BEFORE UPDATE ON hx_audit BEGIN
    SELECT RAISE(ABORT, 'hx_audit is append-only');
END;

CREATE TRIGGER IF NOT EXISTS hx_audit_no_delete BEFORE DELETE ON hx_audit BEGIN
    SELECT RAISE(ABORT, 'hx_audit is append-only');
END;
