# Corrections ledger — how Porter learns

This is what turns Porter from a fixed sorter into an operator that gets your inbox *right* over time. When you override one of Porter's calls — you re-type a card, move an email it filed, change a card type, or tell it "that sender is always noise" — the lesson is captured here, and Porter reads this file **before** classifying anything. A learned rule here **overrides** the defaults in `rules.md` and `reference/scoring-rubric.md`.

The discipline: a correction made once should never need making twice.

---

## How a correction is captured

When the person corrects a call, Porter appends an entry in this shape, then proposes the generalised rule (and, if the person confirms, adds it to the **Learned rules** section at the top so it's applied from the next run):

```
### <date> — <short signature of the email>
- Porter's call:   <what Porter decided>
- Correction:      <what the person changed it to>
- Lesson:          <the generalisable rule>
- Applied as:      <a Learned rule below | a one-off, too specific to generalise>
```

Porter only promotes a correction to a **Learned rule** when it generalises (a sender, a pattern, a phrase, a routing policy). A genuinely one-off fix is logged for the audit trail but not turned into a rule — over-generalising is its own failure mode.

---

## Learned rules (in force, highest precedence)

> These are read at step 0 of every batch and win over the default logic. A rule appears here only once it is **in force**. A rule learned *during* the current run takes effect from the **next** run — which is exactly why Porter can still FLAG something in the run where it first learns the answer (see the invoice entry in the log below). Add your own as you correct Porter.

1. **Dr. Lena Voss (Brio sponsor) is never auto-filed.** Any email from the project sponsor gets at least a FILE with a one-line summary in the digest, even when it scores below the action gate — sponsor signal is worth surfacing regardless of content.

*Learned 2026-06-09, in force from the next run:*

2. **Invoices → finance, then FILE.** Emails from `billing@` that name a project ticket key are **not** carded as project work; they are FILEd with a one-line digest note "invoice — forward to finance". Promoted from the 2026-06-09 correction below. Exception: an invoice that's genuinely disputed or blocks a deliverable is an issue-card, not a routine FILE.

---

## Correction log (full history, newest first)

> Empty to start. Each override the person makes lands here. Two worked examples below show the shape; delete them once you have real entries, or leave them as a reference.

### 2026-06-09 — Northwind "Invoice — May services (ACLD-552)"
- Porter's call:   FLAG — unsure whether invoices get carded or sent to finance.
- Correction:      Person: "invoices always go to finance, just file them."
- Lesson:          `billing@` emails naming a ticket key → FILE + "forward to finance" note, not a card.
- Applied as:      Learned rule #2 — in force from the run *after* 2026-06-09. It was novel during this run, so Porter correctly FLAGged it; the loop is working, not contradicting itself.

### 2026-06-09 — newsletter mis-filed as informative (illustrative)
- Porter's call:   FILE (informative) — a vendor "product update" email scored 0 on the action gate.
- Correction:      Person moved it to noise: "anything from `updates@` is noise."
- Lesson:          Treat `updates@<vendor>` as a marketing address (noise −3), same as `news@`/`marketing@`.
- Applied as:      a one-off sender pattern — narrow; logged, not yet promoted (promote if it recurs across senders).

---

## Why this matters for trust

The first week, Porter will misjudge a handful of calls — every operator does, because your inbox has conventions no generic rubric knows. The corrections ledger is the mechanism that makes those misjudgements **temporary**. Each one you fix tightens the rubric, and within a couple of weeks the flags drop to the genuinely-ambiguous and the genuinely-yours-to-decide. An operator that repeats the same misread every day is one you stop trusting; an operator that learns the convention the first time you state it is one you let run unattended.
