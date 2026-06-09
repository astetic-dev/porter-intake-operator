# Examples

Worked decisions, verbatim — the input email and exactly what Porter returns. These use the sample config from `config.md` (user `SR`, projects `ACME-CLOUD` and `BRIO-PORTAL`) and a working date of **2026-06-09**. The last section shows a full **batch digest** across several emails at once.

Read these to calibrate. Notice that every decision shows its confidence and the rule that fired, that gaps are flagged rather than guessed, and that the hard edge cases (a decision record, a risk that became an issue, an approval that unblocks work, an ambiguous match) each resolve to a specific, defensible call.

---

## Example 1 — a plain commitment (CARD → action-card / task)

**Inbound:**

> From: Mark Thompson <mark.thompson@acmelogistics.com>
> Subject: OrderHub runbook
> Date: 2026-06-09
>
> Sam — can you put together the cutover runbook for OrderHub and get it to me before the go-live review on the 20th? Needs the rollback steps spelled out, the team got nervous about that last time.

**Porter:**

> **Outcome:** CARD → action-card, `type: task`
> **Confidence:** high — Gate D action score 4 (direct request to me +2, deadline +2). New work (no existing card matches). Routed to ACME-CLOUD on keyword "OrderHub" + sender domain.
> **Why:** A direct, dated commitment the person owns. Clear thing-to-do with an acceptance signal (rollback steps spelled out). Priority `high` because the deadline gates the go-live review.
> **Gaps:** none — owner is the person (me/SR), deadline date is explicit.
> **Also proposed:** identity-only `CONTACT-ACME-mark-thompson` (first sighting of Mark as a recurring contact); the card's `reporter.contact_id` points at it.

Proposed card `SR-ACME-CLOUD-0012.json`:

```json
{
  "schema_version": 2,
  "id": "SR-ACME-CLOUD-0012",
  "title": "Write the OrderHub cutover runbook with rollback steps",
  "status": "TODO",
  "type": "task",
  "priority": "high",
  "project": { "user_code": "SR", "customer_code": "ACME", "project_code": "CLOUD", "full_name": "Acme Logistics — Cloud platform migration" },
  "assignee": { "party": "me", "person": "Sam Rivera" },
  "reporter": { "party": "customer", "person": "Mark Thompson" },
  "deadline": { "date": "2026-06-20", "text": "before the go-live review on the 20th" },
  "created": "2026-06-09T00:00:00Z",
  "updated": "2026-06-09T00:00:00Z",
  "sources": [{ "type": "email", "ref": "email/2026-06-09-orderhub-runbook", "note": "request from Mark Thompson (Acme)" }],
  "acceptance_criteria": ["Runbook covers the cutover steps", "Rollback steps are explicit (raised as a concern from last time)"],
  "tags": ["cutover", "runbook"]
}
```

`SR-ACME-CLOUD-0012.md` body: Context (Mark asked for the OrderHub runbook ahead of the 20th go-live review; rollback detail is the sensitive part) / Next step (draft the runbook, lead with rollback). First log line: `{"ts":"2026-06-09T00:00:00Z","who":"porter","action":"created","note":"from email, request by Mark Thompson"}`.

> **Reply:** drafted — short acknowledgement confirming the 20th, flagging I'll lead with the rollback section. *(Draft only; send when ready.)*

---

## Example 2 — the decision-record trap (CARD → decision-card, NOT a task)

**Inbound:**

> From: Priya Nair <priya.nair@acmelogistics.com>
> Subject: Re: cutover approach
> Date: 2026-06-09
>
> Following yesterday's call — we're going with the phased cutover, region by region, rather than the single-weekend big-bang. Risk team was clear they want the rollback window per region. Calling it settled so the team can plan around it.

**Porter:**

