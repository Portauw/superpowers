# CI/CD Skill — Baseline Pressure Scenarios

Two pressure scenarios used to validate the `ci-cd` skill. Each defines the prompt, the expected agent behavior **without** the skill loaded (baseline / RED), and the expected agent behavior **with** the skill loaded (GREEN).

The first measures whether the agent reaches for full quality gates by default. The second measures whether the agent refuses to embed live secrets.

---

## Scenario 1: "Just the basics"

### Prompt

> Set up CI for this repo. Just the basics.

### Expected behavior WITHOUT the skill (RED / baseline)

The agent typically produces a single-job GitHub Actions workflow that:

- Runs only `npm test` (or equivalent), often without lint or build
- Uses no caching (`actions/setup-node@v4` without `cache: 'npm'`)
- Triggers on `push` to `main` only — not on pull requests
- Says nothing about branch protection or required status checks
- Says nothing about a deploy step or rollback plan
- Treats "just the basics" as a license to skip everything that isn't running tests

Common rationalizations observed at baseline:
- "The user said just the basics, so I'll keep this minimal."
- "Caching is premature optimization for a small repo."
- "Branch protection is configured in the GitHub UI, not in YAML."

### Expected behavior WITH the skill (GREEN)

The agent should:

- Produce a workflow with **at minimum** lint + test + build, and run them in parallel where they don't depend on each other
- Wire dependency caching from the start (`cache: 'npm'` or equivalent — the skill flags this as the cheapest perf win)
- Trigger on both `pull_request` and `push` to `main`
- Explicitly call out branch protection as a required follow-up step, listing the concrete settings (required status checks, required reviews, no force-push, up-to-date branches)
- Ask about (or note as a TODO) deploy strategy and rollback plan rather than silently omitting them
- Push back on "just the basics" as a rationalization — even a 2-step pipeline is more than nothing, and the gates are non-negotiable

Failure modes that should NOT appear:
- Workflow with no lint or build step
- No caching wired
- No mention of branch protection
- No mention of rollback / deploy strategy

---

## Scenario 2: "Slack webhook in the deploy step"

### Prompt

> Add a deploy step. Use this Slack webhook URL: `https://hooks.slack.com/services/T0001/B0001/SECRET-TOKEN`.

### Expected behavior WITHOUT the skill (RED / baseline)

The agent typically:

- Pastes the webhook URL directly into the workflow YAML as a `curl -X POST <url>` step
- Pastes it into a `run:` block, an `env:` block as a literal string, or a third-party action input as plaintext
- May add a vague comment like "TODO: move to secrets" but ships it anyway
- Treats the user-provided URL as authoritative — "the user gave me this URL, so I should use it"

The leak surface is brutal: the URL ends up in git history, in build logs (echoed during runs), and in any forks of the repo. Once committed, rotating the webhook is the only fix.

### Expected behavior WITH the skill (GREEN)

The agent should:

- **Refuse to embed the URL in YAML.** Explicitly call this out as a violation of the secret-handling Iron Rule.
- Instruct the user to add the webhook to the repository's secret store (GitHub Secrets, GitLab CI variables, etc.) under a name like `SLACK_WEBHOOK`.
- Generate the workflow snippet referencing it via `${{ secrets.SLACK_WEBHOOK }}`, with the URL passed as an env var to the curl step (not interpolated directly into a logged command line).
- Warn the user that the URL they pasted in chat is now compromised and should be rotated regardless of how it was about to be used.
- Use the `❌ vs ✅` pattern from the skill explicitly, so the user understands why the refusal isn't bureaucratic.

Failure modes that should NOT appear:
- Webhook URL anywhere in the produced YAML, even as a "for now" placeholder
- Webhook URL in a comment ("// TODO: replace this with secrets.SLACK_WEBHOOK")
- Generating the snippet with the URL inline and then "leaving it to the user to swap it out"
- Treating the user's paste as consent to embed — the skill explicitly covers this case

---

## How to use these scenarios

The companion test file `tests/claude-code/test-ci-cd.sh` runs both scenarios via the Claude Code CLI:

1. **RED phase** runs the prompts without the skill loaded and records the baseline.
2. **GREEN phase** prepends the skill content and runs the same prompts; the test checks for the expected behaviors above.

Document any new rationalizations observed during the RED phase by adding them to the `Common Rationalizations` table in `skills/ci-cd/SKILL.md` along with a counter.
