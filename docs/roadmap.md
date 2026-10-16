# Bash-base roadmap

> **Status:** Planning document; last reviewed 2026-10-16. Priorities and status
> notes describe the known project state at that review, not a guarantee of
> present CI or release status. Check current GitHub issues, pull requests,
> workflow runs and published artifacts before acting.

## Purpose and scope

Bash-base aims to make **command-oriented Bash and zsh programming more reliable,
understandable and composable**. Reusable higher-level helpers should reduce
repeated searching, comparison, experimentation, verification and maintenance.
String and array operations support argument management, output transformation
and automation logic; implementing a general-purpose data-processing language
is not the project's goal.

This roadmap identifies problems to investigate, their relative priorities and
what evidence would justify calling the work complete. It is **not** a promise
that every proposed API will be implemented, a release schedule, or a statement
that unimplemented helpers are already available.

Read [design principles](design-principles.md) for lasting rules,
[Bash/zsh compatibility](bash-zsh-compatibility.md) for the currently documented
portability contract, [coverage and the CI test matrix](coverage.md) for actual
test scope, and [CONTRIBUTING](../CONTRIBUTING.md) for proposal and review
requirements. The [generated API reference](references.md) and source comments,
not this roadmap, describe shipped APIs.

## How priorities and status work

| Priority | Meaning |
| --- | --- |
| **P0 — Reliability and foundations** | Protect current consumers, close release/security risks and establish contracts needed before safely expanding APIs. |
| **P1 — Coherent evolution** | Improve composability, data semantics, deployment experience and testing after their dependencies are understood. |
| **P2 — Candidate capabilities** | Investigate useful new helpers only when real recurring use cases justify them. |

Possible status values are **Proposed**, **Under investigation**, **Planned**,
**In progress**, **Blocked** and **Completed**. An item's presence or P-level
**does not authorize implementation**. Keep statuses and evidence in focused
GitHub issues and pull requests; update this document when the direction,
priority or acceptance criteria meaningfully change. Do not invent dates or
promise a particular release number before scope and risks are reviewed.

## P0 — Reliability, release integrity and API foundations

### P0.1 Complete and verify the release chain

**Status (2026-10-16): In progress.** The GitHub Actions to npm OIDC token
exchange was observed to succeed. The first end-to-end publication was not
completed in the observed run: release Git push was blocked by a local Husky
`pre-push` hook in a job without zsh. Treat this as a release-workflow issue;
do not reintroduce a long-lived npm publishing token or bypass existing quality
gates. Current results and fixes must be checked in the relevant CI runs.

Work to investigate and verify:

- Keep npm Trusted Publishing matched to the authorized GitHub repository and
  release workflow, with narrowly scoped `id-token: write` on trusted release
  jobs. Validate actual publication, not only credential exchange or dry-run.
- Keep GitHub Release and Docker authentication separate from npm OIDC. Avoid
  re-running developer-local Git hooks in release jobs after required CI gates,
  without disabling those hooks for contributors.
- Verify npm package version, Git tags, generated bundle, GitHub Release and
  Docker tags/images represent the intended source and release. Investigate the
  previously observed mismatch between the npm published version and the latest
  Git tag instead of assuming they were always synchronized.
- Review release-trigger rules and side effects: documentation and CI commits
  may currently cause a patch release. Preserve intended behavior until a
  separate, reviewed change establishes a new policy.
- After a successful trusted publish, review restrictive package publishing
  access and retire obsolete npm tokens without removing credentials needed by
  other release destinations.

**Acceptance:** A real authorized `master` release completes with the required
lint, compatibility, regression and strict coverage jobs passing; npm, GitHub
and Docker artifacts are checked against the intended tag/source; the npm
Trusted Publisher is validated; no legacy `NPM_TOKEN` is needed by npm publish.

### P0.2 Security and compatibility audit of existing code

**Status: Planned; findings require fresh source review.**

- Audit `eval`, dynamic variable names/references, command-string construction,
  argument quoting, glob expansion, external input and re-interpretation of data
  as Shell code. Distinguish APIs intentionally accepting *trusted code* from
  APIs accepting ordinary data.
- Audit process selection/termination (especially `prc_filter_by_cmd` and
  `prc_kill_by_cmd`) for ambiguous matches, accidental termination, exit-state
  handling and potential safer PID-based alternatives.
- Audit `source`-time and repeated-source effects on caller variables, `IFS`,
  options, traps, current directory, terminal interaction and stdout/stderr.
- Check historical executable-mode changes on `src/*.sh` against actual intended
  use. Sourcing a file does not require the executable bit; whether direct
  execution is a supported contract must be verified before changing modes.
- Audit npm vulnerabilities using a current dependency tree and threat model;
  distinguish development/build-only dependencies from runtime exposure.
  Previous `npm ci` warnings are a historical finding, not a current count.

