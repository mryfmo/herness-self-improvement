#!/usr/bin/env sh

# @file ci/test_telemetry_hooks.sh
# @brief Verify asynchronous session, prompt, tool, and stop telemetry hooks.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
HOOK="$ROOT/.claude/hooks/hx-telemetry.sh"
MARKERS="$ROOT/.claude/hooks/hx-correction-markers.txt"
SETTINGS="$ROOT/.claude/settings.json"
TMP=$(mktemp -d "${TMPDIR:-/tmp}/hx-telemetry-hooks.XXXXXX")
DB="$TMP/telemetry.db"
FAIL_LOG="$TMP/telemetry-failures.log"
trap 'rm -rf "$TMP"' EXIT

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

query() {
    sqlite3 -cmd ".timeout 5000" "$DB" "$1"
}

wait_for_sql() {
    expected=$1
    sql=$2
    attempt=0
    while [ "$attempt" -lt 100 ]; do
        [ "$(query "$sql")" = "$expected" ] && return
        sleep 0.02
        attempt=$((attempt + 1))
    done
    fail "timed out: $sql"
}

wait_for_failure() {
    attempt=0
    while [ "$attempt" -lt 100 ]; do
        [ -s "$FAIL_LOG" ] && return
        sleep 0.02
        attempt=$((attempt + 1))
    done
    fail "failure log was not written"
}

run_hook() {
    event=$1
    payload=$2
    printf '%s' "$payload" |
        HX_DB_PATH="$DB" HX_FAILURE_LOG="$FAIL_LOG" "$HOOK" "$event"
}

[ -x "$HOOK" ] || fail "missing executable telemetry hook"
[ -f "$MARKERS" ] || fail "missing correction markers"
[ -f "$SETTINGS" ] || fail "missing project settings"
"$ROOT/db/migrate.sh" up "$DB"

ROOT="$ROOT" python3 <<'PY'
import os
import sys

sys.path.insert(0, os.path.join(os.environ["ROOT"], "ci"))
from secret_patterns import mask_text

samples = {
    "github_token": "ghp_" + "A" * 20,
    "anthropic_key": "sk-" + "ant-" + "A" * 20,
    "aws_access_key": "AK" + "IA" + "A" * 16,
    "bearer_token": "Bear" + "er " + "A" * 20,
    "key_value_secret": "to" + "ken=" + "A" * 16,
    "jwt": "ey" + "J" + "A" * 6 + "." + "B" * 8 + "." + "C" * 8,
    "private_key_header": "-----BEGIN " + "PRIVATE KEY-----",
}
for name, secret in samples.items():
    masked, changed = mask_text(f"before {secret} after")
    assert changed, name
    assert secret not in masked, name
    assert f"[REDACTED:{name}]" in masked, name
assert mask_text("ordinary prompt") == ("ordinary prompt", False)
PY
echo "PASS: all shared secret patterns mask and benign text is unchanged"

run_hook session-start \
    '{"session_id":"session-1","cwd":"/tmp/demo'\''s","hook_event_name":"SessionStart"}'
wait_for_sql 1 "SELECT count(*) FROM hx_sessions WHERE session_id='session-1';"

prefix=ghp
dummy="${prefix}_AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
run_hook prompt-submit \
    "{\"session_id\":\"session-1\",\"cwd\":\"/tmp/demo\",\"hook_event_name\":\"UserPromptSubmit\",\"prompt\":\"keep $dummy\"}"
wait_for_sql 1 "SELECT count(*) FROM hx_prompts;"
[ "$(query "SELECT masked FROM hx_prompts LIMIT 1;")" = 1 ] || fail "masked flag"
[ "$(query "SELECT instr(content, '$dummy') FROM hx_prompts LIMIT 1;")" = 0 ] || fail "secret stored"
[ "$(query "SELECT instr(content, '[REDACTED:github_token]') > 0 FROM hx_prompts LIMIT 1;")" = 1 ] ||
    fail "redaction marker missing"
echo "PASS: both events recorded and prompt masked"

run_hook post-tool-use \
    '{"session_id":"session-1","cwd":"/tmp/demo","tool_name":"Bash","tool_response":{"success":true,"duration_ms":42,"exit_code":0,"stderr":""}}'
wait_for_sql 1 "SELECT count(*) FROM hx_tool_events WHERE tool='Bash' AND status='success' AND duration_ms=42 AND exit_code=0;"