> **Outcome:** CARD → **decision-card** (not an action-card)
> **Confidence:** high — edge-case rule 1 fired: past-tense, settled, no choice left to drive ("calling it settled"). A *thing decided*, not a *thing to do*. Routed to ACME-CLOUD.
> **Why:** This is the recorded outcome of a decision, with an option explicitly ruled out (big-bang). That is a decision-card (an ADR), not a task. A task here would be the wrong artifact — there's nothing left to drive.
> **Gaps:** the decision-maker is named loosely ("we" + risk team). Recorded `party: customer` with `person: Priya Nair` as the one who communicated it; flagged that the formal owner may be the steering group — confirm.

Proposed `DEC-ACME-CLOUD-002.json`:

```json
{
  "schema_version": 1,
  "id": "DEC-ACME-CLOUD-002",
  "project_id": "ACME-CLOUD",
  "title": "Phased region-by-region cutover over single-weekend big-bang",
  "status": "accepted",
  "date": "2026-06-09",
  "context": "Cutover approach for the OrderHub migration had to be settled so the team could plan. Choice was a phased region-by-region rollout vs a single-weekend big-bang. Risk team required a per-region rollback window.",
  "decision": "We will cut over region by region, with a defined rollback window per region.",
  "consequences": "Lower blast radius and a real rollback path per region; longer overall cutover calendar and more coordination overhead across regions.",
  "decision_drivers": ["Risk team requirement for a per-region rollback window", "Reduce blast radius of a failed cutover"],
  "options_considered": [
    { "option": "Phased region-by-region", "pros": ["Per-region rollback", "Smaller blast radius"], "cons": ["Longer calendar"], "chosen": true },
    { "option": "Single-weekend big-bang", "pros": ["Shorter calendar"], "cons": ["No staged rollback", "High blast radius"], "chosen": false }
  ],
  "decision_makers": [{ "party": "customer", "person": "Priya Nair" }],
  "tags": ["cutover"]
}
```

> **Follow-on:** proposed one action-card `SR-ACME-CLOUD-0013` (`task`, "Rework the cutover plan to per-region phasing + rollback windows") linked via the decision-card's `action_cards[]`, because the decision sets real work in motion. *Flagged the decision-maker ownership question for confirmation.*

---

## Example 3 — the approval that unblocks (UPDATE, not FILE)

**Inbound:**

> From: Amir Haddad <amir.haddad@northwind-cloud.com>
> Subject: Re: landing-zone sign-off
> Date: 2026-06-09
>
> Sam — internal review done our side. Landing-zone design is signed off, including the backup config. You're clear to schedule the first cutover.

**Context Porter has:** open card `SR-ACME-CLOUD-0001` — `type: blocker`, `status: WAIT`, "Get written landing-zone sign-off from Northwind", blocking `SR-ACME-CLOUD-0002` (first cutover).

**Porter:**

> **Outcome:** UPDATE `SR-ACME-CLOUD-0001` (matched on subject thread + the live blocker it answers)
> **Confidence:** high — edge-case rule 3 fired: this is the green light the person was waiting on. Not FILE/informative — it releases blocked work.
> **Why:** The blocker's exact condition (written sign-off incl. backup config) is now met. The blocker can close and the cutover (0002) it was holding can move.
> **Gaps:** none.

Update applied to `SR-ACME-CLOUD-0001`:

- `latest_update` → `{ "date": "2026-06-09", "by": "Amir Haddad (Northwind)", "summary": "Landing-zone signed off incl. backup config. First cutover (0002) is unblocked and can be scheduled." }`
- Proposed status: `WAIT` → `DONE` (confirm).
- Log line appended: `{"ts":"2026-06-09T00:00:00Z","who":"porter","action":"status","from":"WAIT","to":"DONE","note":"written sign-off received"}`.
- Source added: `{ "type": "email", "ref": "email/2026-06-09-landingzone-signoff" }`.
- **Down-link nudge:** `SR-ACME-CLOUD-0002` (first cutover) is now unblocked → proposed moving it `BLOCKED`/`PLAN` → `TODO` and drafted a one-line next step ("schedule first cutover, per-region per DEC-ACME-CLOUD-002").

> **Reply:** drafted — thanks Amir, confirms we'll schedule the first cutover. *(Draft only.)*

---

## Example 4 — the risk that already happened (CARD → issue-card, not risk-card)

**Inbound:**