**Acceptance:** Findings have reproducible evidence and risk classification;
changes preserve existing Bash and documented zsh behavior unless deliberate
migration is approved; regression and adversarial-input tests cover fixes. Do
not remove `eval` indiscriminately or use `npm audit fix --force` as a shortcut.

### P0.3 Define a consistent public API contract

**Status: Planned. Design guidance exists; per-helper review remains.**

Define and document, for new public APIs and each reviewed legacy API:

| Contract area | Required decisions |
| --- | --- |
| Input | Positional parameters, stdin, named variables; accepted identifiers and record boundaries. |
| Output | stdout, named destination, in-place change or other side effect; output suitable for composition. |
| Outcomes | How success, false predicates, empty results, invalid inputs and command failures differ. |
| Data | Ordering, duplicates, empty elements, whitespace, newlines, encoding limitations and serialization domain. |
| Execution | External processes, prompts, timeouts, cleanup, cwd, traps, variables and other caller-state changes. |
| Portability | Tested Shell versions and GNU/BSD command requirements; explicitly documented exceptions. |

**Acceptance:** A reviewed, example-backed contract template is available and
applied to the first representative String, Array, Argument and Process helpers;
contract tests prove relevant boundary behavior. Existing undocumented quirks
are catalogued before redesign. New guidelines **do not retroactively change**
legacy API semantics.

### P0.4 Preserve trustworthy test and coverage gates

**Status: Established gates; continued assurance required.**

- Preserve the Bash regression suite, Bash/zsh compatibility checks and the
  macOS Bash 3.2 / Bash 5+ / zsh / interactive TTY coverage collection.
- Keep the **100% union of measurable source lines** as a mandatory CI gate.
  This does **not** mean each Shell individually has 100% coverage, or that all
  branches, inputs, OS combinations or security properties have been tested.
- Ensure that Codecov displays the validated report for the correct source
  revision, and that report-export or upload failures cannot silently create a
  misleading green result. Preserve diagnostics for failures.
