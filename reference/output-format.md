# Output format

Two outputs, every run: a **per-email decision** for each message, and one **batch digest** at the end. The formats below are what makes the output trustworthy enough to act on without re-reading the source — the person sees the call, the reason, the doubt, and the artifact in one place.

---

## Per-email decision

For each email, Porter emits this block, in this order. The first four lines are the **trust trace** and are non-negotiable.

```
Outcome:    <CARD | UPDATE | REPLY | FILE | DECLINE | NOISE | FLAG>  [→ card type if CARD/UPDATE]
Confidence: <high | medium | low> — <the gate or rule that fired, with the score where relevant>
Why:        <one or two lines: the substance of the call>
Gaps:       <what Porter refused to guess: owner? date? project? ambiguous match? — or "none">
---
Artifact:   <the proposed card JSON (+ .md body + first log line), and/or the reply draft>
Routing:    <which project, and where the card lands>
```

Notes:

- **NOISE** collapses to a single line (no artifact): `Outcome: NOISE — <sender/type>; filed.`
- **FILE** carries a one-line summary instead of a card: `Why:` is the summary the person will see in the digest.
- **FLAG** still carries an artifact — the best-guess card and/or draft — plus the explicit question the person needs to answer. A flag is "confirm this", never "you deal with it".
- **Cards are proposed, not saved** (unless `config.md` auto-save is on, which is off by default). Show the JSON; save on confirm.
- For a register card that spawns work, show the register card **and** the linked action-card(s) together, so the work-path is visible.

## The batch digest

After the batch, Porter writes one digest. This is the artifact the person actually reads — order it by what needs them, not by the order mail arrived.

```
Porter — inbox run, <date> · <N> emails

Needs you (<n>):
  - <each FLAG and each genuine gap (e.g. an unassigned high-priority fix), with WHY and what's attached>
  - <lead with anything incident-shaped — see rules.md edge-case 9>

Captured, please confirm (<n> cards):
  <table: card id | type | title | owner | due — owner-gaps shown as "? — assign">

Handled (<n> updates):
  - <each UPDATE: card id → what changed, status proposed, downstream effects>

Closed / advanced from your sent mail (<n>):
  - <each card the outbound pass moved: card id → DONE proposed (delivered via sent mail), or advanced/logged>

Drafted replies (<n>):
  - <recipient + one-line purpose> — all in drafts, none sent.

Filed: <n> informative · Noise: <n>

One thing I didn't card: <anything that looked like a commitment but Porter chose not to track, with why — or "nothing dropped silently this run">
```

### The rules the digest obeys

1. **Needs-you first.** The two or three things requiring a human go at the top, each with the reason and what Porter already prepared. Everything Porter handled goes below.
2. **Never claim an irreversible action.** Replies are "drafted, none sent". Cards are "please confirm". The digest never implies Porter sent mail or committed the person.
3. **Gaps are stated, not buried.** An unassigned owner, an ambiguous match, a guessed placeholder id — these appear as gaps, in plain sight. A digest that hides a gap is worse than one that admits it.
4. **Nothing dropped silently.** If Porter decided not to card something that looked like a commitment, the last line says so. Silent non-capture is the exact failure the system exists to prevent.
5. **Counts, not walls.** Noise and routine FILEs are tallied, not enumerated. The person can audit the noise bucket if they want; the digest doesn't make them.

A good digest can be read in fifteen seconds and leaves the person with a short, honest list of decisions only they can make — having found everything else already done and waiting for a confirm.

## Persisted outputs (not just chat)

The chat digest is the *summary*; it is not the *record*. Every run also writes to disk, so Porter is genuinely standalone and the person comes back to files, not a scrollback (full spec: `reference/outputs.md`):

- **`mail-log.jsonl`** — one appended line per email (date, sender, subject, outcome, confidence, `read_worthy`, summary, card link). The durable, queryable history of every decision.
- **`runs/<YYYY-MM-DD>-NN.md`** — the batch digest above, written verbatim to a file (plus `runs/latest.md`).
- **`dashboard.html`** — regenerated: **Tab 1** every open action-card (urgent/late first, by project); **Tab 2** the to-read (FILE) mail grouped by day, with a per-day noise count.

So the per-email blocks and the digest you show in chat are the *live view*; the three files are the *standing record*. A run that prints a digest but writes nothing is not finished.
