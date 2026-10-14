# Coverage collection, validation and reporting

## What the percentage means

The authoritative gate is `coverage-macos` in
[the CI workflow](../.github/workflows/cicd.yml). It requires the union of the
measurable lines in `src/*.sh` to reach **100%**, using reports collected from
one checkout by [the strict verifier](../scripts/verify-final-coverage-v3.sh).

The runs are Bash 3.2, Homebrew Bash 5+, selected zsh ShellSpec tests, and an
independent Bash TTY probe. “Full report” describes a complete instrumentation
inventory; it does not mean that the entire ShellSpec suite runs under every
shell. The zsh test selection remains the selection in the verifier.

A line is covered when at least one of these runs records a positive hit for
that exact file and line. This is not per-shell 100% coverage, branch coverage,
all-input coverage, or proof of complete correctness. The denominator is taken
from the validated reports, not a fixed historical line count.

The separate Linux job continues to run compatibility/regression checks and
collect diagnostic reports. Its reports are retained as an artifact but are
not uploaded to Codecov or added to the strict macOS union.

## CI test matrix

This matrix describes the commands configured in
[the workflow](../.github/workflows/cicd.yml) and
[the strict verifier](../scripts/verify-final-coverage-v3.sh), not the outcome of
an individual run. Read the logs for executed examples, skips, installed
versions, source SHA and results. Update this section when those commands change.

### Operating system, shell and execution location

`ubuntu-22.04` and `macos-15` select the GitHub-hosted runner operating system.
Bash and zsh are the interpreters running on that operating system. These are
separate dimensions; macOS is not another name for zsh. The workflow's
`shell: bash` runs the orchestration step, while ShellSpec's `--shell` selects
the interpreter under test.

`coverage-macos` checks out source on GitHub's macOS runner, installs its tools,
and calls the verifier there. The verifier creates a fresh temporary report
directory on that machine. The workflow uploads that run's validated union;
it does not retrieve reports from a contributor's Mac. Running the verifier
on a development Mac produces a separate local result and does not itself run
the Codecov upload step.

Keep `macOS` in operating-system requirements, runner labels, platform-specific
notes and report-origin labels. Do not replace it globally with `zsh`. This
matrix keeps the existing job IDs and release dependencies unchanged.

### Configured tests and report destinations

| Runner | Job | Interpreter or tool | Configured scope / entry point | Included in Codecov union? |
| --- | --- | --- | --- | --- |
| `ubuntu-22.04` | `test` | Installed Bash and zsh | `bash scripts/test.sh --kcov -f t`: the workflow's Bash/zsh compatibility entry point followed by the existing Bash ShellSpec regression suite. Compatibility cases are maintained by the test entry point, not redefined here. | No. Linux coverage remains diagnostic evidence. |
| `ubuntu-22.04` | `test` | Installed zsh, via ShellSpec `--shell zsh` | Selected `spec/string.spec.sh` and `spec/reflection.spec.sh` tests; separate `coverage-zsh` report. | No. Retained with Linux diagnostics. |
| `macos-15` | `coverage-macos` | `/bin/bash`, expected Bash 3.2 | ShellSpec over `spec/*.spec.sh`, subject to the suite's conditional skips; report label `bash32`. | Yes, as a full-inventory report. |
| `macos-15` | `coverage-macos` | Homebrew Bash, expected Bash 5+ | ShellSpec over `spec/*.spec.sh`, subject to the suite's conditional skips; report label `bash5`. | Yes, as a full-inventory report. |
| `macos-15` | `coverage-macos` | `/bin/zsh` | Four selected spec files listed below; report label `zsh`. This is not the complete ShellSpec suite. | Yes, as a full-inventory report. |
| `macos-15` | `coverage-macos` | Python PTY driver launching `/bin/bash` | `bash_base_tty_probe_v3.py --shell /bin/bash --preload-input`; the verifier requires `TTY_COVERAGE_PASS 2/2`. | Yes, as the supplemental TTY report. |
| `ubuntu-22.04` and `macos-15` | `test` and `coverage-macos`, respectively | Python 3 | `python3 -m unittest discover -s tests -p 'test_coverage_union_v3.py' -v`; synthetic report fixtures exercise validation and export. | No. These are tests of the coverage tooling, not additional production-source coverage. |

The macOS zsh selection is exactly:

```text
spec/string.spec.sh
spec/reflection.spec.sh
spec/coverage_edges.spec.sh
spec/coverage_zsh_array_map.spec.sh
```

The macOS job calls the strict verifier directly, not `scripts/test.sh`. Do not
infer that the separate Bash/zsh compatibility entry point is also invoked on
macOS merely because the strict verifier tests both interpreters.

The Linux zsh probe's **coverage report** is diagnostic. The probe itself is
not best-effort: the workflow propagates its test exit status and does not
ignore a failing probe.

### Limits, versions and evidence