run_hook post-tool-use \
    "{\"session_id\":\"session-1\",\"cwd\":\"/tmp/demo\",\"tool_name\":\"Bash\",\"tool_response\":{\"success\":false,\"duration_ms\":77,\"exit_code\":2,\"stderr\":\"failed $dummy $(printf '%0240s' '')\"}}"
wait_for_sql 1 "SELECT count(*) FROM hx_tool_events WHERE tool='Bash' AND status='failure' AND duration_ms=77 AND exit_code=2;"
[ "$(query "SELECT length(error_summary) <= 200 FROM hx_tool_events WHERE status='failure';")" = 1 ] ||
    fail "stderr summary exceeds 200 characters"
[ "$(query "SELECT instr(error_summary, '$dummy') FROM hx_tool_events WHERE status='failure';")" = 0 ] ||
    fail "stderr secret stored"
[ "$(query "SELECT instr(error_summary, '[REDACTED:github_token]') > 0 FROM hx_tool_events WHERE status='failure';")" = 1 ] ||
    fail "stderr redaction marker missing"
echo "PASS: successful and failed tool events record masked bounded details"

[ "$(query "SELECT count(*) FROM hx_skill_runs;")" = 0 ] ||
    fail "non-Skill tool created a skill run"

run_hook post-tool-use \
    '{"session_id":"skill-corrected","cwd":"/tmp/demo","tool_name":"Skill","tool_input":{"skill":"crit","scope":"project"},"tool_response":{"success":true}}'
wait_for_sql 1 "SELECT count(*) FROM hx_skill_runs WHERE session_id='skill-corrected' AND skill_name='crit' AND scope='project' AND outcome='success' AND corrected=0;"
run_hook prompt-submit \
    '{"session_id":"skill-corrected","cwd":"/tmp/demo","prompt":"違う、修正して"}'
wait_for_sql 1 "SELECT corrected FROM hx_skill_runs WHERE session_id='skill-corrected';"

run_hook post-tool-use \
    '{"session_id":"skill-normal","cwd":"/tmp/demo","tool_name":"Skill","tool_input":{"skill":"docs","scope":"user"},"tool_response":{"success":true}}'
wait_for_sql 1 "SELECT count(*) FROM hx_skill_runs WHERE session_id='skill-normal';"
run_hook prompt-submit \
    '{"session_id":"skill-normal","cwd":"/tmp/demo","prompt":"そのまま続けて"}'
wait_for_sql 1 "SELECT count(*) FROM hx_prompts WHERE session_id='skill-normal';"
[ "$(query "SELECT corrected FROM hx_skill_runs WHERE session_id='skill-normal';")" = 0 ] ||
    fail "normal prompt marked as correction"

run_hook post-tool-use \
    '{"session_id":"skill-expired","cwd":"/tmp/demo","tool_name":"Skill","tool_input":{"skill":"old-skill","scope":"enterprise"},"tool_response":{"success":true}}'
wait_for_sql 1 "SELECT count(*) FROM hx_skill_runs WHERE session_id='skill-expired';"
query "UPDATE hx_skill_runs SET ts=strftime('%Y-%m-%dT%H:%M:%fZ','now','-16 minutes') WHERE session_id='skill-expired';"
run_hook prompt-submit \
    '{"session_id":"skill-expired","cwd":"/tmp/demo","prompt":"redo that"}'
wait_for_sql 1 "SELECT count(*) FROM hx_prompts WHERE session_id='skill-expired';"
[ "$(query "SELECT corrected FROM hx_skill_runs WHERE session_id='skill-expired';")" = 0 ] ||
    fail "expired skill run marked as correction"

run_hook post-tool-use \
    '{"session_id":"skill-override","cwd":"/tmp/demo","tool_name":"Skill","tool_input":{"skill":"unknown-scope"},"tool_response":{"success":true}}'
wait_for_sql 1 "SELECT count(*) FROM hx_skill_runs WHERE session_id='skill-override' AND scope='unknown';"
query "UPDATE hx_skill_runs SET ts=strftime('%Y-%m-%dT%H:%M:%fZ','now','-16 minutes') WHERE session_id='skill-override';"
printf '%s' '{"session_id":"skill-override","cwd":"/tmp/demo","prompt":"fix that"}' |
    HX_DB_PATH="$DB" HX_FAILURE_LOG="$FAIL_LOG" HX_CORRECTION_WINDOW_MIN=30 \
        "$HOOK" prompt-submit
