CREATE VIEW IF NOT EXISTS hx_v_skill_daily AS
WITH skill_durations AS (
    SELECT session_id, ts, AVG(duration_ms) AS avg_duration_ms
    FROM hx_tool_events
    WHERE tool = 'Skill' AND duration_ms IS NOT NULL
    GROUP BY session_id, ts
)
SELECT
    date(skill.ts) AS metric_date,
    skill.skill_name,
    COUNT(*) AS run_count,
    SUM(skill.outcome = 'success') AS success_count,
    ROUND(1.0 * SUM(skill.outcome = 'success') / COUNT(*), 6) AS success_rate,
    SUM(skill.corrected = 1) AS correction_count,
    ROUND(1.0 * SUM(skill.corrected = 1) / COUNT(*), 6) AS correction_rate,
    ROUND(AVG(duration.avg_duration_ms), 3) AS avg_duration_ms
FROM hx_skill_runs AS skill
LEFT JOIN skill_durations AS duration
    ON duration.session_id = skill.session_id AND duration.ts = skill.ts
GROUP BY date(skill.ts), skill.skill_name;

CREATE VIEW IF NOT EXISTS hx_v_tool_daily AS
SELECT
    date(ts) AS metric_date,
    tool,
    COUNT(*) AS execution_count,
    SUM(status = 'failure') AS failure_count,
    ROUND(1.0 * SUM(status = 'failure') / COUNT(*), 6) AS failure_rate
FROM hx_tool_events
GROUP BY date(ts), tool;

CREATE VIEW IF NOT EXISTS hx_v_prompt_repetition_daily AS
WITH repeated AS (
    SELECT date(ts) AS metric_date, content, COUNT(*) AS occurrences
    FROM hx_prompts
    WHERE role = 'user'
    GROUP BY date(ts), content
    HAVING COUNT(*) > 1
),
repeat_totals AS (
    SELECT metric_date, SUM(occurrences - 1) AS repeated_prompt_count
    FROM repeated
    GROUP BY metric_date
),
session_totals AS (
    SELECT repeated.metric_date, COUNT(DISTINCT prompt.session_id) AS distinct_session_count
    FROM repeated
    JOIN hx_prompts AS prompt
        ON date(prompt.ts) = repeated.metric_date
       AND prompt.role = 'user'
       AND prompt.content = repeated.content
    GROUP BY repeated.metric_date
)
SELECT
    repeat_totals.metric_date,
    repeat_totals.repeated_prompt_count,
    session_totals.distinct_session_count
FROM repeat_totals
JOIN session_totals USING (metric_date);
