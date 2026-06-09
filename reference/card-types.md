# Card types — what Porter routes work into

Porter writes into the Astrid card model. This file is the working reference for **which type a given email becomes** and the **minimum fields** each needs. You do not need Astrid installed to use these — they are plain JSON files, and the full JSON Schemas are **bundled in `reference/schemas/`** so Porter's cards are valid and self-contained on their own. If you also run Astrid, these are exactly the cards its dashboard reads; if you don't, the schemas here are the whole contract.

> **The schemas are authoritative.** This file is the human-readable summary; `reference/schemas/*.schema.json` are the precise definitions Porter validates against (`action-card-v2`, `decision-card-v1`, `risk-card-v1`, `issue-card-v1`, `milestone-card-v1`, `deliverable-card-v1`, `meeting-card-v1`, `project-card-v1`, `contact-card-v1`). When the prose here and a schema ever disagree, the schema wins.

The hardest part of intake is not *whether* to capture — it's *what kind* of card. Get the type wrong and the work lands in the wrong place: a decision filed as a task never gets recorded as a decision; a present failure filed as a risk sits in the register while the demo breaks. The disambiguation table below is the core of Porter's job.

---

## The disambiguation table

Ask these in order. The first "yes" wins.

| # | Ask | Yes → | Key tell |
|---|---|---|---|
| 1 | Is it a record that a **meeting happened** — attendees, agenda/minutes, *several* outcomes? | **meeting-card** (+ action-cards for what it produced) | minutes or notes, an attendee list, multiple decisions/actions from one session |
| 2 | Is a choice **already made and settled**? | **decision-card** | past tense, "we're going with", "calling it settled", an option ruled out |
| 3 | Is something **broken / failing / unclear right now**? | **issue-card** (+ a fix action-card) | present-tense failure, "throws an error", "doesn't work", "which is correct?" |
| 4 | Is it an **uncertain future event** that could hurt an objective? | **risk-card** | "might", "could slip", "if X doesn't land", a concern not yet realised |
| 5 | Is it a **dated gate** the plan hinges on? | **milestone-card** | "go-live", "the 20th is the hard date", a moment that's binary and gating |
| 6 | Is it a **thing to produce** with acceptance + sign-off? | **deliverable-card** | "the design doc", "the report they must approve", named artifact with a recipient |
| 7 | Is it **holding other work up**? | action-card `type: blocker` | "we can't proceed until", a dependency that's stuck |
| 8 | Is it a **choice that still must be made** (pending)? | action-card `type: decision` | "we need to decide between A and B by Friday", owner + deadline, no answer yet |
| 9 | Is it something to **keep watching**, no single done-moment? | action-card `type: monitoring` | "keep an eye on", a slow-burn risk being watched, an ongoing condition |
| 10 | Otherwise: is it a **thing to do**? | action-card `type: task` | a commitment, a deliverable-to-make, a request directed at someone |

### The two traps these encode

- **decision-card (row 2) vs action-card `type: decision` (row 8).** A *made* decision is the record (decision-card). A *pending* decision is work to drive (action-card). Test: **a thing done, or a choice still open?** When a pending decision is finally made, you create the decision-card and close the action-card via the decision-card's `resolves_action_card`.
- **risk-card (row 4) vs issue-card (row 3).** A risk is an *uncertain future*. The moment it happens it is a *present issue*. "The vendor might slip" is a risk; "the vendor slipped" is an issue (and if a risk-card existed, mark it `realized` and link `realized_as_issue`).
- **meeting-card (row 1) vs decision-card (row 2).** A call mentioned only as the *source* of a single settled decision ("following our call, we're going with X") is a **decision-card**, not a meeting-card — there is no meeting record worth keeping, just the decision it produced. Reach for a meeting-card only when the email is genuinely a record of the session itself (attendees, several decisions/actions). This is why row 1's tell requires *multiple* outcomes, not just the phrase "following our call".

---

## How the cards connect

Work always flows **down into action-cards**. The register cards (issue/risk/decision/milestone/deliverable) describe *what* and point at the action-cards that *do the work*:

- **issue** → `action_cards[]` (the fix) · **risk** → `mitigation_action_cards[]` (the response)
- **decision** → `action_cards[]` (work it sets in motion) · `resolves_action_card` (the pending decision it closes)
- **milestone** → `action_cards[]` + `deliverables[]` + `issues[]` · **deliverable** → `action_cards[]` + `milestone_id`
- **meeting** → `action_cards_created[]` (everything it spun out)

When Porter logs a register card, it also proposes the action-card(s) that carry out the work, and links them — so nothing is recorded without a path to getting done.

---

## Minimum fields per type (what Porter must fill)

Porter fills the **required** fields and any optional field the email gives it for free. It never invents an owner, a date, or context to fill a field — an honest gap is flagged.

