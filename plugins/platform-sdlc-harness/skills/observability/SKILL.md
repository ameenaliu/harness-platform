---
name: observability
description: >
  Ensure new or changed code is observable in production — structured logging,
  distributed tracing, and error capture — across all surfaces: SERVICE
  (Serilog + OpenTelemetry traces/metrics), WEB and MOBILE (Sentry error capture,
  breadcrumbs, key user/business events). Load this in the Developer self-review
  and Reviewer Phase B so new endpoints, handlers, and screens ship with the
  instrumentation needed to debug and monitor them — without leaking PII into
  telemetry. Advisory — surfaces gaps; never auto-blocks.
user-invocable: true
---

# observability — logging, tracing & error capture

Code that can't be observed can't be operated. A new endpoint with no structured
log, a background job with no trace, or a screen whose errors never reach Sentry
are invisible until a customer reports the outage. This skill is the review lens
that makes operability a first-class part of "done" — the reviewer checklist
already gestures at logging; this makes it concrete and consistent.

## When to use it

- **Developer (Phase 3)**: when adding/changing an endpoint, message/job handler,
  integration call, or a user-facing flow, confirm it emits the right telemetry
  before committing.
- **Reviewer (Phase B)**: verify new code paths are instrumented; raise gaps as
  `[R<n>]` comments.

No tool to install — this is a conventions/review skill. The repo's existing
Serilog / OpenTelemetry / Sentry setup is the implementation; this defines what
"instrumented" means per surface.

## SERVICE (.NET — Serilog + OpenTelemetry)

- **Structured logging** (Serilog): log at meaningful boundaries (request handled,
  external call made, job started/finished, domain decision) with **structured
  properties**, not string-concatenated messages: `_logger.LogInformation("Order {OrderId} settled via {Provider}", id, provider)`. Right level: `Information` for business events, `Warning` for recoverable anomalies, `Error` for failures with the exception.
- **Tracing/metrics** (OpenTelemetry): new HTTP endpoints and message/job handlers
  participate in a trace (activity/span); long or external operations get their own
  span; key business counters/histograms where it aids monitoring. Propagate
  context across async/queue boundaries.
- **Correlation**: a correlation/trace id flows through logs + spans so a request
  is reconstructable end-to-end.
- **Errors**: exceptions are logged with structured context (not swallowed); the
  outbox/handler idempotency is observable.

## WEB & MOBILE (Sentry)

- **Error capture**: unhandled errors and rejected promises reach Sentry; React
  error boundaries (web) / the RN error handler (mobile) are in place for new
  feature roots. Caught-but-significant errors use `Sentry.captureException` with
  context — not a silent `catch {}`.
- **Breadcrumbs / context**: navigation + key actions leave breadcrumbs; set user
  scope (id only — never PII) and release/environment so issues are triageable.
- **Key events**: meaningful business/user events (signup, payment, core action)
  are tracked where the product needs the signal — consistently, not ad hoc.
- **Performance**: new screens/routes can be traced (Sentry tracing) where latency
  matters; complements `react-doctor` / `bundle-budget`.

## PII / data-policy guardrail (all surfaces)

Telemetry is still data egress. **Never log or attach PII or secrets** — no raw
emails, phone numbers, tokens, full payment details, BVN/NIN, coordinates tied to
a person. Log ids and structural facts, not values. This is the same line the
data-policy hooks enforce on source; it applies to log/Sentry payloads too.

## How to interpret (harness policy — advisory)

- **Scoped to new/changed code paths** — don't retrofit instrumentation across
  untouched legacy as part of the Story.
- **Developer**: add the missing log/span/capture before committing; remove any
  PII you were about to log.
- **Reviewer**: raise an un-instrumented new endpoint/handler/screen, a swallowed
  error, or PII-in-telemetry as `[R<n>]` (PII → `CRITICAL`); read-only — no edits.
- Advisory — never hard-blocks.

## See also

- [`dotnet-conventions`](../dotnet-conventions/SKILL.md) — SERVICE Serilog/OpenTelemetry setup.
- [`react-turbo-conventions`](../react-turbo-conventions/SKILL.md) / [`expo-mobile-conventions`](../expo-mobile-conventions/SKILL.md) — Sentry init points + logging rules per surface.
- [`security-scan`](../security-scan/SKILL.md) — overlapping concern: secrets must not reach telemetry either.
