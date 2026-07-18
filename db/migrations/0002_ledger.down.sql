DROP TRIGGER IF EXISTS hx_tasks_state_transition;
DROP INDEX IF EXISTS hx_task_messages_task_ts_idx;
DROP INDEX IF EXISTS hx_tasks_state_updated_idx;
DROP TABLE IF EXISTS hx_task_messages;
DROP TABLE IF EXISTS hx_tasks;