### action-card (`{user}-{customer}-{project}-NNNN.json` + `.md` + `.log.jsonl`)
Required: `schema_version:2`, `id`, `title` (the person's words, an outcome), `status` (`TODO`/`DOING`/`WAIT`/`PLAN`/`BLOCKED`/`DONE`/`CANCELLED`), `type` (`task`/`decision`/`monitoring`/`blocker`), `priority` (`high`/`medium`/`low`/`none`), `project{user_code,customer_code,project_code,full_name}`, `assignee{party,person?}`, `reporter{party,person?}`, `deadline{text, date?}`, `created`, `updated`.
Porter also fills when known: `sources[]` (the email), `acceptance_criteria[]`, `tags[]`, `blocks`/`depends_on`. Never sets `late`/`urgent` (auto). Body `.md`: `## Context / ## Next step` at minimum. First `.log.jsonl` line: `{"ts","who":"porter","action":"created","note"}`.

### decision-card (`DEC-{customer}-{project}-NNN.json`)
Required: `schema_version:1`, `id`, `project_id`, `title` (noun phrase naming the decision), `status` (`proposed` if not yet agreed — Porter uses this for "the person's call" decisions; `accepted` only when the email shows it's settled), `date`, `context`, `decision` ("We will ..."), `consequences`, `decision_makers[]` (≥1; flag if not truly named). Fill `options_considered[]` (mark exactly one `chosen:true` on an accepted card) and `decision_drivers[]` when the email gives them.

### risk-card (`RISK-{customer}-{project}-NNN.json`)
Required: `schema_version:1`, `id`, `project_id`, `title` (cause→effect: "Vendor sign-off slips, delaying cutover"), `description`, `probability` + `impact` (`very-low`..`very-high`), `response` (`avoid`/`mitigate`/`transfer`/`accept`/`escalate`), `status` (`open`/`mitigating`/`accepted`/`realized`/`closed`), `owner{party,person?}`, `raised`. Porter leaves `score` to tooling. Propose `mitigation_action_cards[]` for the response.

### issue-card (`ISS-{customer}-{project}-NNNN.json`)
Logs what's broken/unclear/asked. Carries severity (technical impact) separate from priority (business urgency), `status` (`open`/.../`resolved`/`closed`; `resolved` ≠ terminal), `project_id`, and `action_cards[]` for the fix. Always pair a fresh issue with at least one fix action-card unless it's purely a question awaiting an answer.

### milestone-card (`MS-{customer}-{project}-NNN.json`)
A moment, binary and gating, against a baseline date. Links `action_cards[]` / `deliverables[]` / `issues[]` that must land for it to be met. Terminal: `met`/`missed`/`cancelled`.

### deliverable-card (`DLV-{customer}-{project}-NNN.json`)
A thing to produce, with `acceptance_criteria` and a sign-off owner. Links `action_cards[]` (what produces it), `issues[]`, `milestone_id`. Terminal: `accepted`/`rejected`. A "please approve X" email updates this card's acceptance state.

### meeting-card (`MTG-{customer}-{project}-{YYYY-MM-DD}-NN.json`)
The factual record: `project_id`, type, purpose, `attendees[]` (link `contact_id` where known), `decisions[]`, `notes`, and `action_cards_created[]`. Porter fills the factual layer only — the reflection fields (`user_intent`, `analysis`) belong to Miles, the meeting coach.

### contact-card (`CONTACT-{ORG}-{name-slug}.json`, centralised in `_contacts/`)
Identity-only is fine: `name`, `organization`, `role`, `active`. Porter creates one for a new recurring person and references it by id from the cards (`assignee.contact_id`, `attendees[].contact_id`) so a person's details — or departure — change in one place.

---

## Id conventions (so Porter's ids validate)

| Card | Format | Example |
|---|---|---|
| action | `{user}-{customer}-{project}-NNNN[suffix]` | `SR-ACME-CLOUD-0012` |
| decision | `DEC-{customer}-{project}-NNN` | `DEC-ACME-CLOUD-002` |
| risk | `RISK-{customer}-{project}-NNN` | `RISK-ACME-CLOUD-001` |
| issue | `ISS-{customer}-{project}-NNNN` | `ISS-BRIO-PORTAL-0007` |
| milestone | `MS-{customer}-{project}-NNN` | `MS-ACME-CLOUD-001` |
| deliverable | `DLV-{customer}-{project}-NNN` | `DLV-ACME-CLOUD-001` |
| meeting | `MTG-{customer}-{project}-{YYYY-MM-DD}-NN` | `MTG-ACME-CLOUD-2026-06-09-01` |
| contact | `CONTACT-{ORG}-{name-slug}` | `CONTACT-ACME-mark-thompson` |

High-volume cards (action, issue) use **4 digits**; register cards (risk, decision, milestone, deliverable) use **3**. The `{customer}-{project}` substring is the join key to the project. To pick the next number, scan existing card ids for that project and increment; if Porter can't see existing cards, it proposes `NNNN`/`NNN` as a placeholder and notes it for the person to fix on save.
