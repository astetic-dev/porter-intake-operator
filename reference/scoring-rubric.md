# Scoring rubric — the deterministic gates

"Use good judgement" is not a rule. These are the rules. Each gate is a small, explicit calculation Porter runs so its calls are consistent run-to-run and reproducible by a person checking its work. The thresholds live in `config.md` (`action_gate`, `confidence_floor`) so you can tune behaviour without rewriting logic.

The gates run in the order set by `rules.md` §1. This file defines each one's arithmetic.

---

## Gate A — Noise score

Decide whether the email is project work at all. Start at 0; sum the signals:

| Signal | Δ |
|---|---|
| Sender is a known marketing/newsletter address (`news@`, `marketing@`, `digest@`, social notifications) | −3 |
| Sender is `no-reply@` / `noreply@` and body is an auto-notification | −2 |
| Body contains an unsubscribe link / "you're receiving this because" | −2 |
| Sender domain is in a project's `match.domains` | +2 |
| Body names a project ticket key (`match.ticket_prefixes`) | +3 *(overrides noise — see below)* |
| Body names a project keyword or a known person | +1 each (max +3) |
| Addressed personally to the user (To:, not bulk) | +1 |

**Decision:** total **≤ −2** → **NOISE**. A ticket-key match (`+3`) is a hard override: even from `billing@`/`no-reply@`, an email that names a live project key is **not** noise — it routes to that project (and may still FLAG if the handling policy is unclear, as in `examples.md` Ex. 5). Anything not NOISE proceeds to the later gates.

---

## Gate D — Action-vs-FYI score

For emails that are project work, decide trackable-work vs informative. Start at 0:

| Signal | Δ |
|---|---|
| A request/question is directed **at the person** ("can you", "could you", "please") | +2 |
| A **deadline or date** is stated or implied ("by Friday", "before go-live") | +2 |
| A **decision or sign-off** is requested | +2 |
| Something is reported **broken / blocked / at risk** | +2 |
| A **commitment** is made (theirs or the person's) | +2 |
| The person is **only CC'd**, with no ask | −2 |
| It's a **status update / FYI** with no action | −1 |
| It's an **automated notification** of a state change (ticket closed, build passed) | −1 |

**Decision:** total **≥ `action_gate`** (default 2) → trackable → continue to Gate E (UPDATE vs CARD). **Below** → **FILE** (informative); note one line in the digest. Tune `action_gate` down to capture more eagerly, up to capture less.

> Worked: "Can you send the runbook before the 20th?" = +2 (request) +2 (deadline) = **4 → trackable.** "FYI, ticket ACLD-118 was closed" = −1 (automated state change) = **−1 → FILE.**

---

## Gate E — New-card-vs-update score

Decide whether to UPDATE an existing card or create a new one. Match the email against known open cards:

| Match signal | Strength |
|---|---|
| Email names a ticket key that's in a card's `sources[]`/`tags[]` | strong |
| Subject (stripped of `Re:`/`Fwd:`) matches a card title or earlier source | strong |
| The email is the awaited reply on a `WAIT`/`BLOCKED` card (the party that owes the thing is the sender) | strong |
| Same project + same topic, but no specific card reference | weak |

**Decision:** exactly **one strong match** → **UPDATE** that card. **No match** (or weak only) → **CARD** (new). **Two or more strong matches** → **FLAG** (ambiguous target — name the candidates; never pick silently). This is a stop-condition, not a coin-flip.

---

## Confidence

Confidence governs whether Porter acts on its own call or FLAGs it for confirmation. Assign per email:

**HIGH** — all of:
- The outcome gate fired cleanly (comfortably past its threshold, not on the boundary).
- The project routed on a strong signal (domain, ticket key, or named person).
- The card type is unambiguous on the disambiguation table.
- No required field had to be guessed (gaps, if any, are genuinely optional fields).

**MEDIUM** — the call is sound but one of these holds:
- A gate score sat near its threshold (within 1).
- The project matched on keywords only, not domain/key.
- The card type was a judgement between two plausible rows.
- A non-critical field is unknown and flagged.

**LOW** — any of these:
- A **required** field (owner, project, the core "what is this") can only be guessed.
- The email depends on context Porter can't see.
- Two outcomes scored within 1 of each other and the tie isn't clearly breakable.
- The call commits money, scope, or a client-facing promise.

**Action by confidence vs `confidence_floor` (default `medium`):**
- **At or above the floor** → Porter acts: emits the final CARD/UPDATE/DECLINE/REPLY and its trace.
- **Below the floor** → Porter **FLAGs**: it still produces its best-guess outcome and a drafted artifact, but labels it for confirmation rather than presenting it as settled. (See `rules.md` §5 and the stop-conditions.)

Raising `confidence_floor` to `high` makes Porter flag more and decide less — useful while you're calibrating it in the first week, then lower it back to `medium` once the corrections ledger has tightened its calls.

---

## Why scores, not vibes

Three reasons this is arithmetic and not "judgement":

1. **Consistency.** The same email gets the same call on Tuesday as on Friday. An operator you can't predict is one you end up double-checking.
2. **Auditability.** When Porter says "action score 6", the person can see exactly which signals fired and disagree with one — and that disagreement becomes a `corrections.md` rule.
3. **Tunability.** Two numbers in `config.md` shift the whole behaviour. You calibrate the operator without touching its logic.

The scores are a floor, not a ceiling. A clear edge-case rule in `rules.md` (a settled decision, a realised risk, an own-approval-that-unblocks) overrides the arithmetic — the rubric handles the gradient, the named rules handle the cliffs.