> From: Tomas Reic <tomas.reic@briohealth.org>
> Subject: SSO broken in staging
> Date: 2026-06-09
>
> Heads up — since this morning the SSO login on the patient portal staging env throws a 500 for every user. The appointment-widget demo to Dr. Voss is Thursday. Can someone look at this today?

**Porter:**

> **Outcome:** CARD → **issue-card** (+ a fix action-card)
> **Confidence:** high — edge-case rule 2: this is a present fact ("throws a 500 for every user"), not an uncertain future event, so it's an issue, not a risk. Routed to BRIO-PORTAL on keyword "SSO"/"portal" + sender domain.
> **Why:** Something is broken and needs investigation/fix, with a near gate (Thursday demo to the sponsor). Issue-card logs *what's broken*; the fix is driven as an action-card.
> **Gaps:** owner of the fix unknown — Tomas reported it but didn't say who's fixing. Wrote the fix card with `assignee.person: null` and flagged "no owner — assign before Thursday".

Proposed `ISS-BRIO-PORTAL-0007.json` (severity high — blocks the demo; status `open`), plus action-card `SR-BRIO-PORTAL-0031` (`type: task`, `priority: high`, "Diagnose & fix SSO 500 on portal staging", `deadline.text: "before Thu demo to Dr. Voss"`, `assignee.person: null`), linked from the issue's `action_cards[]`.

> **Lead-with note for the digest:** this is the closest thing to an incident in the batch and it has a sponsor demo behind it — surfaced at the top, with the open owner gap called out.

---

## Example 5 — ambiguous match (FLAG, with best guess attached)

**Inbound:**

> From: billing@northwind-cloud.com
> Subject: Invoice — May services
> Date: 2026-06-09
>
> Please find attached the invoice for May. Ref: ACLD-552. Payment terms net 30.

**Porter:**

