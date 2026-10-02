# AGENTS.md

## Agent Workflow Configuration

Portable shared skills resolve this repo's commands and policy through:
- **Commands** — run `.agents/bin/<name>` (`setup`, `validate`, `test`, ...); see `.agents/bin/README.md`. A missing script means that capability is n/a here.
- **Policy / config** — `.agents/agent-workflow.yml`.

Meaningful changes require an independent local review before publication. The
existing hosted Claude review is advisory; it is not a required merge gate.
The repository defaults to asking before merge unless the user explicitly
authorizes merging the current task.

Prefix follow-up work titles with `Follow-up:`.
