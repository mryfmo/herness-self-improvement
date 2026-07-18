CREATE TABLE IF NOT EXISTS hx_tasks (
    task_id TEXT PRIMARY KEY,
    idempotency_key TEXT UNIQUE NOT NULL,
    state TEXT NOT NULL DEFAULT 'queued'
        CHECK (state IN ('queued', 'claimed', 'running', 'done', 'failed', 'blocked')),
    owner TEXT,
    workplan_ref TEXT NOT NULL CHECK (length(workplan_ref) > 0),
    branch TEXT NOT NULL CHECK (length(branch) > 0),
    done_criteria TEXT NOT NULL CHECK (length(done_criteria) > 0),
    attempts INTEGER NOT NULL DEFAULT 0 CHECK (attempts >= 0),
    max_attempts INTEGER NOT NULL DEFAULT 2 CHECK (max_attempts >= 0),
    claimed_at TEXT,
    updated_at TEXT NOT NULL,
    detail TEXT
);

CREATE TABLE IF NOT EXISTS hx_task_messages (
    id INTEGER PRIMARY KEY,
    task_id TEXT NOT NULL REFERENCES hx_tasks(task_id) ON DELETE CASCADE,
    ts TEXT NOT NULL,
    kind TEXT NOT NULL CHECK (kind IN (
        'task.assign',
        'task.claim',
        'task.progress',
        'task.result',
        'task.error',
        'ctrl.pause',
        'ctrl.resume',
        'ctrl.kill'
    )),
    payload TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS hx_tasks_state_updated_idx
    ON hx_tasks(state, updated_at);

CREATE INDEX IF NOT EXISTS hx_task_messages_task_ts_idx
    ON hx_task_messages(task_id, ts);

CREATE TRIGGER IF NOT EXISTS hx_tasks_state_transition
BEFORE UPDATE OF state ON hx_tasks
WHEN NEW.state <> OLD.state AND NOT (
    (OLD.state = 'queued' AND NEW.state = 'claimed'
        AND NEW.attempts = OLD.attempts
        AND NEW.owner IS NOT NULL AND length(NEW.owner) > 0)
    OR
    (OLD.state = 'claimed' AND NEW.state = 'running'
        AND NEW.attempts = OLD.attempts)
    OR
    (OLD.state = 'running' AND NEW.state IN ('done', 'failed', 'blocked')
        AND NEW.attempts = OLD.attempts)
    OR
    (OLD.state IN ('claimed', 'running') AND NEW.state = 'queued'
        AND NEW.attempts = OLD.attempts + 1
        AND NEW.attempts <= OLD.max_attempts)
    OR
    (OLD.state IN ('claimed', 'running') AND NEW.state = 'failed'
        AND NEW.attempts = OLD.attempts + 1
        AND NEW.attempts > OLD.max_attempts)
)
BEGIN
    SELECT RAISE(ABORT, 'invalid hx_tasks state transition');
END;