A **full-inventory report** contains the baseline measurable files and lines;
it need not execute every spec file or cover every measured line. An unexecuted
line remains in the inventory with zero hits. In particular, the zsh inventory
must match the Bash inventories even though the zsh spec selection is smaller.

The four macOS reports are collected sequentially from one checkout and merged
as described below. This is a documented testing matrix, not a
`strategy.matrix` expansion, a full operating-system-by-shell Cartesian product,
or an average of coverage percentages. Linux reports are not merged into it.

The configured checks do not establish a complete zsh ShellSpec run, an explicit
Linux Bash 3.2 job, TTY testing under every interpreter, or testing across every
macOS release and CPU architecture. A 100% union does not establish any of these
claims. The compatibility contract remains in
[Bash and zsh compatibility](bash-zsh-compatibility.md); this table records test
scope rather than expanding the public support contract.

ShellSpec is explicitly pinned to `0.28.1` in both collection jobs. Bash/zsh,
Homebrew packages and the runner images are not all pinned to immutable versions.
The verifier selects `/bin/bash`, `/bin/zsh` and `BASH5` (or Homebrew's Bash); its
labels are not substitutes for checking actual version output. It is configured
for the macOS tool layout, so running it unchanged on a different OS does not
prove that its `bash32` row actually used Bash 3.2.

For PRs, the strict job uses the PR head SHA and the Linux job uses the default
PR merge checkout. Keep their evidence separate. For a run-specific result,
record the source SHA, runner/image and architecture, actual interpreter versions,
executed/skipped tests and validated line totals alongside the CI result.
Historical local versions and line counts are not permanent CI guarantees.

Runner labels and workflow shell semantics are documented in GitHub's
[hosted-runner reference](https://docs.github.com/en/actions/reference/runners/github-hosted-runners)
and [workflow syntax](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax).

## Validation and export

[bash_base_coverage_union_v3.py](../bash_base_coverage_union_v3.py) uses the first
full report as the measurable-line baseline. The three full reports must have
identical file and line inventories. The TTY supplement may omit whole files,
but a file present in that report must have the baseline's complete line
inventory. Additional or missing lines are not silently reconciled.

The verifier compares `src/*.sh` SHA-256 hashes before and after collection.
All test commands must succeed before it invokes the merger. Cobertura XML
alone cannot establish the source revision or prove that tests succeeded; do
not merge reports from unrelated source revisions or independent old runs.

The optional `--output-cobertura FILE` switch exports only the validated union.
It requires strict validation and `--source-dir` pointing to `src`. The output
must be outside `src` and must not already exist; use a fresh output path.

The exported report:

- preserves every baseline measurable line, including lines with zero hits;
- records union hits as `0` or `1`, not cumulative execution counts;
- uses repository-relative `src/<filename>.sh` paths and `<source>.</source>`;
- derives per-file and overall totals/rates from the same line records used by
  the gate, with no asserted branch coverage.

The verifier writes the export to `$COVERAGE_ROOT/union/cobertura.xml`. Raw
reports, logs, source hashes, the tested commit and the export remain available
in the `strict-macos-coverage` artifact.

### Failure behaviour

| Outcome | Union exported/upload eligible? | Strict gate |
| --- | --- | --- |
| Tests pass, source hashes unchanged, inventories valid, all lines covered | Yes | Pass |
| Same validation succeeds, but genuine uncovered lines remain | Yes, including all zero-hit lines | Fail |
| A test fails, source hashes differ, reports are missing/malformed, or inventories differ | No | Fail |
| The export cannot be written or the workflow cannot save its evidence | No upload | Fail |
| A Codecov upload fails after the gate passes | Existing export remains an artifact | The upload step makes `coverage-macos` fail |

Reporting a valid below-100% result is intentional: otherwise a coverage
regression could leave an old green percentage visible. The verifier still
returns nonzero and its failed step is not marked `continue-on-error`.

If no valid new upload exists, Codecov may continue to display an earlier
processed commit. Always compare commit SHAs and CI results, not only the badge.
An upload accepted by the client is not proof that server-side processing and
all UI widgets have finished updating.

## Codecov upload and authentication

The workflow uploads exactly one report using the official Codecov action,
pinned to the v7.1.1 commit. `files` explicitly names the union XML and
`disable_search: true` prevents discovery of other reports. `plugins: noop`
disables additional collection plugins; `disable_file_fixes: true` avoids
client-side removal of measured lines. CLI integrity verification is not
bypassed. The action itself is pinned; its CLI download still uses the action's
default version policy, so this is not a claim that all transitive tools are
version-pinned.

Configure a **repository-specific Codecov upload token** as the GitHub Actions
secret `CODECOV_TOKEN`:

1. In Codecov, open this repository's **Configuration / General** page and obtain
   its repository upload token. Prefer this over an organization-wide token.
2. In the GitHub repository, open **Settings → Secrets and variables → Actions**
   and create or verify the repository secret named `CODECOV_TOKEN`.
3. Set only the token value. Do not put credentials in `codecov.yml`, a commit,
   a screenshot, or a shared log.

This credential is unrelated to `NPM_TOKEN`, `GITHUB_TOKEN`, Docker credentials,
or npm Trusted Publishing. The coverage job only requests `contents: read`;
it does not gain `id-token: write`. The two npm OIDC release jobs are unchanged.

Public fork PRs do not receive repository secrets. The official action supports
public fork uploads without the upstream token. Do not enable
`pull_request_target` to run untrusted PR code with secrets. For Dependabot PRs,
configure the upload token as a Dependabot secret as described by Codecov's
action documentation. Actual upload acceptance remains subject to Codecov's
repository/organization settings and service availability.

The action also supports Codecov OIDC, but this patch deliberately does not add
OIDC permission to test jobs in the existing npm publishing workflow. A future
OIDC change should review the identity trust boundary separately.

## Commit identity and release boundary

For pull requests, `coverage-macos` checks out the PR head SHA explicitly and
passes the actual `git rev-parse HEAD` value to Codecov as `override_commit`.
The separate Linux job continues to test the default PR merge checkout. These
are distinct checks; they are not presented as reports from the same checkout.
For push/manual runs, coverage uses the triggering SHA.

Do not label a feature-branch upload as `master` or relabel a merge-commit report
as a different source SHA. The default-branch README badge will not change just
because a PR's coverage passes.

The `semantic-release-preview` job still depends on `coverage-macos`, and the
real release job still depends on the preview. Thus either the strict gate or
its Codecov upload failing blocks the existing release dependency chain. A
Codecov outage can therefore block publishing even when the local gate passes;
this is an explicit consequence of `fail_ci_if_error: true`.

The workflow already supports `workflow_dispatch`, with both release jobs
restricted to `push` on `master`. A manual run of this workflow on the proposed
branch can validate coverage/upload without invoking those release jobs.
Merging to `master` is not a side-effect-free upload test: it can trigger the
existing npm/GitHub/Docker release path.

## Why codecov.yml is present

A repository-level Codecov YAML is optional. Without one, Codecov uses its
service defaults and any organization-level settings; its absence did not
cause the missing union upload.

The [minimal project configuration](../codecov.yml) makes the project and patch
coverage targets explicitly 100%, with zero tolerance and no carryforward for
`strict-union`. It adds no ignore patterns or source-path filters. This is a
reporting policy, not a replacement for the source inventory validator.

`require_ci_to_pass: false` and `wait_for_ci: false` allow Codecov notifications
to report genuine regressions even when CI is already red, or before unrelated
release steps finish. They do **not** make a failed strict gate successful or
change GitHub branch protection. There is one authoritative upload, so
`after_n_builds` is 1, not 4.

Codecov merges repository YAML with organization YAML; account-level settings
and service-side processing must still be checked in the first real run.
Validate the YAML with Codecov's official validator before rollout.

## README display

The tree remains clickable and points to the `master/src` detail view. A brief
caption explains union line coverage. The badge remains a dynamic Codecov
badge; it is never replaced with a static “100%”. Historical commits keep their
historical coverage unless new reports for those commits are intentionally
submitted.

The GitHub Actions badge uses Shields' supported workflow-filename endpoint,
with `cicd.yml`, `branch=master` and `event=push`. It reports the **whole
workflow**, not just `coverage-macos`. A release failure may make that badge red
while Codecov shows full line coverage.

## Verification and troubleshooting

Run the exporter self-tests (synthetic report fixtures, not production coverage):

```bash
python3 -m unittest discover -s tests -p 'test_coverage_union_v3.py' -v
```

Run the actual coverage gate on the configured macOS development environment:

```bash
bash scripts/verify-final-coverage-v3.sh "$PWD"
```

In the CI log, inspect `SOURCE_COMMIT`, `SOURCE_SHA256_UNCHANGED`,
`MEASURABLE_LINE_SETS`, `VALIDATED_COBERTURA` and `COVERAGE_GATE`. Open the artifact
and compare the XML's `lines-valid` / `lines-covered` counts and `src/*.sh`
filenames with the merger log and Codecov for that same commit.

When Codecov disagrees, check in this order: commit/branch identity; uploader
success and server processing; source paths and measured-line counts; any other
uploaders or organization-level YAML. Do not lower the gate, hard-code a badge,
add ignore rules, or rerun an obsolete uploader to make the display green.

## Official references

- [Codecov YAML and its optional status](https://docs.codecov.com/docs/codecov-yaml)
- [Codecov YAML reference](https://docs.codecov.com/docs/codecovyml-reference)
- [Codecov upload tokens and public fork behaviour](https://docs.codecov.com/docs/codecov-tokens)
- [Pinned Codecov action inputs](https://github.com/codecov/codecov-action/blob/303a32d7a59b442fa8d48b6a1cc6825c09c847a5/action.yml)
- [Codecov report fixes](https://docs.codecov.com/docs/fixing-reports)
- [GitHub Actions workflow status badge](https://shields.io/badges/git-hub-actions-workflow-status)
