# Response templates

Porter drafts replies; it never sends them. These are professional, business-register starting shapes — not scripts. Porter adapts each to the email and rewrites it in the tone set in `config.md` §6 (so a warmer or more clipped house style overrides the neutral default here). Any fact Porter doesn't have becomes a `[TODO: ...]` placeholder, and every placeholder is listed in the decision trace so the person knows what to fill before sending.

The default register below is **professional and concise**: courteous, direct, no filler, no exclamation marks. It reads as correspondence a client or vendor would expect from someone running their project — neither stiff nor chatty.

Rules that apply to every draft:

- **Lead with the substance**, not pleasantries. Open on the matter, not "I hope this email finds you well".
- **Inline-quote the original** beneath the reply when it's a thread reply, so the person can send without rebuilding context.
- **Match the person's voice** (tone block in config). The templates set a neutral-professional floor; the config tone is what's actually applied.
- **Never commit the person** to a date, scope, or cost that isn't already theirs. If the natural reply *would* commit them, draft it *and* raise the card for that commitment (`rules.md` Gate F), and mark the committing sentence so they own it consciously.

---

## Acknowledge + confirm (a request you're accepting)

Use when the person is taking on the work. Confirms the deliverable and the deadline so the sender has it on record.

> Dear [name],
>
> Confirmed — I will deliver [restate the deliverable] by [deadline]. [One line on the key constraint or approach, e.g. "The rollback steps will be set out in full, given the concern raised previously."]
>
> [TODO: any clarifying question, or remove this line.]
>
> Kind regards,
> [sign-off]

Pairs with a `task` action-card for the commitment.

## Status / progress reply (an update was requested)

Use when the sender asks where something stands. States the position plainly, then the next step and date.

> Dear [name],
>
> Current status of [the item]: [one line — on track / delayed / blocked, with the substantive fact]. Next step is [action], expected [date].
>
> [TODO: any dependency on the recipient, or remove this line.]
>
> Kind regards,
> [sign-off]

## Waiting-nudge (chasing a party that owes something)

Use on a `WAIT`/`BLOCKED` card where the external party has gone quiet. Courteous and firm; names the downstream impact so the priority is clear.

> Dear [name],
>
> I am following up on [the item owed]; our last update was [date/status]. We require this by [date], as [the downstream dependency, e.g. "the first cutover cannot be scheduled until the sign-off is in place"].
>
> Please let me know if anything is required from our side to progress this.
>
> Kind regards,
> [sign-off]

## Gracious decline (out of scope / not a fit)

Use for DECLINE. Specific about *why* it is not a fit, and offers a constructive alternative where one genuinely exists. Never curt, never a false maybe.

> Dear [name],
>
> Thank you for the request. [Specific, professional reason it is not a fit — outside the current scope, timing, or area of work.] I would rather be clear on that than take it on without doing it justice.
>
> [Constructive alternative if one genuinely exists: a referral, a more suitable timeframe, a reduced scope that is feasible. Otherwise remove this line — do not manufacture one.]
>
> Kind regards,
> [sign-off]

## Sign-off acknowledgement (an approval came in)

Use when an approval/sign-off arrives that unblocks work (`rules.md` edge-case 3). Confirms receipt and states the next move, so the sender knows the approval was received and is being acted on.

> Dear [name],
>
> Thank you — that is the sign-off required. [The next step it unblocks, e.g. "I will proceed to schedule the first cutover and circulate the per-region plan."]
>
> Kind regards,
> [sign-off]

Pairs with the UPDATE that moves the blocked card forward.

## Meeting-request response (propose, don't open-endedly accept)

Use when someone asks to meet with no agenda. Confirms the purpose and proposes concrete times, rather than an open-ended "when suits?".

> Dear [name],
>
> I would be glad to meet. To prepare properly — is the purpose [best guess at topic]? [TODO: confirm topic.]
>
> I have [TODO: two concrete slots] available. Please let me know which works, or propose an alternative.
>
> Kind regards,
> [sign-off]

Pairs with a `task` card to prepare, if preparation is warranted.

## Holding reply (you've flagged it, but courtesy needs a fast acknowledgement)

Use when Porter has FLAGed an email for the person but the sender expects a prompt response. Acknowledges receipt and sets an honest timeframe without committing.

> Dear [name],
>
> Thank you for your email. I want to review this properly before responding, and will come back to you by [TODO: realistic time].
>
> Kind regards,
> [sign-off]

---

When a situation calls for a register these don't cover, Porter writes the draft from the config tone block and the email's own register. These templates set a consistent professional floor for the common cases; they are not meant to constrain the uncommon ones.
