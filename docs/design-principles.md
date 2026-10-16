# Bash-base design principles

## Purpose and status

Bash-base is a Shell function library for composing system commands and
expressing automation logic in Bash and zsh. Its purpose is to reduce repeated
research, implementation and verification work through reusable higher-level
interfaces.

The central question is:

> Does this change make command-oriented Shell programming easier to understand,
> combine and maintain, while reducing recurring implementation effort or risk?

This document guides maintenance, feature review and future API design. It does
not retroactively redefine existing APIs, certify arbitrary inputs as safe, or
announce unimplemented features. Existing behavior must be checked against the
[API reference](references.md), the relevant source comments and tests, and the
[Bash/zsh compatibility contract](bash-zsh-compatibility.md). Conflicts between
these sources require investigation rather than an assumption that one silently
changes another.

## 1. Start from a real pain point

A feature should address a concrete scripting problem that recurs or is costly
to get right. Time spent searching, comparing approaches, checking edge cases
and maintaining duplicated implementations is part of that cost.

Code length alone is not a measure of value. A small wrapper may be worthwhile
when it provides a useful contract or isolates a difficult compatibility issue.
Conversely, a large implementation is not justified simply because another
language or library provides the same feature.

Consider built-ins, existing Bash-base helpers, established external tools,
documentation improvements and examples before adding a new public API.
Personal or internal use cases are valid evidence; widespread adoption is not a
prerequisite for proposing a useful change.

## 2. Use abstractions to support command composition

Higher-level interfaces should help callers organize arguments, transform
command outputs and express automation logic without repeatedly implementing
Shell-specific mechanics.

String and array operations serve that purpose. List, Set and Map are useful
concepts for reasoning about order, duplicates and key/value relationships, but
mentioning them here does not establish separate implemented APIs. Any extension
must first justify its role in real command-oriented workflows.

The goal is not a complete object system, a replacement Shell interpreter, a
cloud SDK collection, or a general-purpose application framework. Prefer
integration with suitable tools over duplicating them without a clear benefit.

## 3. Define behavior before adding an interface

For a new public helper, or a deliberate contract change, document the relevant
parts of the following before accepting the implementation:

| Area | Questions to resolve |
| --- | --- |
| Inputs | Arguments, stdin or named variables? Required arguments? Accepted data, code and identifier forms? |
| Outputs | stdout, named variables or mutation? Output format and record boundaries? |
| Outcomes | Success, an empty result, a false predicate, invalid input and execution failure: how are they distinguished? |
| Side effects | Can the helper prompt, execute commands, change files, affect processes, mutate variables or alter Shell state? |
| Data semantics | Are order, duplicates, empty elements, whitespace, newlines and trailing newlines preserved? What is unsupported? |
| Environment | Which Shell versions, options, locales and external-command variants are supported? |
| Composition | How does the result feed another helper or command, and how is failure propagated? |

Do not impose a new universal exit-code table on existing functions without a
compatibility review. Similarly, changing an output channel, ordering rule or
empty-value representation can break callers even when the function name stays
the same.

## 4. Preserve meaningful boundaries

Composable interfaces must keep the distinction between data and executable
Shell code explicit. A helper that intentionally accepts trusted code must say
so; it must not be presented as an arbitrary-data interface.

For new or reviewed interfaces, examine argument boundaries, variable-name
validation, quoting, output framing and error propagation. A convenient wrapper
must not hide unexpected prompting, discarded failures or changes to the
caller's environment.

Do not describe newline-separated output as lossless for arbitrary records
unless the input domain or an encoding makes that true. A text representation,
a native array declaration and a portable interchange format are different
contracts. Serialization must state whether it supports restoration within one
Shell, cross-Shell exchange, or both. Follow the existing compatibility contract;
this design document does not broaden any serialization promise.

Diagnostic output, normal data output and presentation-oriented helpers also
need distinct contracts. Changing an existing helper's stdout/stderr behavior
requires review, not merely a new general rule in this document.

## 5. Make portability an explicit boundary

Target the documented Bash/zsh environment, not every implementation of Shell.
Use common syntax where practical and isolate necessary Shell-specific behavior
behind small, explicit implementation branches.

The public behavior should be consistent within the declared boundary. Where a
native representation or environment-dependent operation is intentionally
Shell-specific, document that exception and test it accordingly.

A sourced library must not acquire undocumented dependencies on caller options
or unexpectedly change `IFS`, options, traps, the working directory or global
variables. Audit existing behavior before changing it; new APIs should make
required effects explicit and avoid unrelated ones.

## 6. Support reliability with evidence

Keep the existing Bash regression tests, Bash/zsh compatibility checks and
mandatory coverage gate. Add tests relevant to the behavior changed, including
error paths and boundary inputs rather than only typical examples.

The 100% requirement concerns measurable source lines under the project's
required coverage configuration. A passing report from one environment does not
replace the required gate. Cover relevant supported-Shell and interactive or
non-interactive behavior; coverage is not proof of complete branch coverage, all
input combinations or the absence of security defects.

Documentation-only changes do not justify artificial test changes. Validate the
changed documentation or metadata, explain why executable behavior is unchanged,
and keep all required status checks and coverage gates in force.

For an implementation review, identify the tested environment and the evidence
that supports each portability or safety claim. Do not weaken tests, exclusions
or coverage requirements merely to obtain a passing result.

## 7. Keep installation and execution predictable

Favor fixed-version, local loading for reproducible or offline workflows. Make
network access and update behavior clear for every documented installation or
loading method rather than treating all methods as equivalent.

The existing build already generates the single-file `bin/bash-base` artifact.
Its presence does not by itself prove that every installation method is offline
or that every published version contains the same compatibility work as the
current source branch.

Distinguish installation and build tooling from commands needed by a helper at
runtime. Offline loading is not a claim that the application needs no external
utilities or network access of its own. Declare dependencies and prefer explicit
user control over updates.

## 8. Evolve without silently breaking callers

Preserve existing public behavior unless a change is deliberately reviewed,
documented and released under the project's compatibility and versioning rules.
New wrappers, compatibility layers or parallel interfaces may provide a migration
path, but they also have maintenance costs and should not be added automatically.

When a legacy interface conflicts with a desired design principle, record its
actual behavior and relevant tests first. Distinguish a defect fix from an
intentional API redesign. A new principle is not permission for an unrelated
behavior change, rename, execution-mode change or dependency upgrade.

## Feature review and acceptance

Early proposals may start with a use case and an unresolved problem. Before an
implementation is merged, the contributor and maintainer should establish the
need, alternatives, scope, public contract, test evidence and compatibility
impact described in [CONTRIBUTING](../CONTRIBUTING.md).

The core review dimensions are **Pain-driven, Contract-driven and
Evidence-driven**. A feature should save more research, implementation or
maintenance work than it introduces, with an understandable learning cost.
There is no function-count target and no requirement to add a whole family of
APIs when only one well-defined operation is needed.

Keep this document focused on design decisions. The API reference belongs to
the existing source-comment generation workflow; specific enhancement proposals
and scheduling decisions belong in issues and pull requests. The
[roadmap](roadmap.md) tracks possible future directions and their acceptance
criteria; it does not override existing API contracts or these principles.
