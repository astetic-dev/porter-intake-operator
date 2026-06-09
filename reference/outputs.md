# Outputs & persistence — how Porter runs standalone

A run is not finished when the chat scrolls away. It is finished when the record is on disk. This is what lets Porter run unattended and lets the person come back to a **dashboard and a written log**, not a conversation they have to scroll. The cards are the source of truth; everything here is derived from them and from the mail log, and can be rebuilt at any time.

At the end of every batch (after the inbound and the outbound passes), Porter writes three things.

---

## 1. `mail-log.jsonl` — the durable record (append-only)

One JSON object per line, one line per email Porter has ever processed. This is the re-readable, queryable history that replaces the ephemeral chat digest: every decision Porter made, with its reason, kept permanently. **Append only — never rewrite it.** It is the audit trail.

```json
{"ts":"2026-06-09T09:12:00Z","date":"2026-06-09","run":"2026-06-09-01","direction":"in","from_name":"Mark Thompson","from_addr":"mark.thompson@acmelogistics.com","subject":"OrderHub runbook","outcome":"CARD","card_type":"task","card_id":"SR-ACME-CLOUD-0012","project":"ACME-CLOUD","confidence":"high","read_worthy":false,"private":false,"summary":"Requested the OrderHub runbook before the 20th go-live review; carded as a task."}
```

Field notes:
- `outcome` — one of CARD / UPDATE / REPLY / FILE / DECLINE / NOISE / FLAG (the outbound pass uses UPDATE for a close, with `card_type:"close"`).
- `read_worthy` — `true` for `FILE` (informative mail the person may still want to read); `false` for everything else. Drives **Tab 2** of the dashboard.
- `private` — `true` for Gate-B private mail: logged minimally (no `summary`), excluded from the dashboard and never surfaced. Privacy stays private even in the log.
- `card_id` — set when the email produced or advanced a card, so the log links to the work.
- `summary` — the one-line the person reads. Omitted for `private` and usually for `NOISE`.

## 2. `runs/<YYYY-MM-DD>-NN.md` — the run digest as a file

The exact batch digest shown in chat (`reference/output-format.md`), written to disk so "what did Porter do this morning" is a file, not a memory. `NN` is the run number that day (`01`, `02`, …). Porter also overwrites `runs/latest.md` with the most recent one for a stable path.

## 3. `dashboard.html` — the two-tab view, regenerated each run

A single self-contained HTML file (no server, no external assets) the person opens in a browser. Two tabs:

### Tab 1 — Open actions
Every **open action-card** (status in `TODO / DOING / WAIT / PLAN / BLOCKED` — i.e. not `DONE`/`CANCELLED`), across all projects. Sorted **urgent and late first**, then by due date, grouped by project. Each row shows: title, project, type, status, owner (a missing owner is shown as **? — assign**, never hidden), due (date or the deadline text), the `latest_update` one-liner, and `late`/`urgent`/`stale` badges. This is the "what needs doing" view — the standing answer to "where are we."

### Tab 2 — To read, per day
The `FILE` (informative) messages Porter triaged, **grouped by the day they arrived**, newest day first. Each entry: sender, subject, the one-line summary, and the project tag. This is the person's catch-up reading list — the mail that wasn't noise and wasn't action, so they can stay informed without reopening the inbox. Each day also shows a muted footer count of what was filtered as noise that day (`+12 filtered as noise`), so nothing is hidden, only collapsed.

`FLAG` items (the things needing the person) live in the run digest's "Needs you" section, not in Tab 2 — Tab 2 is for reading, not deciding.

---

## How the dashboard gets built

Two mechanisms; the cards stay the source of truth either way.

- **Scripted (recommended, robust):** if PowerShell 7+ is available and `config.md` `build_dashboard: auto`, Porter runs the bundled generator:
  ```
  pwsh -File tools/build-dashboard.ps1 -Root <workspace_root> -MailLog <mail_log> -Out <dashboard> -Accent <dashboard_accent>
  ```
  It scans the workspace for action-cards (Tab 1) and reads `mail-log.jsonl` (Tab 2), and writes a self-contained `dashboard.html`. It computes `late`/`urgent` itself, so the dashboard is correct even if a card's stored flags are stale.
- **No-script fallback (fully portable):** if there's no PowerShell (e.g. a judge on another OS, or a pure paste-mode session), Porter writes `dashboard.html` **directly** from the same card data and mail log, in the same two-tab layout. The operator is an LLM — rendering the view from the data is within its job. Nothing about the dashboard depends on a runtime being installed.

If you already run **Astrid**, you can instead point `workspace_root` at your Astrid workspace and use Astrid's own `generate-dashboard.ps1` for the portfolio view — Porter's cards are the same format, so they show up there too. Porter's two-tab dashboard is the *standalone* option for when you don't run Astrid.

---

## Where things live (standalone layout)

```
<workspace_root>/
├── projects/<CUSTOMER>/<project>/
│   ├── project.json
│   └── cards/                 ← action-cards Porter creates ({id}.json + .md + .log.jsonl)
│   └── risks/ decisions/ issues/ milestones/ deliverables/ meetings/   ← register cards (when used)
├── _contacts/                 ← contact-cards
├── mail-log.jsonl             ← the durable record (append-only)
├── runs/                      ← per-run digests + latest.md
└── dashboard.html             ← regenerated each run (Tab 1 open actions · Tab 2 to-read per day)
```

This is the Astrid workspace layout, so a Porter workspace *is* an Astrid workspace — add Astrid later and your cards are already where it expects them. Set `workspace_root` in `config.md`; it defaults to `./workspace` for a fresh standalone setup.

> **Worked example:** `sample-workspace/` (at the operator root) is a populated workspace — six action-cards across two projects, a thirteen-line `mail-log.jsonl`, a written digest in `runs/`, and the generated `sample-workspace/dashboard.html`. Open the dashboard to see exactly what a run leaves behind, or re-run `tools/build-dashboard.ps1 -Root sample-workspace` to regenerate it.

## The discipline

- **Cards are truth; the dashboard and log are derived.** You can delete `dashboard.html` and rebuild it from the cards + mail log. Nothing of value lives only in the dashboard.
- **Append the mail log, never rewrite it.** It is the audit trail of every decision; rewriting it would let the record drift from what actually happened.
- **Persist before you report "done".** A run that touched the inbox but left no file behind hasn't finished — the whole point is that the person finds the work recorded, not narrated.
