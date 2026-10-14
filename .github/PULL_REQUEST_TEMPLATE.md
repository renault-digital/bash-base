### Requirements

* Fill out the relevant sections below; explain items that do not apply.
* Add or update appropriate tests for behavior changes. For documentation-only
  changes, explain why test-suite changes are unnecessary and describe the
  documentation or metadata checks performed.
* Preserve the existing regression, Bash/zsh compatibility and mandatory 100%
  measurable-line coverage gates. Do not weaken checks to obtain a passing result.
* All status checks must pass before merge. Pending or unrun checks are
  not passing results.

### Type

- [ ] Bug fix
- [ ] Feature change
- [ ] Performance
- [ ] Refactor
- [ ] Documentation
- [ ] CI/CD
- [ ] Test
- [ ] Build
- [ ] Style
- [ ] Chore

### Issue (only for type `bug fix`/`feature change`)

<!-- Link to the issue that your change relates to. -->

### Description of the Change

<!-- Explain the problem and the scope of the solution. For a new helper,
explain the recurring command-composition cost it reduces and why existing
helpers, built-ins, tools, examples or documentation are not sufficient.
See CONTRIBUTING.md and docs/design-principles.md. -->

### Contract and Compatibility

<!-- For a new or changed public interface, describe inputs, outputs, exit
statuses, data boundaries and side effects. Include a realistic composition
example or link to the updated source comments and tests.

Explain impact on existing Bash behavior, supported zsh behavior, dependencies,
installation/loading and generated artifacts, as applicable. A design principle
is not permission to silently change an existing contract. State any intended
breaking change and migration requirements. Mark this section not applicable
with a reason when no behavior or interface is affected. -->

### Validation

<!-- List the commands actually run and their results. Include relevant Shell/OS
versions, regression and boundary tests, and coverage evidence for code changes.
For documentation-only changes, state the documentation/metadata checks and why
no executable behavior changed. Do not claim a full test run from a static check.
Distinguish completed local checks, pending CI and checks that were not run. -->

### Possible Drawbacks

<!-- Explain relevant side effects, compatibility risks, new dependencies,
learning or maintenance costs, and unresolved questions. A documentation-only
change may still participate in release automation; review the current release
configuration instead of assuming the commit type prevents publication. -->
