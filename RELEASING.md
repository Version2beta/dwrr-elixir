# RELEASING

Owner procedure for releasing `dwrr` 0.1.0. This document is not authorization.
Each step that publishes, tags or pushes needs explicit owner approval at the time
it is run. The historical package procedure below records no publication; it
describes the original release preparation, not permission to overwrite the
already published version. The current verified publication status follows.

## Current status

Hex package `dwrr` 0.1.0 is public, released from source commit `88c8dc7`.
HexDocs 0.1.0 are public at https://hexdocs.pm/dwrr/0.1.0/, independently
verified on 2026-11-21 after the owner reported successful interactive docs-only
publication. The first automated attempt stopped at OTP authentication; no OTP or
credentials were captured. No further upload was needed for verification.

The Hex release API reports `has_docs: true`. Its `checksum` matches the SHA256
of the downloaded outer `dwrr-0.1.0.tar` and the retained prepublication checksum:
`302456fe434b9bc0279f06bd39cdbabba3026ffa6c19f53723c3b6adf02706b4`.
The package is unchanged. Live checks passed for the getting-started landing,
four public modules, release-pinned source links, navigation and assets, with no
bogus guide preview link.

The docs-only preparation adds ExDoc 0.40.5 (`only: :dev, runtime: false`) and
a public getting-started guide. No package republication, commit, push or tag
was performed. The historical release procedure below is retained, not a
direction to rerun it.

### Docs-only review gate (for separately approved future updates)

Run `MIX_ENV=dev mix docs --warnings-as-errors` and inspect `doc/index.html`,
getting-started, the four public API pages, navigation, examples and source links.
Internal Core/conformance modules and this owner procedure are excluded. Links
resolve to release files at `88c8dc71f673c35281de00d602c5ae2a4a951f7e`;
file-level links deliberately omit current documentation line numbers. The new
guide has no historical source link because it did not exist in that commit.
Executable library AST must match that release exactly (ignoring documentation
and typespec attributes only). Never claim that later documentation edits were
in the package archive.

The installed Hex 2.7.0 help confirms the docs-only command. After independent
build review and approval, use only:

```sh
MIX_ENV=dev mix hex.publish docs
```

Do not use the unqualified publish task, `package`, `--replace` or a package tar.
`MIX_ENV=dev mix hex.publish docs --dry-run` generates docs without uploading.
Hex may regenerate docs during publication: use the same reviewed tree, lock and
runtime. If authentication/2FA requires an interactive owner terminal, stop and
have the owner run the exact docs-only command there; never transmit an OTP or
credentials in chat. After publication, verify the version-specific HexDocs URL
and update this status. The completed publication is recorded above; do not
repeat it merely to verify the site.

## Identity

- Package and application: `dwrr`, version `0.1.0` (`mix.exs`).
- Canonical repository: https://github.com/version2beta/dwrr-elixir
- Published Hex package: https://hex.pm/packages/dwrr/0.1.0
- HexDocs: https://hexdocs.pm/dwrr/0.1.0/ (public, verified 2026-11-21)
- License: MIT (`LICENSE`).
- Runtime minimum: Elixir >= 1.18 on OTP 27. Current: Elixir 1.20.4 on OTP 29.

## Step 1: verify the release commit

Run these on a clean checkout of the exact commit to release. Stop at the first
failure.

1. Confirm the working tree is clean with `git status --porcelain`, which prints
   nothing.
2. Confirm the protected stage-2 assets (tests, fixtures and the CI workflow)
   match the committed baseline. The CI identity test checks the workflow hash.
3. Confirm `mix.exs` has version `0.1.0`, the `## 0.1.0` entry in CHANGELOG.md
   matches this release, and the only dependency is `stream_data` (test only),
   pinned by `mix.lock`.
4. Run the gate on both CI pairings from `.github/workflows/ci.yml`: the minimum
   Elixir 1.18.4 / OTP 27.3 and the current Elixir 1.20.4 / OTP 29.1.2. Record the
   runtime versions used.

Gate:

```sh
MIX_ENV=test mix deps.get --check-locked
mix format --check-formatted
mix compile --warnings-as-errors
MIX_ENV=test mix test --warnings-as-errors --no-color
```

5. Check that the sibling `dwrr-spec` checkout is at commit
   `8a0e3cf9ae860ba207213590c00feeb822bdd8f2` (`git -C ../dwrr-spec rev-parse HEAD`).
   Then run both pinned external tools. Neither modifies upstream files.

```sh
python3 ../dwrr-spec/tools/replay.py --driver 'env MIX_ENV=test mix run --no-compile --no-start scripts/conformance_driver.exs'
python3 ../dwrr-spec/tools/check_driver.py --driver 'env MIX_ENV=test mix run --no-compile --no-start scripts/conformance_driver.exs'
```

Expected output lines:

```text
PASS: 1839 cases, 44728 steps, 7 files
PASS: 36 of 36 checks passed
```

## Step 2: build and inspect the package

Run this only after step 1 passes on both pairings:

```sh
mix hex.build
```

This writes the package archive `dwrr-0.1.0.tar`. Inspect the actual archive
rather than trusting the command's summary:

- The file list must be exactly `lib/**/*.ex`, `mix.exs`, `README.md`,
  `TESTING.md`, `CHANGELOG.md`, `RELEASING.md` and `LICENSE`.
- It must contain no tests, corpus, conformance code, scripts, `docs/`, `.loop/`
  or private source.
- The metadata must show package name `dwrr`, version `0.1.0`, license `MIT` and
  the canonical repository link.

List the outer archive with `tar -tf dwrr-0.1.0.tar`. Extract the inner source
archive to a temporary directory outside the repository and list its files. Remove
the temporary files afterward. Do not commit the archive.

## Step 3: publish (owner only, separate approval)

Publishing is not part of the verification steps above. Run it only when the owner
has:

- reviewed the step 1 results and the step 2 archive inspection for this exact commit;
- confirmed the Hex account that owns the `dwrr` package and its credentials;
- explicitly authorized publishing version 0.1.0.

Use the owner's own Hex credentials through Hex's interactive login. Never put
credentials, API keys, tokens or their values in a file, a command line, a log, a
CHANGELOG entry or a PROGRESS note.

```sh
mix hex.publish
```

If the command also offers to publish HexDocs, that is part of the same owner
decision. A published version cannot be overwritten. If a problem is found later,
the owner decides on a new version. Do not republish 0.1.0 with different contents.

After publication, confirm that https://hex.pm/packages/dwrr and
https://hexdocs.pm/dwrr/ show 0.1.0. Then the owner removes "unreleased" from the
CHANGELOG heading in a separate commit.

## Step 4: tag and push (separate owner permission)

Tagging and pushing are separate actions with their own permission. Do not infer
them from publication.

```sh
git tag -a v0.1.0 -m "dwrr 0.1.0" <release-commit>
git push <remote> v0.1.0
```

Replace `<remote>` with the owner's chosen remote for the canonical repository,
and run these only after the owner approves them.