- Add boundary, negative-case, quoting, failure-propagation and caller-state
  tests where risk warrants them. Keep test selectors and the
  [CI test matrix](coverage.md#ci-test-matrix) synchronized.

**Acceptance:** Mandatory CI gates fail on a regression or a real coverage
shortfall; reports and source identity are verifiable; neither exclusions,
synthetic hits nor weakened assertions are used to satisfy a coverage number.

## P1 — Coherent abstractions and adoption

### P1.1 Clarify String / Array / List / Set semantics

**Status: Planned (design before expansion).**

- Distinguish a String from a Shell-native Array, a List (ordered, duplicates
  allowed) and a Set (unique elements; traversal order must be specified).
- Audit the real behavior of existing `array_*` functions, especially union,
  intersection, duplicates and ordering. Do not rename or change them just
  because a new conceptual model is clearer.
- Decide whether distinct `list_*` or `set_*` APIs solve real command-input or
  command-output workflows; avoid adding an entire family for symmetry alone.
- Verify empty elements, spaces, literal wildcards, newline-containing values,
  shell indexing and serialization/restore boundaries in supported Shells.

**Acceptance:** A documented semantic model, representative composition
examples, compatibility analysis and cross-Shell boundary tests precede any
new public type family.

### P1.2 Investigate a Map API

**Status: Under investigation; not an implemented feature.**

Potential uses include options, configuration and key/value associations
between system commands. Start with a contract rather than function names:

- Key and value domain; empty values versus missing keys; duplicate assignment.
- Lookup, insertion/removal and iteration semantics; deterministic ordering
  only if explicitly promised; memory and performance constraints.
- Serialization, newlines and unsafe code/data boundaries.
- A Bash 3.2-compatible representation (it lacks native associative arrays),
  and any Bash 5+/zsh optimization that preserves the same public contract.

**Acceptance:** Demonstrate a recurring use case that existing built-ins,
helpers or tools do not solve adequately; compare representations and costs;
approve an API contract and test model before implementation. A proposal can
be rejected if complexity outweighs command-composition value.

### P1.3 Improve module loading and namespacing

**Status: Proposed.**

- Investigate optional `bb_*` namespaced entry points to reduce function-name
  collisions. Keep current public names working unless a separately planned,
  properly versioned migration is approved.
- Investigate selective module loading with explicit module dependencies,
  idempotence and well-defined `source` effects. Simply splitting files is not
  proof of independent modules.
- Prefer a migration/adoption story with tangible benefit over a broad,
  mechanical rename or a large framework layer.

**Acceptance:** Dependency and state model documented; current full-library
loading remains compatible; realistic scripts validate both old and new usage.

### P1.4 Strengthen fixed-version and offline-first distribution

**Status: Proposed enhancements to existing distribution.**

The build **already generates a single-file** `bin/bash-base`; do not propose
adding that existing feature a second time. Instead:

- Make pinned/local/offline usage clear and straightforward, with examples
  for GitHub, npm, Docker and bundled artifacts that state when network access
  occurs. Never imply that `source <(curl ...)` works offline.
- Evaluate module vendoring or focused bundling only when it lowers setup and
  maintenance costs without changing behavior.
- Verify runtime requirements separately from npm/Docker tools used for build,
  CI or distribution. Check version provenance and reproducibility where useful.

**Acceptance:** A documented, reproducible installation and loading path can
be followed with a pinned artifact after initial acquisition, without requiring
Node.js or Docker merely to execute the already-provided Shell library.

### P1.5 Improve examples and user-facing documentation

**Status: Planned, incremental.**

- Update the README Quick Start and API navigation to match current supported
  Bash/zsh behavior and distinguish online shortcuts from pinned local usage.
- Add complete realistic examples that orchestrate Git, SSH, Docker or system
  commands with safe argument boundaries, outputs, failures and cleanup.
- Keep generated references derived from source comments; do not hand-edit
  `docs/references.md`, `bin/` or man pages outside their generation workflow.
- Track reproducible feedback and real usage rather than treating Stars,
  downloads or function count as proxies for correctness or adoption.

**Acceptance:** Examples execute in declared environments; links and generated
artifacts correspond to the implementation; user feedback informs prioritization.

## P2 — Problem-driven helper candidates (not commitments)

Investigate a candidate **only when** there is a concrete and recurring
command-composition cost and a contract can be made clear. Priority within this
table is intentionally not assigned in advance.

| Candidate | Problem worth investigating | Main risk / contract question |
| --- | --- | --- |
| Bounded `retry` | Transient failures of appropriate external commands | Retry safety/idempotence, wait policy, exit status, stdout/stderr and cancellation. |
| Portable `timeout` | Commands or children that hang | Process groups, signal propagation, cleanup and GNU/BSD differences. |
| Cleanup registration | Consistent temporary-file/process cleanup | Trap ownership, nested/early exits and caller-state changes. |
| Dependency checks | Missing external programs or incompatible tool variants | Clear diagnostics and optional/versioned requirements. |
| Portable path resolution | GNU/BSD differences in paths and symlinks | Physical/logical paths, missing targets and special characters. |
| Secure temporary-file helpers | Cross-platform safe file/directory creation | Races, permissions, lifetime and cleanup contract. |
| Argument/output adapters | Prevent splitting, globbing and unsafe record decoding | Preserve boundaries, empty values and newlines; no fake lossless text format. |
| Structured logging | Consistent diagnostic output for automation | stdout/stderr ownership, optional external dependencies and formatting. |
| Safer process APIs | Replace ambiguous process-name matching where appropriate | PID identity, permissions, dry-run and accidental termination. |

No candidate name above should be treated as an existing Bash-base API. A
small example, clearer documentation or an established external utility may be
preferable to implementing a wrapper.

## Backward compatibility and release strategy

The default is to **preserve the v2.x public Bash behavior and documented zsh
support**. Prefer new explicit contracts and additive, narrowly scoped APIs
over silent changes to old names or outputs. For any breaking change, document
consumer impact, alternatives, migration steps and why a major release is
necessary. A hypothetical v3 is not a scheduled deliverable.

Do not expand the project into a full object system, general JSON/YAML engine,
all-POSIX-Shell portability layer or a Python-equivalent standard library
without separately demonstrated command-oriented need. High-level abstraction
should hide incidental complexity, **not meaningful errors or side effects**.

## How an item becomes work — and how work is accepted

1. **Describe the pain.** Provide a real script or task, the repetitive research
   and verification burden, and the commands/data boundaries involved.
2. **Compare alternatives.** Check built-ins, existing helpers, external tools,
   example-only solutions and their deployment costs.
3. **Define the contract.** Decide inputs, outputs, return states, side effects,
   portability limits, versioning and a realistic composition example.
4. **Validate the change.** Add behavior and failure tests in relevant Shells,
   check caller state and preserve the existing required CI and 100% line-union
   gate. Coverage is evidence, not proof of total correctness.
5. **Review net maintenance value.** Accept only when expected time/risk savings
   justify implementation, learning and long-term support cost.

Create a focused [GitHub issue](https://github.com/renault-digital/bash-base/issues)
for an approved investigation or proposed task, linking the appropriate
acceptance evidence. Use [pull requests](https://github.com/renault-digital/bash-base/pulls)
to track actual implementation and verification; don't mark an item completed
because a document or proposal has been written. Re-review this roadmap after
material changes rather than treating priorities or estimates as permanent.
