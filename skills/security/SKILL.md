---
name: security
description: Use when building anything that takes user input, implements authentication or authorization, stores or transmits sensitive data, integrates external APIs, accepts file uploads, handles webhooks or callbacks, processes payments, handles PII, or sets up CORS, cookies, headers, secrets, or rate limits
---

# Security

## Overview

Security-first development for code that touches user input, auth, secrets, or external systems. Security is not a phase — it is a constraint on every line that crosses a system boundary.

**Core principle:** Treat every external input as hostile, every secret as sacred, every authorization check as mandatory.

## The Iron Law

```
ALL EXTERNAL INPUT IS HOSTILE UNTIL VALIDATED AT THE SYSTEM BOUNDARY
```

If input crosses a process boundary (HTTP, file upload, webhook, env var, message queue, third-party response), validate it at the entry point. No exceptions. No "we'll trust this one." No "internal only."

Thinking "this case is different"? It isn't. That's rationalization.

## When to Use

- Building anything that accepts user input (forms, query params, request bodies, uploads)
- Implementing authentication or authorization (login, sessions, tokens, RBAC)
- Storing or transmitting sensitive data (PII, payment info, health data, secrets)
- Integrating external APIs, webhooks, or callbacks
- Handling file uploads
- Configuring CORS, cookies, security headers, rate limits
- Touching anything in `.env`, secrets management, or credential code paths
- Reviewing dependency vulnerabilities (`npm audit`, `pip-audit`, etc.)

## Three-Tier Boundary System

### Always Do (No Exceptions)

- **Validate all external input** at the system boundary (route handlers, message consumers, file ingest)
- **Parameterize every database query** — never concatenate user input into SQL/NoSQL/shell
- **Encode output** to prevent XSS — use framework auto-escaping, do not bypass it
- **Use HTTPS** for all external communication
- **Hash passwords** with bcrypt/scrypt/argon2 (salt rounds ≥ 12). Never store plaintext.
- **Set security headers** (CSP, HSTS, X-Frame-Options, X-Content-Type-Options, Referrer-Policy)
- **Use httpOnly, secure, sameSite cookies** for sessions
- **Run `npm audit` / equivalent** before every release
- **Authorize on every protected endpoint** (authenticated ≠ authorized)

### Ask First (Requires Human Approval)

- New authentication flows or changes to existing auth logic
- Storing new categories of sensitive data (PII, payments, health)
- New external service integrations (especially anything handling secrets)
- CORS configuration changes
- New file upload handlers
- Changes to rate limiting, throttling, or quota policy
- Granting elevated permissions, roles, or scopes

### Never Do

- **Never commit secrets** to version control (API keys, passwords, tokens, certs)
- **Never log sensitive data** (passwords, tokens, full card numbers, raw PII)
- **Never trust client-side validation** as a security boundary — re-check on the server
- **Never disable security headers** for convenience
- **Never use `eval()` or `innerHTML`** with user-provided data
- **Never store auth tokens in localStorage** or other client-accessible storage
- **Never expose stack traces** or internal error details to end users
- **Never use a query-param "secret" as authentication** (logged everywhere, leaks via Referer)

## OWASP Top 10 Prevention

### 1. Injection

```typescript
// BAD — string concatenation
const q = `SELECT * FROM users WHERE id = '${userId}'`;

// GOOD — parameterized
const user = await db.query('SELECT * FROM users WHERE id = $1', [userId]);

// GOOD — ORM with typed input
const user = await prisma.user.findUnique({ where: { id: userId } });
```

Same rule applies to shell commands (`execFile` with arg array, never `exec` with string), NoSQL ($where, regex injection), LDAP, XPath, and template engines.

### 2. Broken Authentication

```typescript
import { hash, compare } from 'bcrypt';
const SALT_ROUNDS = 12;
const hashed = await hash(plaintext, SALT_ROUNDS);
const ok = await compare(plaintext, hashed);
```

```typescript
app.use(session({
  secret: process.env.SESSION_SECRET,        // env, never hardcoded
  resave: false,
  saveUninitialized: false,
  cookie: { httpOnly: true, secure: true, sameSite: 'lax', maxAge: 86_400_000 },
}));
```

