#!/usr/bin/env python3
"""
Strict guard for the tafsir-generator subagent.

Allowlist model (the only way to guarantee no loopholes):
- Write/Edit: allowed only inside `<project>/new_tafsir/`.
- Bash:       blocked entirely (the agent's tools list should also omit Bash;
              this is defense-in-depth in case the tools list is ever edited).
- Any other tool: blocked by default.

Hook contract:
- stdin: JSON payload with `tool_name` and `tool_input`.
- stdout: {"decision": "allow"} or {"decision": "block", "reason": "..."}.
- exit 0 on allow, 2 on block.
"""

import json
import os
import sys
from datetime import datetime
from pathlib import Path

PROJECT_ROOT = Path(os.environ.get("CLAUDE_PROJECT_DIR", Path(__file__).parent.parent.parent)).resolve()
ALLOWED_DIR = (PROJECT_ROOT / "new_tafsir").resolve()
LOG_DIR = PROJECT_ROOT / "logs"
LOG_FILE = LOG_DIR / "tafsir_generator_guard.log"


def log(message: str) -> None:
    try:
        LOG_DIR.mkdir(exist_ok=True)
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        with open(LOG_FILE, "a", encoding="utf-8") as f:
            f.write(f"[{timestamp}] {message}\n")
    except Exception:
        pass


def block(reason: str) -> None:
    log(f"BLOCKED: {reason}")
    print(json.dumps({"decision": "block", "reason": reason}))
    sys.exit(2)


def allow(detail: str = "") -> None:
    print(json.dumps({"decision": "allow"}))
    if detail:
        log(f"ALLOWED: {detail}")
    sys.exit(0)


def resolves_under_allowed(file_path: str) -> tuple[bool, Path]:
    """
    Resolve the provided path (following symlinks) and test whether the
    result lies inside ALLOWED_DIR. Uses resolve(strict=False) so that
    not-yet-created files are handled.
    """
    if not file_path:
        return False, Path()

    p = Path(file_path)
    if not p.is_absolute():
        p = PROJECT_ROOT / p

    try:
        resolved = p.resolve(strict=False)
    except Exception:
        return False, p

    try:
        resolved.relative_to(ALLOWED_DIR)
        return True, resolved
    except ValueError:
        return False, resolved


def main() -> None:
    try:
        payload = json.load(sys.stdin)
    except json.JSONDecodeError:
        block("tafsir-generator guard: invalid hook payload")

    tool_name = payload.get("tool_name", "")
    tool_input = payload.get("tool_input", {}) or {}

    if tool_name in ("Write", "Edit"):
        file_path = tool_input.get("file_path", "")
        ok, resolved = resolves_under_allowed(file_path)
        if ok:
            allow(f"{tool_name}: {resolved}")
        block(
            f"tafsir-generator is only permitted to {tool_name} files inside "
            f"{ALLOWED_DIR.relative_to(PROJECT_ROOT)}/. "
            f"Requested path resolved to: {resolved}"
        )

    if tool_name == "Bash":
        command = tool_input.get("command", "")
        block(
            "tafsir-generator is not permitted to run Bash. "
            f"Attempted command: {command[:200]}"
        )

    block(f"tafsir-generator guard: tool '{tool_name}' is not on the allowlist.")


if __name__ == "__main__":
    main()
