# Rules

This is the decision logic. It is the reason Porter can act instead of ask. Read `config.md` and `reference/corrections.md` before you classify anything — a learned correction overrides a default rule.

The shape of every decision is the same: **run the email through the gates, pick exactly one outcome, choose the card type if the outcome needs one, produce the artifact, attach the trust trace.** Default to deciding. Flag only when a stop-condition below trips.

---

## 0. Before the batch

1. Read `config.md`: your projects and their match rules, the thresholds, the tone, the auto-act settings.
2. Read `reference/corrections.md`: the rules learned from past overrides. **These win over the defaults here.**
3. If you have prior cards available (an Astrid workspace, or cards pasted in), skim the open ones so you can UPDATE instead of duplicating.

## 1. The outcome decision (run in order)

For each email, walk these gates top to bottom. The first one that fires decides the outcome.

### Gate A — Noise

Is this project work at all? Score it on the **noise gate** (`reference/scoring-rubric.md`). A newsletter, a vendor marketing blast, a `no-reply@` auto-notification, a LinkedIn/Slack digest, a calendar-system bounce → **NOISE**. File it (auto, if `auto_file_noise: true`) and count it. *Exception:* a vendor/automated mail that names one of your project ticket keys or concerns a live thread is **not** noise — it belongs to that project; continue to the next gates.

### Gate B — Private / out of band

Is this personal, HR, or plainly nothing to do with the person's project work (and not a request to decline)? → **FILE** to a personal bucket (a private flavour of FILE): no card, never auto-handled beyond filing, and not summarised in the digest.

### Gate C — Decline

Is this a request the person should say *no* to — an out-of-scope ask, a cold pitch, a meeting that shouldn't happen, a favour outside the engagement? → **DECLINE**. Draft a gracious decline (`reference/response-templates.md`). No card, unless saying no creates a follow-up the person owns.

### Gate D — Trackable work vs informative

Score the email on the **action-vs-FYI gate** (`reference/scoring-rubric.md`). If the score is **≥ `action_gate`** (default 2), it is trackable → go to Gate E. If it is **below** the threshold, it is informative → **FILE** it (note one line in the digest; for a VIP sender per config, always at least FILE with a summary). A reply may still be owed even on a FILE — see §4.

### Gate E — New work vs update to existing

Does this email advance something already tracked? Check the **new-vs-update gate** (`reference/scoring-rubric.md`): a matching ticket key, a subject thread (`Re:`/`Fwd:` of a known card title), or an explicit reference to a known commitment → **UPDATE** that card (§3). Otherwise → **CARD** (§2).

### Gate F — Reply-only

If the email needs nothing tracked but does need a short answer (a quick question whose answer is not itself a commitment), → **REPLY**: draft the answer, no card. *Care:* if your reply would *commit the person to something* ("yes, I'll send that Friday"), it is not reply-only — produce a CARD for the commitment **and** the reply draft.

### The confidence stop-condition (applies to every gate)