### 3. Cross-Site Scripting (XSS)

```tsx
// BAD
element.innerHTML = userInput;

// GOOD — framework auto-escapes
return <div>{userInput}</div>;

// If raw HTML is unavoidable, sanitize
import DOMPurify from 'dompurify';
const clean = DOMPurify.sanitize(userInput);
```

### 4. Broken Access Control

Authentication answers "who are you." Authorization answers "may you do this to *that* resource." Both are required.

```typescript
app.patch('/api/tasks/:id', authenticate, async (req, res) => {
  const task = await taskService.findById(req.params.id);
  if (task.ownerId !== req.user.id) {
    return res.status(403).json({ error: { code: 'FORBIDDEN' } });
  }
  return res.json(await taskService.update(req.params.id, req.body));
});
```

### 5. Security Misconfiguration

```typescript
import helmet from 'helmet';
app.use(helmet());                      // CSP, HSTS, frameguard, etc.
app.use(cors({
  origin: process.env.ALLOWED_ORIGINS?.split(',') ?? false,  // never `*` with credentials
  credentials: true,
}));
```

### 6. Sensitive Data Exposure

```typescript
function toPublicUser(u: UserRecord): PublicUser {
  const { passwordHash, resetToken, mfaSecret, ...rest } = u;
  return rest;
}
```

Apply this at the response boundary, not "somewhere in the service." Add a type-level distinction (`UserRecord` vs `PublicUser`) so the compiler enforces it.

## Input Validation at Boundaries

### Schema Validation

Validate at the route handler, before any business logic touches the data.

```typescript
import { z } from 'zod';

const CreateTaskSchema = z.object({
  title: z.string().min(1).max(200).trim(),
  description: z.string().max(2000).optional(),
  priority: z.enum(['low', 'medium', 'high']).default('medium'),
  dueDate: z.string().datetime().optional(),
});

app.post('/api/tasks', async (req, res) => {
  const parsed = CreateTaskSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(422).json({
      error: { code: 'VALIDATION_ERROR', details: parsed.error.flatten() },
    });
  }
  const task = await taskService.create(parsed.data);
  return res.status(201).json(task);
});
```

### File Upload Safety

```typescript
const ALLOWED = new Set(['image/jpeg', 'image/png', 'image/webp']);
const MAX = 5 * 1024 * 1024;

function validateUpload(file: UploadedFile) {
  if (!ALLOWED.has(file.mimetype)) throw new ValidationError('type not allowed');
  if (file.size > MAX) throw new ValidationError('too large (max 5MB)');
  // For security-critical paths, verify magic bytes — do not trust mimetype alone.
  // Always strip path components from filenames before storing.
}
```

Defenses to layer in: virus scan for user-shared content, store outside the web root, serve from a separate origin, randomize stored filenames.

## Triaging npm audit

Not every audit finding blocks shipping. Use this decision tree:

```
npm audit reports a vulnerability
├── critical or high
│   ├── Reachable in your code path?
│   │   ├── YES → fix immediately (update / patch / replace)
│   │   └── NO  (dev-only or unused) → fix soon, not blocking
│   └── Fix available?
│       ├── YES → update to patched version
│       └── NO  → workaround, replace dep, or allowlist with review date
├── moderate
│   ├── Reachable in production → fix next release
│   └── Dev-only → backlog
└── low
    └── Track and fix during routine dependency updates
```

When you defer, **document the rationale and a review date** — otherwise it never gets fixed.

## Secrets Management

```
.env.example   → committed, placeholder values only
.env           → NOT committed (real secrets)
.env.local     → NOT committed (local overrides)

.gitignore must include:
  .env
  .env.local
  .env.*.local
  *.pem
  *.key
```

```bash
# Pre-commit grep for accidentally staged secrets
git diff --cached | grep -iE 'password|secret|api[_-]?key|token|bearer'
```

For production, prefer a real secret manager (AWS Secrets Manager, Vault, Doppler, GCP Secret Manager) over `.env` files on disk. Rotate on a schedule.

## Rate Limiting

