# Accessibility Checklist

Reference for WCAG 2.1 AA compliance. Used alongside the `frontend-ui` skill. Run through this before considering any user-facing change complete.

## Table of Contents

- [Essential Checks](#essential-checks)
- [Common HTML Patterns](#common-html-patterns)
- [Testing Tools](#testing-tools)
- [ARIA Live Regions](#aria-live-regions)
- [Common Anti-Patterns](#common-anti-patterns)

## Essential Checks

### Keyboard Navigation

- [ ] All interactive elements focusable via Tab
- [ ] Focus order follows visual/logical order
- [ ] Focus is visible (outline or ring on focused elements; never `outline: none` without a replacement)
- [ ] Custom widgets have keyboard support (Enter to activate, Escape to close, arrow keys where appropriate)
- [ ] No keyboard traps — user can always Tab away from a component
- [ ] Skip-to-content link near the top of every page (visible at least on focus)
- [ ] Modals trap focus while open and return focus to the trigger on close

### Screen Readers

- [ ] All images have `alt` text (or `alt=""` for purely decorative images)
- [ ] All form inputs have associated labels (`<label htmlFor>` or `aria-label`)
- [ ] Buttons and links have descriptive text — never bare "Click here" or "Read more"
- [ ] Icon-only buttons have `aria-label`
- [ ] Page has exactly one `<h1>` and headings don't skip levels (h1 → h2 → h3, not h1 → h3)
- [ ] Dynamic content changes announced via `aria-live` regions
- [ ] Tables have `<th>` headers with `scope="col"` or `scope="row"`
- [ ] Lists use `<ul>` / `<ol>` / `<li>` (not styled `<div>`s)

### Visual

- [ ] Text contrast ≥ 4.5:1 (normal text) or ≥ 3:1 (large text, ≥ 18px or ≥ 14px bold)
- [ ] UI components and graphical objects contrast ≥ 3:1 against adjacent colors
- [ ] Color is never the only way to convey information (pair with icon, text, or pattern)
- [ ] Text resizable to 200% without breaking layout or hiding content
- [ ] No content flashes more than 3 times per second
- [ ] Focus ring is visible against every background it appears on

### Forms

- [ ] Every input has a visible label (placeholder is not a label)
- [ ] Required fields indicated by more than color (asterisk, "(required)", icon)
- [ ] Error messages are specific ("Email must include @"), not generic ("Invalid")
- [ ] Errors are programmatically associated with the field (`aria-describedby`)
- [ ] Error state visible by more than color (icon, text, border style)
- [ ] On submit failure, errors summarized and the summary is focusable
- [ ] Known fields use `autocomplete` (`autocomplete="email"`, `autocomplete="given-name"`, etc.)
- [ ] Error messages reach screen readers (use `role="alert"` or `aria-live="assertive"` for blocking errors)

### Content

- [ ] Language declared on root: `<html lang="en">`
- [ ] Page has a unique, descriptive `<title>`
- [ ] Links visually distinguish from surrounding text by more than color
- [ ] Touch targets ≥ 44×44px on mobile
- [ ] Meaningful empty states (not blank screens with no context)
- [ ] No `tabindex` values greater than 0 (breaks natural tab order)

## Common HTML Patterns

### Buttons vs. Links

```html
<!-- Use <button> for actions (mutates state, opens dialog, submits) -->
<button onClick={handleDelete}>Delete Task</button>

<!-- Use <a> for navigation (changes URL or destination) -->
<a href="/tasks/123">View Task</a>

<!-- NEVER use div/span as a button -->
<div onClick={handleDelete}>Delete</div>  <!-- BAD: not focusable, no Enter/Space -->
```

### Form Labels

```html
<!-- Explicit label association (preferred) -->
<label htmlFor="email">Email address</label>
<input id="email" type="email" required />

<!-- Implicit wrapping -->
<label>
  Email address
  <input type="email" required />
</label>

<!-- Hidden label (visible label preferred for cognitive accessibility) -->
<input type="search" aria-label="Search tasks" />
```

### ARIA Roles

```html
<!-- Navigation landmarks -->
<nav aria-label="Main navigation">...</nav>
<nav aria-label="Footer links">...</nav>

<!-- Status / non-blocking updates -->
<div role="status" aria-live="polite">Task saved</div>

<!-- Errors / time-sensitive -->
<div role="alert">Error: Title is required</div>

<!-- Modal dialogs -->
<dialog aria-modal="true" aria-labelledby="dialog-title">
  <h2 id="dialog-title">Confirm Delete</h2>
  ...
</dialog>

<!-- Loading state -->
<div aria-busy="true" aria-label="Loading tasks">
  <Spinner />
</div>
```

### Accessible Lists

```html
<ul role="list" aria-label="Tasks">
  <li>
    <input type="checkbox" id="task-1" />
    <label htmlFor="task-1">Buy groceries</label>
  </li>
</ul>
```

### Skip Link

```html
<a href="#main" class="sr-only focus:not-sr-only focus:absolute focus:top-2 focus:left-2">
  Skip to main content
</a>
...
<main id="main" tabIndex={-1}>
  <!-- page content -->
</main>
```

## Testing Tools

```bash
# Automated audit (CI-friendly)
npx axe-core           # Programmatic accessibility testing
npx pa11y https://...  # CLI accessibility checker
npx playwright test    # @axe-core/playwright integrates well

# In browser
# Chrome DevTools → Lighthouse → Accessibility
# Chrome DevTools → Elements → Accessibility tree
# Firefox DevTools → Accessibility panel
```

### Screen Reader Testing

| Platform | Screen Reader | Activation |
|---|---|---|
| macOS | VoiceOver | Cmd + F5 |
| Windows | NVDA (free) | Download from nvaccess.org |
| Windows | JAWS | Commercial |
| Linux | Orca | Pre-installed on most distros |
| iOS | VoiceOver | Settings → Accessibility |
| Android | TalkBack | Settings → Accessibility |

Test with at least one screen reader before shipping. Lighthouse passing is necessary but not sufficient.

## ARIA Live Regions

| Value | Behavior | Use For |
|---|---|---|
| `aria-live="polite"` | Announced at next pause | Status updates, save confirmations, search results loaded |
| `aria-live="assertive"` | Announced immediately, interrupts | Errors, time-sensitive alerts, form validation failures |
| `role="status"` | Same as `polite` | Non-critical status messages |
| `role="alert"` | Same as `assertive` | Error messages, important warnings |
| `aria-busy="true"` | Hides region from AT until `false` | Loading containers |

**Don't overuse `assertive`.** It interrupts whatever the user is reading. Reserve for genuinely time-sensitive updates.

## Common Anti-Patterns

| Anti-Pattern | Problem | Fix |
|---|---|---|
| `<div>` as button | Not focusable, no keyboard support, screen readers skip it | Use `<button>` |
| Missing `alt` text | Images invisible to screen readers | Add descriptive `alt`, or `alt=""` for decorative |
| Color-only states | Invisible to color-blind users | Add icons, text, or patterns |
| Autoplaying media with sound | Disorienting; can't be stopped by AT users | Don't autoplay, or autoplay muted with controls |
| Custom dropdown without ARIA | Unusable by keyboard or screen reader | Use native `<select>` or implement full ARIA combobox/listbox pattern |
| Removing focus outlines | Users can't see where they are | Style outlines, never `outline: none` without replacement |
| Empty links/buttons | "Link" announced with no description | Add visible text or `aria-label` |
| `tabindex="5"` | Breaks natural tab order | Only use `tabindex="0"` (focusable) or `tabindex="-1"` (programmatic focus only) |
| Placeholder as label | Disappears on input, low contrast, not announced reliably | Use a visible `<label>` |
| `<a>` with no href | Not focusable, not a link | Use `<button>` for actions, give the `<a>` a real `href` |
| Generic "Click here" links | No context out of order | Use descriptive link text ("View task #123") |
| Modal that doesn't trap focus | Tab moves into the page behind | Trap focus until close; restore on dismiss |
| Form errors only red | Color-blind users miss them | Add icon + text + accessible association |
| Heading used for visual size | Breaks document outline | Use heading semantics for structure; CSS for size |
| `aria-label` overriding visible text | Mismatch confuses speech input users | Match `aria-label` to visible text, or omit |
