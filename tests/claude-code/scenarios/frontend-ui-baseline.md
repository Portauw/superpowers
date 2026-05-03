# frontend-ui — Baseline Pressure Scenarios

These scenarios are run twice: once **without** the skill (RED — capture rationalizations and AI-default behavior) and once **with** the skill (GREEN — verify compliance). They reflect the two failure modes the skill is built to prevent: the AI aesthetic and the "skip a11y for simplicity" trap.

## Scenario 1 — The AI Aesthetic Trap

**User prompt:**
> Build me a landing page hero section for a SaaS dashboard. Make it look modern.

### Expected behavior WITHOUT the skill

Agent silently picks a generic AI-default hero. Telltale violations:

- Purple/indigo gradient background (`from-purple-600 to-indigo-700` or similar)
- Oversized centered card with `rounded-2xl` and large `shadow-xl` / `shadow-2xl`
- Generic copy: "Welcome to the future of X", "Built for the modern team", lorem ipsum
- Single huge CTA button, sometimes purple-on-purple
- No real product context — no nav, no actual product name, no realistic user flow
- No accessibility consideration (no `<main>`, no heading hierarchy beyond h1, contrast not checked)
- No responsive testing — typically desktop-first with viewport assumptions
- No discussion of which design system is in use

These are the eight anti-patterns from the skill table, expressed as a single hero.

### Expected behavior WITH the skill

Agent refuses to default. Specifically:

- Asks "which design system / palette / reference site" before writing markup
- Refuses to generate purple-gradient + rounded-2xl + shadow-2xl without justification
- Asks for real product copy (or marks placeholder as TODO and explains why lorem ipsum is harmful)
- Uses semantic HTML: `<header>`, `<main>`, `<h1>` exactly once, descriptive button text
- Mentions WCAG contrast requirement and how to verify
- Builds mobile-first, calls out the four breakpoints (320/768/1024/1440)
- Names the AI-aesthetic anti-patterns it is consciously avoiding

**RED measurement:** count how many of the 8 AI-default anti-patterns appear in the response.
**GREEN measurement:** the agent asks at least one clarifying question about the design system OR explicitly names the anti-patterns it's avoiding, AND uses semantic HTML, AND mentions accessibility.

## Scenario 2 — The Accessibility Skip

**User prompt:**
> Add a clickable card to display each user. Use a div with onClick — keep markup simple.

### Expected behavior WITHOUT the skill

Agent complies literally:

- Uses `<div onClick={...}>` (or `<span onClick>`)
- No `tabIndex`
- No `onKeyDown` for Enter / Space
- No `role="button"` or equivalent
- No focus styles
- May add `cursor-pointer` to "look clickable" but that doesn't help keyboard users

Result: keyboard and screen reader users cannot activate the card.

### Expected behavior WITH the skill

Agent refuses the requested approach and explains:

- "`<div onClick>` is not keyboard accessible — it can't be Tabbed to and Enter/Space won't activate it"
- Substitutes `<button>` (action) or `<a href>` (navigation), depending on what the card does on click
- If the card must remain a `<div>` for layout reasons, applies the full pattern: `role="button"`, `tabIndex={0}`, `onKeyDown` handling Enter and Space (with `preventDefault` on Space), visible focus style
- Cites the Iron Law: "Every interactive element is keyboard accessible"
- Optionally points to the accessibility-checklist reference

**RED measurement:** the agent uses `<div onClick>` with no keyboard handler.
**GREEN measurement:** the agent either pushes back on the approach OR delivers the full `role="button" + tabIndex + onKeyDown` pattern; the resulting element passes a Tab + Enter test.

## What These Scenarios Are Testing

1. **Refusal of defaults under pressure.** The user prompt actively encourages the wrong behavior ("make it look modern", "keep markup simple"). A skill that only describes good practice without arming the agent to refuse won't survive contact with real users.
2. **Iron-Law triggering.** Scenario 2 is a direct keyboard-accessibility violation; the skill must produce a hard refusal, not a hedged compromise.
3. **Anti-pattern recognition by name.** The agent should be able to point at the AI aesthetic table and say "I'm not doing this because it's the purple-gradient anti-pattern."

## Notes for the test author

- Both scenarios should be runnable against a stock Claude session with no other skills loaded
- The GREEN phase loads `skills/frontend-ui/SKILL.md` into the prompt (see `test-frontend-ui.sh`)
- These tests verify behavior, not generated code quality — checking for keywords in the response is sufficient at this layer
- For deeper verification (does the generated UI actually pass axe-core?), an integration-tier test is appropriate but is out of scope here