```typescript
import rateLimit from 'express-rate-limit';

app.use('/api/',     rateLimit({ windowMs: 15*60_000, max: 100 }));
app.use('/api/auth', rateLimit({ windowMs: 15*60_000, max: 10  }));  // stricter
```

Auth endpoints, password reset, and any expensive operation need stricter limits than general traffic.

## Pre-Deploy Checklist

For the full pre-deploy security review checklist (auth, authz, input, data, infrastructure), see `security-checklist.md` in this skill directory.

## Common Rationalizations

| Rationalization                                    | Reality                                                                                                                |
|----------------------------------------------------|------------------------------------------------------------------------------------------------------------------------|
| "Internal tool, security doesn't matter"           | Internal tools get compromised. Attackers target the weakest link, then pivot.                                         |
| "We'll add security later"                         | Retrofitting is 10x harder. Auth bolted on after the fact misses authorization checks. Add it now.                     |
| "No one would exploit this"                        | Automated scanners find it within hours of going public. Security by obscurity is not security.                        |
| "The framework handles it"                         | Frameworks provide tools, not guarantees. Helmet doesn't help if you `app.use(helmet({ contentSecurityPolicy: false }))`. |
| "It's just a prototype"                            | Prototypes become production. Build security habits from day one.                                                       |
| "It's behind a VPN / firewall / SSO"               | Defense in depth. The next breach pivots through an authenticated employee or a compromised service account.            |
| "The user is authenticated, that's enough"         | Authentication ≠ authorization. Authenticated users still need ownership and role checks per resource.                  |
| "We'll just trust this one input — it's from us"   | Service-to-service inputs are still external. Today's "internal" service is tomorrow's compromised service.             |
| "Adding validation will slow the team down"        | Schema validation at boundaries is faster than debugging injection bugs in production.                                  |
| "I'll harden it before launch"                     | "Before launch" is the most common time security work gets cut. Bake it in from the first commit.                       |
| "It's a query param secret, easy to rotate"        | Query params land in logs, browser history, Referer headers, analytics. Use a header, a cookie, or a signed token.      |
| "Nobody will guess this URL"                       | URLs leak via referrer, browser history, sharing, screenshots, exception trackers. URLs are not secrets.                |

## Red Flags — STOP and Reassess

- User input flowing directly into SQL, shell, HTML, eval, or template strings
- Secrets, tokens, or private keys in source code, commit history, or logs
- Endpoints with authentication but no per-resource authorization check
- CORS using `*` with `credentials: true`
- Missing rate limit on auth, password reset, or expensive endpoints
- Stack traces or internal errors returned to end users
- Auth tokens stored in `localStorage` or readable cookies
- Query-param "secrets" used as authentication (`?admin_key=...`, `?token=...`)
- File upload that trusts `mimetype` or extension alone, or stores under the web root
- `npm audit` shows critical/high in a runtime dependency on a reachable path
- Disabled security headers ("temporarily, for debugging")
- "We'll add auth later" appears anywhere in the plan

If you see any of these, **stop and address before continuing**.

## Verification

After implementing security-relevant code:

- [ ] Every external input has schema validation at the boundary
- [ ] Every database/shell/template call uses parameterized inputs
- [ ] Every protected endpoint checks both authentication AND authorization
- [ ] No secrets in source, history, or logs (`git log -p | grep -iE 'password|secret|key|token'`)
- [ ] Sensitive fields are stripped from API responses by a typed sanitizer
- [ ] Security headers present in actual responses (verified in browser DevTools)
- [ ] CORS allowlist is explicit; no wildcard with credentials
- [ ] Rate limits on auth, password reset, and expensive operations
- [ ] `npm audit` (or equivalent) shows no critical/high in reachable runtime deps
- [ ] Errors returned to users contain no stack traces or internal details
- [ ] Cookies are httpOnly + secure + sameSite where applicable
- [ ] File uploads validate type, size, and store outside the web root

Can't check every box? Treat the gap as a Red Flag and address before merge.

**REQUIRED SUB-SKILL:** Use superpowers:requesting-code-review before merging anything that touches auth, secrets, or external input.

---

> Translated and adapted from [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills) (MIT License).