wait_for_sql 1 "SELECT corrected FROM hx_skill_runs WHERE session_id='skill-override';"

run_hook post-tool-use \
    '{"session_id":"skill-failure","cwd":"/tmp/demo","tool_name":"Skill","tool_input":{"skill":"broken","scope":"project"},"tool_response":{"success":false,"exit_code":1}}'
wait_for_sql 1 "SELECT count(*) FROM hx_skill_runs WHERE session_id='skill-failure' AND skill_name='broken' AND outcome='failure' AND corrected=0;"
echo "PASS: skill runs record outcomes, scope fallback, and bounded corrections"

run_hook stop '{"session_id":"session-1","cwd":"/tmp/demo"}'
wait_for_sql 1 "SELECT count(*) FROM hx_sessions WHERE session_id='session-1' AND status='completed' AND ended_at IS NOT NULL;"
run_hook stop '{"session_id":"stop-without-start","cwd":"/tmp/demo"}'
wait_for_sql 1 "SELECT count(*) FROM hx_sessions WHERE session_id='stop-without-start' AND status='completed' AND ended_at IS NOT NULL;"
echo "PASS: stop completes existing and missing sessions"

run_hook subagent-stop '{"session_id":"session-1","cwd":"/tmp/demo","agent_id":"worker-1"}'
wait_for_sql 1 "SELECT count(*) FROM hx_tool_events WHERE session_id='session-1' AND tool='subagent' AND status='success';"
echo "PASS: subagent stop records a tool event"

printf '%s' '{"session_id":"session-1","cwd":"/tmp/demo","tool_name":"Bash","tool_response":{"success":false}}' |
    HX_DB_PATH="$TMP/missing/db.sqlite" HX_FAILURE_LOG="$FAIL_LOG" \
        "$HOOK" post-tool-use
wait_for_failure

run_hook prompt-submit \
    '{"session_id":"session-1","cwd":"/tmp/demo","prompt":"recovery"}'
wait_for_sql 1 "SELECT count(*) FROM hx_audit WHERE event='telemetry.failures.recovered' AND detail='{\"failures\":1}';"
[ ! -s "$FAIL_LOG" ] || fail "failure log was not cleared"
echo "PASS: failure is best-effort and recovered count is audited"

p95=$(
    HOOK="$HOOK" DB="$DB" FAIL_LOG="$FAIL_LOG" python3 <<'PY'
import json
import os
import subprocess
import time

durations = []
env = os.environ | {
    "HX_DB_PATH": os.environ["DB"],
    "HX_FAILURE_LOG": os.environ["FAIL_LOG"],
}
for i in range(20):
    payload = json.dumps({
        "session_id": f"latency-{i}",
        "cwd": "/tmp/demo",
        "tool_name": "Skill",
        "tool_input": {"skill": f"latency-skill-{i}", "scope": "project"},
        "tool_response": {"success": True},
    })
    started = time.perf_counter_ns()
    result = subprocess.run(
        [os.environ["HOOK"], "post-tool-use"],
        input=payload,
        text=True,
        env=env,
        check=False,
    )
    if result.returncode:
        raise SystemExit(f"hook returned {result.returncode}")
    durations.append((time.perf_counter_ns() - started) / 1_000_000)
durations.sort()
print(f"{durations[18]:.3f}")
PY
)
python3 - "$p95" <<'PY'
import sys

value = float(sys.argv[1])
if value >= 100:
    raise SystemExit(f"p95 {value:.3f}ms is not under 100ms")
PY
wait_for_sql 1 "SELECT count(*) >= 25 FROM hx_skill_runs;"
echo "PASS: hook invocation p95=${p95}ms (<100ms)"

python3 - "$SETTINGS" <<'PY'
import json
import sys

settings = json.load(open(sys.argv[1], encoding="utf-8"))
expected = {
    "SessionStart": "session-start",
    "UserPromptSubmit": "prompt-submit",
    "PostToolUse": "post-tool-use",
    "Stop": "stop",
    "SubagentStop": "subagent-stop",
}
for event, subcommand in expected.items():
    hooks = settings["hooks"][event]
    commands = [hook["command"] for group in hooks for hook in group["hooks"]]
    assert any("hx-telemetry.sh" in command and subcommand in command for command in commands)
PY
echo "PASS: project settings register all five lifecycle hooks"