> **Outcome:** FLAG (stop-condition: needs a call that isn't mine to make on my own + sender is a `billing@` noise-candidate that nonetheless names a project ticket key)
> **Confidence:** low — Gate A nearly filed this as NOISE (`billing@`), but it names `ACLD-552`, a project ticket prefix, which overrides the noise call. Whether an invoice should become a project card or go straight to finance is a routing policy I don't have.
> **Why:** Genuinely ambiguous, and the **first invoice Porter has seen for this project** — no learned rule covers it yet. It touches a project (ACLD- key) but invoice handling may live entirely outside the card system. I won't guess the policy.
> **Best-guess proposal (attached):** if invoices *should* be tracked, an action-card `task` "Approve/forward May Northwind invoice (ACLD-552)" routed to ACME-CLOUD, `priority: low`. If not, this is FILE.
> **Asked:** "Do invoices get carded, or forwarded to finance and filed? Tell me once and I'll add the rule." — the one-line answer becomes Learned rule #2 in `corrections.md` (see that file), and from the next run this stops being a flag forever. *This is the learning loop in action: flag the genuinely-novel once, never again.*

---

## Example 6 — pure noise (NOISE, auto-filed)

**Inbound:**

> From: news@atlassian.com — "5 ways to level up your Jira workflows this quarter"

**Porter:** **NOISE** — vendor newsletter, no project ticket key, `auto_file_noise: true`. Filed, counted, not summarised. (One line in the digest's noise tally.)

---

## Example 7 — the outbound pass: a sent email closes a card (UPDATE → DONE)

This one is from the **Sent folder**, not the inbox. The outbound pass is how work gets closed (`rules.md` §7).

**Sent:**

> From: Sam Rivera
> To: Mark Thompson <mark.thompson@acmelogistics.com>
> Subject: Re: UAT test plan — attached
> Date: 2026-06-09
>
> Mark — attached is the final UAT test plan I agreed to deliver this week. It covers all five order flows plus the rollback checks. Let me know if anything is missing.

**Context Porter has:** open card `SR-ACME-CLOUD-0009` — `type: task`, `status: DOING`, "Produce UAT test plan for OrderHub", `acceptance_criteria: ["covers all order flows", "includes rollback checks"]`, deadline this week.

**Porter (outbound pass):**

> **Outcome:** UPDATE `SR-ACME-CLOUD-0009` → propose **DONE** (matched on subject thread + it is the deliverable the card tracked)
> **Confidence:** high — the sent mail delivers the tracked thing and the content meets both acceptance criteria (five order flows + rollback checks named explicitly).
> **Why:** Outbound mail delivering a card's tracked deliverable that meets its acceptance criteria → the task is done. Leaving it open would be the dashboard lying about work the mailbox proves is finished.
> **Gaps / nuance flagged:** delivered ≠ formally accepted. Mark hasn't signed off yet. Porter proposes DONE on **delivery** (the *task* — produce the plan — is complete); if you track Mark's *acceptance* separately, that belongs on a deliverable-card, not this task. Say the word and Porter keeps it `WAIT` for sign-off instead.

Update applied (on confirm):

- `latest_update` → `{ "date": "2026-06-09", "by": "Sam Rivera (sent mail)", "summary": "Final UAT test plan delivered to Mark — all five order flows + rollback checks. Awaiting any feedback." }`
- Status proposed: `DOING` → `DONE`.
- Log line: `{"ts":"2026-06-09T00:00:00Z","who":"porter","action":"status","from":"DOING","to":"DONE","note":"delivered via sent mail to Mark Thompson"}`.

> Note the restraint: Porter does **not** auto-close (`auto_close_from_sent: false`), and it surfaces the deliver-vs-accept distinction rather than silently calling a delivered-but-unaccepted item done. That nuance is the difference between a closure pass you trust and one you have to re-check.

---

## The batch digest

After processing the six inbound emails and one sent email above in one run, Porter closes with a single digest — the thing the person actually reads:

---

**Porter — mailbox run, 2026-06-09 · 6 inbound + 1 sent**

**Needs you (2):**
- 🔴 **SSO is down in BRIO-PORTAL staging** — every user gets a 500, and the appointment-widget demo to Dr. Voss is Thursday. I logged it as `ISS-BRIO-PORTAL-0007` and created the fix card `SR-BRIO-PORTAL-0031`, but **it has no owner** — assign it today. *(This is the one fire in the batch.)*
- ⚠️ **Invoice ACLD-552 from Northwind** — flagged: do invoices get carded or sent to finance? One-line answer and I'll never ask again. Best-guess card attached.

**Captured, please confirm (4 cards):**
| Card | Type | Title | Owner | Due |
|---|---|---|---|---|
| SR-ACME-CLOUD-0012 | task | OrderHub cutover runbook w/ rollback | Sam | 2026-06-20 |
| DEC-ACME-CLOUD-002 | decision | Phased cutover over big-bang | Priya (confirm formal owner) | — |
| SR-ACME-CLOUD-0013 | task | Rework cutover plan to per-region | Sam | (from DEC-002) |
| ISS-BRIO-PORTAL-0007 + SR-BRIO-PORTAL-0031 | issue + task | SSO 500 on staging | **? — assign** | before Thu |

**Handled (1 update):**
- `SR-ACME-CLOUD-0001` landing-zone blocker → **sign-off received, proposed DONE**; first cutover `0002` unblocked, next-step drafted. Reply to Amir drafted.

**Closed / advanced from your sent mail (1):**
- `SR-ACME-CLOUD-0009` UAT test plan → **delivered to Mark, proposed DONE** (acceptance criteria met). Flagged: delivered, not yet formally accepted — say if you'd rather hold it for sign-off.

**Drafted replies (3):** Mark (runbook ack), Amir (sign-off thanks), — *all waiting in drafts, none sent.*

**Filed:** 1 informative · **Noise:** 1 newsletter.

**One thing I didn't card:** nothing dropped silently this run.

---

Three things to notice about this digest: it leads with the two items that need a human and *why*, it never claims to have done anything irreversible (every reply is a draft, every card is "please confirm"), and the one genuine gap — the unassigned SSO fix — is stated as a gap, not buried. That is the difference between an operator you trust to run unattended and a tool you have to double-check.
