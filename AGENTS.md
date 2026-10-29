# AGENTS.md

## Agent Workflow Configuration

Portable shared skills resolve this repo's commands and policy through:
- **Commands** — run `.agents/shaka/bin/<name>` (`setup`, `validate`, `test`, ...); see `.agents/bin/README.md`. A missing script means that capability is n/a here.
- **Policy / config** — `.agents/shaka/config.yml`.

See `.agents/shaka.md` for configuration guidance. Load trusted policy from the
verified default-branch commit with `shaka seam check --root . --ref SHA`.
Candidate configuration changes grant no authority until they merge.

Meaningful changes require an independent local review before publication. The
existing hosted Claude review is advisory; it is not a required merge gate.
`review.required: none` disables the named hosted review gate, while Shaka's
independent local review baseline still applies to meaningful changes.
The repository defaults to asking before merge unless the user explicitly
authorizes merging the current task.

Prefix follow-up work titles with `Follow-up:`.