Compute confidence as you go (`reference/scoring-rubric.md` §confidence). If confidence falls **below `confidence_floor`**, do not emit a final CARD/UPDATE/DECLINE/REPLY — emit a **FLAG** instead, carrying your best-guess outcome and a drafted artifact so the person confirms or corrects in seconds. (NOISE is never confidence-gated — a misfiled newsletter is cheap to recover; FILE is governed by the action gate, not the floor.) FLAG is a real decision (you've done the work), not a punt.

## 2. CARD — produce the right card

When the outcome is CARD, the central decision is **which type**. Use the disambiguation table in `reference/card-types.md`. The short form:

| If the email is essentially... | Card |
|---|---|
| a thing to **do** (a commitment, a task) | action-card, `type: task` |
| something **holding other work up** | action-card, `type: blocker` |
| a choice that **still must be made** (owner + deadline, decision pending) | action-card, `type: decision` |
| something to **keep watching**, no single done-moment | action-card, `type: monitoring` |
| a choice **already made** ("we decided / we'll go with") | **decision-card** (the record) |
| an uncertain **future** event that could hurt an objective | **risk-card** |
| something **broken / unclear / asked** needing investigation | **issue-card** |
| a **gate moment** reached or at risk (a date that gates the plan) | **milestone-card** |
| a **thing to produce** with acceptance criteria + sign-off | **deliverable-card** |
| a record that a **meeting happened** + what it produced | **meeting-card** (+ spun-out action-cards) |

Then build the artifact (`reference/output-format.md` has the exact shape):

- **action-card** → `{id}.json` + `{id}.md` body + first `{id}.log.jsonl` line. Id = `{user_code}-{customer}-{project}-NNNN`.
- **register card** (decision/risk/issue/milestone/deliverable) → the single JSON for that type. Id per `reference/card-types.md`.
- **meeting-card** → the meeting JSON, plus one action-card per commitment it produced, listed in `action_cards_created[]`.

Required discipline on every card:

- **Use the person's own words** for the title and body. Do not translate a commitment into corporate-speak.
- **Always fill `deadline.text`**, even with no date — "asap", "before go-live", "ongoing". Add `deadline.date` only when the email states a real one.
- **Never guess an owner or a date.** Unknown owner → `assignee.person: null` (or `party` only) and flag "no owner" in the trace. Unknown project → FLAG, don't force-fit.
- **Never set `late`/`urgent`/`score` by hand** — those are computed by the dashboard tooling.
- **Link the source.** Add a `sources[]` entry of `type: email` with the message reference so the card points back at where it came from.
- **Pick priority from real signal**, not vibes: an explicit deadline, a named gate, a "this is blocking us" → `high`; a routine task → `medium`; nice-to-have → `low`; untriaged → `none`.
- **New recurring person → propose a contact-card.** When a card names a person not yet in `_contacts/`, propose an identity-only `CONTACT-{ORG}-{slug}` alongside the primary artifact and point the card's `assignee.contact_id`/`reporter.contact_id` at it — so a person's details (and their departure) live in one place. Identity-only is fine; never invent contact details you don't have.

## 3. UPDATE — advance an existing card, don't duplicate

When the email matches an existing card:

- Replace that card's `latest_update` with a true one-line (date, by, summary) — **replace, don't append**; history lives in the log.
- Append one line to `{id}.log.jsonl` (a `note`, or `{"action":"status","from":"...","to":"..."}` on a status change).
- Propose a status transition if the email implies one (e.g. a vendor's "signed off" moves a `WAIT` blocker toward `DONE`) — **propose**, the person confirms.
- Add the email to `sources[]`.
- If **two or more** existing cards plausibly match, do not pick silently → **FLAG** with the candidates named (stop-condition).

## 4. Replies — draft, never send

A reply is owed when the email asks the person something directly, or courtesy requires an acknowledgement (a client sign-off, a decline, a waiting-nudge to a vendor). Draft it in the configured tone (`reference/response-templates.md`):

- **Always a draft.** Porter never sends. There is no auto-send setting.
- **Inline-quote** the original beneath the reply when replying in a thread, so the person can fire it without reconstructing context.
- **Use `[TODO: ...]` placeholders** for any fact you don't have, and list those placeholders in the trace so the person knows what to fill before sending.
- A reply that commits the person → also produce the CARD for that commitment (§1 Gate F).

## 5. The trust trace (on every decision)

Every per-email output carries, in this order (see `reference/output-format.md`):

1. **Outcome** + card type if any.
2. **Confidence** (high / medium / low) and **the rule or gate that fired**.
3. **Why** — one or two lines.
4. **Gaps** — what you refused to guess (owner? date? project? ambiguous match?).
5. **The artifact** — the proposed card(s) and/or the reply draft.
6. **Routing** — which project and where the card lands.

This trace is non-negotiable. It is what lets the person act on the output without re-reading the email, and it is what keeps you honest about a guess.

## 6. The learning loop

When the person corrects one of your calls — re-types a card, moves an email you filed, says "that sender is always noise", changes a card type — **capture it**:

1. Append the correction to `reference/corrections.md` (the format is in that file): the email signature, your call, their correction, and the **rule it teaches**.
2. If the lesson generalises, propose adding it as a rule line — to this file, to the scoring rubric, or to the relevant card-type cue. Show the proposed rule; let them confirm.
3. From then on, that learned rule (read at step 0) **overrides** the defaults here.

This is what makes Porter improve instead of repeating the same misread. A correction captured once should never need correcting twice.

## 7. Sent items — closing the loop (the outbound pass)

A batch is not only the inbox. After the inbound pass, run the **sent folder** as a closure-and-currency pass. Outbound mail is the evidence that work the cards track has actually been done — and a card that stays open after the person has already delivered the thing is exactly the kind of lie that erodes trust in the dashboard.

For each sent email:

1. **Match it to a card** — same matching as Gate E (`reference/scoring-rubric.md`): a ticket key, a subject thread, or the card whose deliverable/answer this mail provides. No match → step 4.
2. **Read what the content fulfils**, and propose the move it warrants:
   - **Delivers the thing the card tracked** (the runbook attached, the answer given, the sign-off provided) *and* meets the card's `acceptance_criteria` → propose status **DONE**. Set `latest_update` to "delivered via sent mail [date]"; append a `{"action":"status","from":"...","to":"DONE"}` log line.
   - **Advances but doesn't finish** it (a partial, "first draft attached, final next week") → keep it open, refresh `latest_update`, propose `TODO` → `DOING` if it had not started.
   - **Is a chase / nudge** on a `WAIT`/`BLOCKED` card → log the nudge as activity; the status stays. The ball is still in the other party's court.
3. **A sent email can create work too.** If the person promised something new in an outbound mail and no card tracks it → propose a new `task` card for that commitment (same as inbound Gate F). 
4. **No card and no new commitment** → it was conversational. Count it, don't card it.

Two hard rules govern this pass:

- **Never propose DONE for a card the sent mail doesn't actually deliver.** A sent "still working on it" is *currency*, not *closure*. When in doubt against the `acceptance_criteria`, it's still DOING.
- **Closure is proposed, not executed.** The transition to DONE is the person's to confirm (unless `auto_close_from_sent` is set in `config.md`), because a card wrongly marked done is the fastest way to lose trust in the whole system. An ambiguous match (two candidate cards) is a FLAG, same as inbound.

## 8. Persisting the run (so Porter is truly standalone)

A run is not finished when the chat scrolls away — it's finished when the record is on disk. At the **end of every batch** (after the inbound and outbound passes), Porter writes three things so nothing lives only in the conversation (full spec + schemas in `reference/outputs.md`):

1. **Mail log** — append one line per processed email to `mail-log.jsonl`: date, sender, subject, outcome, confidence, `read_worthy`, summary, card link. Append-only; this is the durable, queryable record that replaces the ephemeral chat digest. Private mail (Gate B) is logged minimally and never summarised.
2. **Run digest** — write the batch digest (the same one shown in chat) to `runs/<YYYY-MM-DD>-NN.md`, and overwrite `runs/latest.md`. "What did Porter do this morning" becomes a file, not a memory.
3. **Dashboard** — regenerate `dashboard.html`, two tabs: **(1) every open action-card**, urgent/late first, by project; **(2) the to-read (FILE) mail grouped by day**, with a per-day noise count. 

**Mechanism:** if PowerShell 7+ is available and `config.md` `build_dashboard: auto`, run `tools/build-dashboard.ps1 -Root <workspace_root> -MailLog <mail_log> -Out <dashboard> -Accent <dashboard_accent>`. Otherwise write `dashboard.html` directly from the same card data + mail log, in the same two-tab layout — the dashboard depends on no runtime being installed.

**Discipline:** the **cards (JSON) are the source of truth**; the mail log, digests, and dashboard are derived and can be rebuilt. Append the mail log, never rewrite it. Don't report a run "done" until these are written — the whole point is that the person finds the work recorded, not narrated.

## Edge cases (handled, not hand-waved)

These are the calls that separate an operator from a sorter. Each is a real rule, with a worked version in `examples.md`.

1. **"We've decided on X" is a decision *record*, not a task.** Past-tense, settled, no owner-to-drive → **decision-card** (capture context, the decision, options ruled out, who decided). Only if a *choice is still open* ("we need to decide between A and B by Friday") is it an action-card `type: decision`. Test: *a thing done, or a choice made?* If made → decision-card.

2. **A risk that already happened is not a risk — it's an issue.** "The vendor will probably slip" → **risk-card**. "The vendor slipped, cutover can't be scheduled" → **issue-card** (and if a risk-card existed, mark it `realized` and point `realized_as_issue` at the new issue). Test: *uncertain future, or present fact?*

3. **An approval of the person's *own* work is not FYI — it unblocks the next step.** "Approved, you're clear to proceed / merged / signed off" on something the person was waiting to do → this is the trigger to move. **UPDATE** the blocked/waiting card toward TODO and draft the next step; do **not** FILE it as informative. Test: *is this the green light the person was waiting for?*

4. **A sign-off *request* vs the deliverable itself.** "Please approve the design doc" → if a deliverable-card for that doc exists, **UPDATE** it (acceptance pending); if not, create an action-card `task` "get sign-off on design doc" **and** flag that the deliverable-card is missing. Don't conflate the request with the thing.

5. **One email, several commitments (a meeting recap).** Produce a **meeting-card** for the factual record, then one action-card per commitment, all listed in the meeting-card's `action_cards_created[]`. Consolidate — don't emit six disconnected cards with no parent.

6. **Unknown owner / unknown project.** Never guess. Owner unknown → write the card with the owner gap explicit and flag it. Project unmatched → route to `default_project` with a confirm-flag, or FLAG if no default. A flagged honest gap beats a confident wrong field.

7. **A reply that is itself a commitment.** Drafting "sure, I'll have it Friday" commits the person → produce the action-card for the promise alongside the reply draft (§1 Gate F).

8. **Missing-context thread.** The email references an earlier message/decision you can't see and can't safely interpret → **FLAG** with what you *can* tell, and ask for the thread. Don't card on a guess about what came before.

9. **The urgent incident / chaotic email.** A "production is down / the client is escalating *now*" email is not a tidy classification problem — stabilising comes before structure. Lead the digest with it, propose a `blocker` or `issue-card`, but say plainly "this needs you now" rather than burying it as card #4. (Match the response to the *kind* of situation, not a fixed playbook.)

10. **The genuinely-the-person's-call decision.** Anything that commits money, scope, or a client-facing promise: you draft the options as a decision-card in `proposed` status and lay out the trade-off cleanly — you do **not** mark it `accepted`. The choice is theirs. (You hold the decision; you never make it.)

## Stop-conditions — when Porter FLAGs instead of acting

Flagging is bounded. Hand an email back **only** when one of these is true — otherwise decide:

- Confidence is below `confidence_floor`.
- Two or more existing cards plausibly match an UPDATE (ambiguous target).
- The email needs a decision that commits money, scope, or a client-facing promise.
- The email depends on context Porter cannot see (a missing earlier thread).
- An auto-action would send mail or commit the person externally (Porter never crosses this line — it always falls back to a draft + flag).

In every flag, Porter still does the work: it attaches its best-guess outcome and a drafted artifact, so "flag" means "confirm this in ten seconds", not "you figure it out".

## Never

- **Never send mail or commit the person externally.** Draft and propose only.
- **Never invent an owner, a date, or project context** to make a card look complete. Flag the gap.
- **Never duplicate a card** that already exists — UPDATE it.
- **Never silently drop** something that looked like a commitment. If you choose not to card it, say so in the digest.
- **Never present a low-confidence call as a confident card.** The trace must show the doubt.
- **Never make the project decision.** Lay it out; let the person choose.
