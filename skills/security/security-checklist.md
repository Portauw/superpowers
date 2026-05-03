# Pre-Deploy Security Checklist

Run through this checklist before merging anything that touches auth, secrets, user input, or external systems. This is the long-form companion to `SKILL.md` — use it for thorough pre-deploy review and during code review.

## How to Use

- Walk top to bottom. Every box checked or explicitly marked N/A with reason.
- If anything is unchecked at merge time, it's a blocker, not a "follow-up."
- When deferring a finding, document **why** and **review-by date** in the PR.

---

## Authentication

- [ ] Passwords hashed with bcrypt, scrypt, or argon2 (salt rounds ≥ 12 for bcrypt)
- [ ] No plaintext passwords in DB, logs, telemetry, exception trackers, or analytics
- [ ] Session/refresh tokens are httpOnly, secure, sameSite=Lax (or Strict)
- [ ] Session secret loaded from env or secret manager — never hardcoded
- [ ] Login endpoint has rate limiting (≤ 10 attempts / 15 min per identifier + IP)
- [ ] Password reset tokens are single-use, expire (≤ 1 hour), and bound to the user
- [ ] MFA available for sensitive accounts; required for admin
- [ ] Failed-login responses are generic (no "user not found" vs "wrong password")
- [ ] Session invalidates on password change and on logout
- [ ] Tokens have a hard expiration; refresh flow re-validates the user

## Authorization

- [ ] Every protected endpoint runs an authorization check (not just authentication)
- [ ] Authorization is enforced server-side; client-side checks are UX only
- [ ] Users can only read/modify resources they own (`resource.ownerId === user.id`)
- [ ] Admin actions require explicit role/permission verification
- [ ] No "internal" endpoints reachable without auth in production
- [ ] Object-level authorization is per-request, not "trust the URL"
- [ ] No query-param secrets used as authentication (`?admin_key=...`)
- [ ] Roles and permissions are server-derived; not read from user-supplied JWT claims unverified

## Input Validation

- [ ] Every external input passes through a schema validator at the boundary (zod/joi/pydantic/etc.)
- [ ] Validation rejects unknown fields (no silent passthrough)
- [ ] Length, type, format, and range constraints set on every string/number/date field
- [ ] All DB queries are parameterized — no string concatenation, no `${}` in raw SQL
- [ ] Shell commands use `execFile`/argv arrays — no `exec()` with user-built strings
- [ ] HTML output uses framework auto-escaping; any `dangerouslySetInnerHTML` / `v-html` / equivalent is sanitized via DOMPurify
- [ ] File uploads validate MIME type AND size AND magic bytes (for security-critical paths)
- [ ] Uploaded files stored outside the web root, served via signed URLs
- [ ] No use of `eval`, `Function()`, or `vm.runInThisContext` on user input
- [ ] Regex inputs guarded against ReDoS (anchored, no nested quantifiers, or use re2)
- [ ] URL/redirect parameters validated against an allowlist (no open redirects)

## Output Encoding & XSS

- [ ] Templates auto-escape by default; no manual `unsafe` flag bypasses
- [ ] JSON-in-HTML escaped properly (`</script>` cannot break out of `<script>` block)
- [ ] CSP set with `default-src 'self'`; `'unsafe-inline'` minimized or removed
- [ ] No reflective rendering of unsanitized input from query/body/headers/cookies

## Data Protection

- [ ] No secrets in source code, commits, or git history
- [ ] `.env*` files in `.gitignore`; production secrets in a secret manager
- [ ] Sensitive fields (`passwordHash`, `mfaSecret`, `resetToken`, raw PII) excluded from API responses via a typed sanitizer
- [ ] PII encrypted at rest where applicable (column-level or full-disk plus key management)
- [ ] PII transmitted only over TLS 1.2+
- [ ] Backups encrypted; access audited
- [ ] Logs scrubbed of secrets, tokens, full PAN/credit-card, raw PII
- [ ] Exception trackers redact request bodies of sensitive endpoints
- [ ] Database connection strings use unique, scoped credentials per service

## Sessions & Cookies

