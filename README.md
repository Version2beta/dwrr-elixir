# dwrr-elixir

Stage-2 spec-loop kit over the completed stage-1 core. Release README/examples
remain the T24 implementation target; this is not a published release.

## Apply and run the stage-2 kit (owner only)

Already applied over audited stage-1 HEAD `7205252` on
`spec-loop/stage2-preparation`. Review SPEC Part 2, tasks.json and
[verification](docs/STAGE2-VERIFICATION.md) first. T01–T21 remain unchanged;
the old T22 whole-tree gate was replaced by seven new tasks T22–T27 and T29.
T28 is deliberately absent: CI is complete and protected, not a coding task.
Properties, the naive oracle and CI identity check are protected preparation assets.

Exact judge expectations require installed Elixir 1.20.4 / OTP29. Library minimum
1.18/27 is not proven by that runtime. CI minimum/current jobs are not executed
by preparation. Requires Python3, bash, git, jq, timeout (or gtimeout), Pi with
owner-authorized access/spending, and approved StreamData test dependency.
Do not start with unrelated edits. Only the owner may commit this baseline and
then authorize model calls, loop commits and discards of attempt-owned edits.

```sh
cd ~/Development/dwrr-elixir
test "$(git -C ../dwrr-spec rev-parse HEAD)" = 8a0e3cf9ae860ba207213590c00feeb822bdd8f2
test "$(git branch --show-current)" = spec-loop/stage2-preparation
MIX_ENV=test mix deps.get --check-locked
git status --short
# Review all tracked AND new files; do not include .loop/ or private source.
git add .
git diff --cached --stat
git commit -m "Add verified stage-2 spec-loop kit"
test -z "$(git status --porcelain)"
mkdir -p .loop
set -o pipefail
JUDGE_TIMEOUT=300 bash scripts/loop.sh 2>&1 | tee .loop/stage2-console.log
```

Unchanged pinned defaults (inspection only; no kit overrides):

```text
cheap: pi --provider anthropic --model claude-haiku-5-5 --thinking high --print --no-session
strong: pi --provider openai-codex --model gpt-6.1-sol --thinking high --print --no-session
strongest: pi --provider openai-codex --model gpt-6.1-sol --thinking max --print --no-session
```

Inspect any owner environment overrides yourself. Defaults: 60 iterations, four
attempts per task, 1200s coder timeout, 300s per judge command. The loop commits
on this branch. `.loop/loop.log` records exact coder commands, `.loop/coder.*.log`
holds output and `.loop/notes.*` discarded notes; `STOP` names an exhausted task.
Keep ignored logs for review; do not blindly rerun STOP. Preparation invokes no
coder, stages/commits nothing, publishes nothing and changes no installed skill.

Release README prose and examples remain the T24 task.
