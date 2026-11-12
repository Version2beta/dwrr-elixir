# dwrr-elixir

Stage-1 spec-loop kit for a pure Elixir deficit weighted round robin scheduler.
**This checkout contains stubs, not a working release.** No loop has run.

## Need and scope

Allocate a shared consumer's service by declared item cost and queue quantum,
without coupling scheduling to execution or a process. Hex name `dwrr`, module
`Dwrr`. Elixir >=1.18, OTP >=27; no runtime dependencies. Driver uses built-in JSON.
Stage 1 covers the pure core and conformance driver; release docs, properties and
minimal GenServer wrapper belong to stage 2.

## Apply and run this kit

The kit is already applied in this directory on `spec-loop/framing`, with no
commits created by preparation. Review `SPEC.md`, `tasks.json`, protected paths,
and `docs/STAGE1-VERIFICATION.md` first. The reference is private, outside this
checkout; it is not part of the kit or a source for the coder.

Requirements: the installed Elixir **1.20.4 / OTP 29** for these exact ExUnit
summary expectations, Python >=3.9, bash, git, jq, timeout (or gtimeout), and Pi
with owner-authorized provider access/spending. The library's minimum is 1.18/27;
this kit's judge summaries were verified with 1.20.4, not claimed portable to 1.18.
The sibling `../dwrr-spec` must be at `8a0e3cf9ae860ba207213590c00feeb822bdd8f2`.
No network/dependencies are needed for tests. `.wtha/` is globally ignored;
`.loop/`, `_build/`, `deps/` are kit ignores.

The owner, not the preparation assistant, runs these commands. They explicitly
create a committed baseline and authorize the loop's model calls, commits and
discard of **attempt-owned** work. Do not start with any unrelated edits. Set
provider spending limits first; the loop is not a sandbox. Review the exact
commands in `scripts/loop.sh`; this kit does not set or override them.

```sh
cd ~/Development/dwrr-elixir
test "$(git -C ../dwrr-spec rev-parse HEAD)" = 8a0e3cf9ae860ba207213590c00feeb822bdd8f2
git switch -c spec-loop/stage1
# Review ALL files before including them in the baseline.
git status --short
git add .
git diff --cached --stat
git commit -m "Add verified stage-1 spec-loop kit"
test -z "$(git status --porcelain)"
mkdir -p .loop
set -o pipefail
JUDGE_TIMEOUT=300 bash scripts/loop.sh 2>&1 | tee .loop/stage1-console.log
```

The unchanged loop defaults are:

```text
cheap:     pi --provider anthropic --model claude-haiku-5-5 --thinking high --print --no-session
strong:    pi --provider openai-codex --model gpt-6.1-sol --thinking high --print --no-session
strongest: pi --provider openai-codex --model gpt-6.1-sol --thinking max --print --no-session
```

They are shown for inspection, **not assigned by this kit**. Pre-existing owner
environment overrides would change them; inspect/unset those yourself if needed.
Default 60 iterations, four attempts per task, coder timeout 1200s, each judge
command timeout 300s. Verified reference timings are in the verification report.

The loop commits on your branch; `.loop/loop.log` records each exact coder
command, `.loop/coder.*.log` holds output, `.loop/notes.*` retains failed notes,
and `STOP` names an exhausted task. Keep `.loop/` for review and shakedown timing;
it is ignored and must not be committed. Do not blindly rerun after STOP.
Return for stage-1 review before proceeding to stage 2. We will inspect all code
for test-specific shortcuts and check that every protected file stayed unchanged.

## API at a glance (after implementation)

```elixir
s = Dwrr.new(2)
{:ok, s} = Dwrr.set_quantum(s, 0, 2)
{:ok, s} = Dwrr.enqueue(s, 0, [%Dwrr.Item{value: :job, cost: 2}])
{:ok, [%Dwrr.Scheduled{queue: 0, value: :job, cost: 2}], s} = Dwrr.take(s, 1)
```

Other return shapes: `add_queue(s)` is `{index, s2}`; `remove_queue(s)` is `s2`.
`remove_head`/`drain_queue` return `{:ok, value, s2}`. Tagged errors omit state;
keep the original scheduler. Type faults raise ArgumentError. Thread successful
returned states; this core neither executes work nor coordinates callers.

## Check it yourself

After the loop (not a claim about these stubs):

```sh
bash scripts/loop.sh --check
mix format --check-formatted
MIX_ENV=test mix compile --warnings-as-errors
MIX_ENV=test mix test --warnings-as-errors --no-color
python3 ../dwrr-spec/tools/replay.py --driver 'env MIX_ENV=test mix run --no-compile --no-start scripts/conformance_driver.exs'
python3 ../dwrr-spec/tools/check_driver.py --driver 'env MIX_ENV=test mix run --no-compile --no-start scripts/conformance_driver.exs'
```

Native tests exercise all seven vendored corpus files directly through Dwrr,
without the driver adapter. Original cases and hashes are in
`test/fixtures/dwrr-spec/PROVENANCE.json`. The independent external tools check
all recorded responses plus strict protocol, interactive flushing and exit codes.
The shared source is a draft spec 0.1.1; passing this corpus is not a proof of all
possible sequences or a substitute for stage-2 differential properties.

## Colophon

MIT. Copyright (c) 2026 M. Robert Martin. Repository intended for
https://github.com/Version2beta/dwrr-elixir. No publication, push or tag in this run.