- [ ] Auth tokens NOT in `localStorage` or any client-readable storage
- [ ] Session cookies: `httpOnly`, `Secure`, `SameSite=Lax|Strict`
- [ ] CSRF protection on cookie-authenticated POST/PUT/DELETE/PATCH (token or sameSite=Strict)
- [ ] Session fixation prevented (rotate session ID on login)
- [ ] Idle and absolute session timeouts configured
- [ ] Logout clears server-side session, not just the cookie

## CORS

- [ ] CORS origin list is an explicit allowlist (no `*` with credentials)
- [ ] Allowed methods/headers minimized to what the app actually needs
- [ ] Preflight (`OPTIONS`) returns correctly; no wildcard `Access-Control-Allow-Origin` reflection of arbitrary `Origin`

## Security Headers

- [ ] `Content-Security-Policy` configured (start strict, loosen with intent)
- [ ] `Strict-Transport-Security: max-age=31536000; includeSubDomains` (and `preload` for production)
- [ ] `X-Content-Type-Options: nosniff`
- [ ] `X-Frame-Options: DENY` or `frame-ancestors` in CSP
- [ ] `Referrer-Policy: strict-origin-when-cross-origin` (or stricter)
- [ ] `Permissions-Policy` restricts unused browser features (camera, geolocation, etc.)
- [ ] `Cache-Control: no-store` on responses containing sensitive data
- [ ] Verify in actual deployed responses (DevTools → Network → Headers), not just code

## Rate Limiting & Abuse

- [ ] Login, signup, password reset, MFA verify: strict rate limits per IP + identifier
- [ ] Public APIs have a baseline rate limit
- [ ] Expensive operations (search, exports, password hashes) limited
- [ ] CAPTCHA or proof-of-work on signup/contact forms exposed to internet
- [ ] Account lockout after repeated failures (with safe reset path)

## Dependencies

- [ ] `npm audit` (or `pip-audit`, `bundler-audit`, `cargo audit`, etc.) clean of critical/high in reachable runtime deps
- [ ] Lockfile committed
- [ ] Dependency update cadence defined (e.g. weekly Dependabot/Renovate)
- [ ] No deprecated or unmaintained packages on critical paths
- [ ] Subresource integrity (SRI) on third-party scripts loaded in browser

## Infrastructure

- [ ] HTTPS everywhere; HTTP redirects to HTTPS; HSTS preloaded
- [ ] Cloud secrets accessed via IAM roles where possible (not long-lived keys)
- [ ] Database not publicly accessible; reachable only from app subnet
- [ ] Server-side errors return generic 500 to user; details logged
- [ ] Stack traces never reach end users
- [ ] Build artifacts don't contain `.env`, source maps for production are stored privately or omitted
- [ ] Container/runtime patched; base image scanned

## Logging & Monitoring

- [ ] Auth events logged (login success/failure, password reset, role change)
- [ ] Authorization failures logged with enough detail to investigate
- [ ] Anomaly alerts on spikes (login failures, 403s, 500s)
- [ ] PII/secrets explicitly redacted from logs and traces
- [ ] Audit log for admin/destructive actions

## Incident Readiness

- [ ] Known steps to rotate every secret in use
- [ ] Known steps to invalidate all active sessions
- [ ] On-call contact list current
- [ ] Backup restore tested in last 6 months
- [ ] Disclosure / contact path published (`/.well-known/security.txt` or equivalent)

## Pre-Commit Greps (Quick Self-Check)

```bash
# Staged secrets
git diff --cached | grep -iE 'password|secret|api[_-]?key|token|bearer|private[_-]?key'

# Hardcoded URLs to staging/prod
git diff --cached | grep -iE 'http(s)?://[^/]*(staging|prod|internal)'

# eval / innerHTML / dangerouslySetInnerHTML
git diff --cached | grep -nE '\beval\(|innerHTML|dangerouslySetInnerHTML'

# String-built SQL
git diff --cached | grep -nE 'SELECT .* FROM .*\$\{|".*WHERE.*\+\s*'
```

If any of these match unexpectedly, stop and review before committing.
