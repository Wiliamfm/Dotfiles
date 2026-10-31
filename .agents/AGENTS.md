# Global Agent Instructions

General-purpose defaults that apply across all projects, regardless of
language or framework. Project-specific `AGENTS.md` files layer on top of
this and take precedence for anything project-specific.

## Project Conventions

If the current project does not have its own `AGENTS.md` at its root,
mention this once early in the session and suggest creating one to capture
project-specific conventions (stack, commands, testing, style, safety
rules). Do not block work on it -- just a nudge, not a gate.

## Communication Style

Be concise and direct. Skip preamble, restating the request, and
unnecessary summaries. Prefer short, to-the-point responses over long
explanations unless the user asks for more detail or the topic genuinely
requires it (e.g. explaining a non-obvious tradeoff).

## Development Workflow: TDD

Default to test-driven development (red -> green -> refactor) for feature
work and bug fixes:

1. Write a failing test that captures the desired behavior.
2. Write the minimal code to make it pass.
3. Refactor with the safety net of passing tests.

If a `tdd` skill is available, use it -- it has the full workflow plus
guidance on mocking, interface design, and refactoring. If it's not
available in this environment, note that one normally lives at
`~/.agents/skills/tdd` (from the user's dotfiles) and suggest checking
whether `~/.agents` is set up here; fall back to the basic red-green-refactor
loop above in the meantime.

Use judgment: trivial one-liners, exploratory spikes, or explicit
"just do it quickly" requests don't need full TDD ceremony.

### Test behavior, not implementation

A test should describe *what* the code does for its callers or the
outside world, and should keep passing when the internals are rewritten.

- Test through the public API / real entry points, not private helpers.
- Don't change visibility to test (no making private things public,
  `internal`/`@VisibleForTesting`-style workarounds, etc.). If a private
  function seems to need its own tests, test it through its public
  caller. If it's genuinely a separate concept, extract it into its own
  module with a deliberate public API that production code uses too,
  not one that only tests use.
- Assert on observable outcomes: return values, errors callers branch
  on, and what is sent/stored/written/logged when that is a requirement.
- Fake only at system boundaries (network, queues, storage, databases,
  clocks), never your own internal collaborators.
- Don't assert on private functions, internal call order or counts
  callers can't observe, query text, struct layout, or error/log wording.
- Smell test: if a refactor that keeps behavior identical breaks the
  test, the test is testing implementation. Rewrite it against the
  behavior.

## Git Safety

Never run destructive or history-rewriting git operations without asking
first, including but not limited to:

- `git push --force` / `--force-with-lease`
- `git reset --hard`
- `git clean -fd` (or `-x`)
- `git checkout -- <file>` / `git restore` when it discards uncommitted work
- `git rebase` (interactive or not), `git filter-branch`
- deleting branches or tags, especially remote ones
- amending or rewriting commits already pushed/shared

Prefer non-destructive alternatives (new commit, new branch, `--dry-run`)
when possible, and always confirm before anything that discards work or
rewrites shared history.
