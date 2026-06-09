# Config

Porter reads this file before classifying anything. It is how you turn a generic operator into *your* operator. Everything here is plain text — edit it whenever your work changes. The values below are a worked example (for a fictional consultant, "Sam Rivera", running two projects); replace them with your own.

This file replaces an onboarding interview. Porter does **not** interview you — an operator decides, it doesn't quiz. You fill this in once; Porter acts on it.

---

## 1. You

- **user_code:** `SR` (your initials or handle, 2–4 uppercase letters — becomes the `{user}` prefix on action-card ids)
- **display_name:** Sam Rivera
- **role:** Independent project lead / consultant

## 2. Active projects

One block per project. The `customer_code` + `project_code` form the card-id prefix and the join key to the project. `match` is how Porter routes an email to this project: sender domains, names, ticket-key prefixes, and keywords. Be generous with keywords — a missed match becomes a FLAG, not a wrong card, so over-listing is safe.

```yaml
projects:
  - customer_code: ACME
    project_code: CLOUD
    full_name: "Acme Logistics — Cloud platform migration"
    match:
      domains: ["acmelogistics.com", "northwind-cloud.com"]
      people: ["Mark Thompson", "Amir Haddad", "Priya Nair"]
      ticket_prefixes: ["ACLD-"]
      keywords: ["cutover", "landing zone", "migration", "OrderHub", "go-live"]

  - customer_code: BRIO
    project_code: PORTAL
    full_name: "Brio Health — Patient portal rebuild"
    match:
      domains: ["briohealth.org"]
      people: ["Dr. Lena Voss", "Tomas Reic"]
      ticket_prefixes: ["BPP-"]
      keywords: ["portal", "SSO", "FHIR", "appointment widget"]
```

If an email matches **no** project and clearly concerns project work, Porter routes it to the project named in `default_project` below and flags it for confirmation. If `default_project` is empty, Porter FLAGs unmatched project work.

- **default_project:** *(empty — flag unmatched project work for me)*

## 3. Email source

How email reaches Porter. This does **not** change the decision logic — only how mail arrives.

- **mode:** `paste`  *(options: `paste` = I paste emails into the chat; `mcp` = an email MCP server is connected and Porter may read the mailbox)*
- **process_folders:** `Inbox, Sent`  — Porter runs an **inbound pass** over the Inbox (mail that opens/advances work) and an **outbound pass** over Sent (mail that closes/advances work — see `rules.md` §7). Set to `Inbox` only if you don't want the closure pass.
- **mcp_notes:** Connecting a mailbox is **optional** — `paste` needs no setup and the decision logic is identical either way. If you want Porter to read the mailbox itself, see **`reference/email-mcp.md`** for the (short) setup: pick an Outlook/Gmail/IMAP MCP, set `mode: mcp`, and name your inbox + sent folders below. Porter only ever needs **read + draft** access — never *send* (it cannot send by design). An email→card bridge is exactly the integration the Astrid system calls for; Porter is that bridge.

## 4. Thresholds

The two numbers that tune how Porter behaves. Defaults are sensible; change them only if Porter is over- or under-flagging for you.

- **action_gate:** `2`  — minimum score on the action-vs-FYI gate for an email to become trackable work (CARD/UPDATE) rather than FILE. Lower = capture more aggressively. See `reference/scoring-rubric.md`.
- **confidence_floor:** `medium`  — the minimum confidence at which Porter acts on its own call. Below it, Porter FLAGs the email (with its best-guess proposal attached) instead of producing a final card. Raise to `high` if you want to review more; this never makes Porter *send* anything — it only governs card/reply confidence.
- **stale_days:** `14` — Porter notes in the digest when an email reopens or relates to a card that has been idle longer than this.

## 5. Auto-act vs propose

By default Porter **proposes** cards and replies (show-then-save) and saves only what you confirm. You can let it auto-handle the low-stakes, high-confidence categories so they never reach you:

- **auto_file_noise:** `true`  — NOISE (newsletters, vendor blasts, auto-notifications) is filed and counted without asking.
- **auto_file_fyi:** `false` — FILE (informative, no action) is proposed, not auto-filed. Set `true` once you trust the FILE calls.
- **auto_save_cards:** `false` — CARD/UPDATE artifacts are always proposed for confirmation. (Recommended off; the cards are your operational memory and a wrong one is costly.)
- **auto_close_from_sent:** `false` — when the outbound pass (`rules.md` §7) finds a sent email that delivers a card's tracked work, the DONE transition is **proposed**, not executed. Set `true` only once you trust the closure calls; even then, Porter only auto-closes when the card's `acceptance_criteria` are met, never on a bare "sent something" match.
- **auto_send_replies:** `false` — **locked off by design.** Porter drafts; you send. There is no setting that lets Porter send mail.

## 6. Reply tone

How drafted replies and declines should sound. A few lines is enough; Porter matches it.

> Professional and concise. Lead with the matter, not pleasantries; no filler openers ("I hope this email finds you well"). Full sentences, courteous business register, no exclamation marks. Standard salutation and sign-off ("Dear [name]" / "Kind regards, Sam Rivera"). For declines: courteous and specific about *why* it is not a fit, with a constructive alternative where one genuinely exists.

## 7. Outputs & persistence

Where Porter writes its record and dashboard at the end of each run (full spec in `reference/outputs.md`). Defaults work for a fresh standalone setup.

- **workspace_root:** `./workspace`  — where the card files live (Astrid layout: `projects/<CUSTOMER>/<project>/cards/`). If you run Astrid, point this at your Astrid workspace and Porter's cards land where Astrid already reads them.
- **mail_log:** `./workspace/mail-log.jsonl`  — append-only record of every email processed (the re-readable audit trail).
- **runs_dir:** `./workspace/runs`  — per-run digests are written here, plus `latest.md`.
- **dashboard:** `./workspace/dashboard.html`  — regenerated each run (Tab 1 open actions · Tab 2 to-read per day).
- **build_dashboard:** `auto`  — `auto` = run `tools/build-dashboard.ps1` if PowerShell 7+ is present; `off` = skip; `manual` = I'll run it myself. With no PowerShell, Porter writes the dashboard HTML directly instead.
- **dashboard_accent:** `#2f6f9f`  — single accent colour for the dashboard header/badges. Neutral professional by default; set it to a brand colour if you like.

## 8. Anything else Porter should know

Free text. Recurring senders that are always noise, a VIP whose mail always gets flagged to you regardless of content, a phrase your clients use that means "this is urgent", etc.

> - Mail from `billing@` or `no-reply@` is NOISE unless it names a project ticket key.
> - Mail from Dr. Lena Voss (Brio sponsor) is never auto-filed — always at least FILE with a one-line summary, even when it carries no action.
> - When a client requests a conversation with no agenda, treat it as a meeting request: draft a reply proposing two concrete slots and create a `task` card to prepare.
