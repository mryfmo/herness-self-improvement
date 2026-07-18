DROP TRIGGER IF EXISTS hx_audit_no_delete;
DROP TRIGGER IF EXISTS hx_audit_no_update;
DROP TRIGGER IF EXISTS hx_skill_runs_fts_au;
DROP TRIGGER IF EXISTS hx_skill_runs_fts_ad;
DROP TRIGGER IF EXISTS hx_skill_runs_fts_ai;
DROP TRIGGER IF EXISTS hx_prompts_fts_au;
DROP TRIGGER IF EXISTS hx_prompts_fts_ad;
DROP TRIGGER IF EXISTS hx_prompts_fts_ai;

DROP TABLE IF EXISTS hx_skill_runs_fts;
DROP TABLE IF EXISTS hx_prompts_fts;
DROP TABLE IF EXISTS hx_skill_runs;
DROP TABLE IF EXISTS hx_tool_events;
DROP TABLE IF EXISTS hx_prompts;
DROP TABLE IF EXISTS hx_patterns;
DROP TABLE IF EXISTS hx_audit;
DROP TABLE IF EXISTS hx_sessions;
