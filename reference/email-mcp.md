# Connecting your email (optional)

Porter works fully **without any setup**: paste one or more emails into the chat and Porter triages them. That is the default (`config.md` → `mode: paste`) and it is all you need to use this folder, test it, or submit it.

This file is for when you want Porter to read the mailbox itself — so you can say *"process my inbox"* instead of pasting. That requires an **email MCP server**: a small connector that lets the assistant read your mail and create drafts. It is the email→card bridge the Astrid system calls out as the highest-leverage thing you can add.

---

## The one rule: read + draft, never send

Porter is built to **never send mail** — it drafts and you send (`config.md` §5, `auto_send_replies` is locked off). So the only capabilities it ever needs from an email MCP are:

- **read** the inbox and the sent folder, and
- **create drafts**.

It never needs *send* permission. If your MCP exposes a send tool, Porter still won't call it — but scope the credential/token to read + draft only where you can. That way the "operator runs unattended" promise is enforced by the connection, not just by Porter's own discipline.

---

## Setup, in three steps

1. **Pick an MCP for your mailbox.** Use whichever connector matches where your mail lives. Common patterns:
   - **Outlook (desktop/work):** a local connector that drives Outlook directly, or a Microsoft Graph–based MCP for Microsoft 365. Reads folders and writes drafts to your Drafts folder.
   - **Gmail / Google Workspace:** a Gmail-API MCP. Grant the read + compose (draft) scopes; do **not** grant send.
   - **Generic IMAP:** an IMAP MCP for any other provider (reads folders). Pair it with a drafts-capable connector, or have Porter return reply drafts as text you paste in.

   (This folder doesn't ship an MCP — connectors are chosen and installed at the Claude-project / client level, not inside the operator folder. Any server that exposes read + draft tools works.)

2. **Point Porter at it in `config.md` §3:**
   - set `mode: mcp`
   - set `process_folders` to the exact inbox and sent folder names/paths your MCP uses (e.g. `Inbox, Sent Items` for Outlook; `INBOX, [Gmail]/Sent Mail` for Gmail).

3. **Tell Porter once, at the start of a run,** which mailbox/account to read if your MCP exposes more than one. Then say *"process my inbox"* (and Porter runs the inbound pass) or *"process inbox and sent"* (inbound + the outbound closure pass, `rules.md` §7).

---

## What Porter does and doesn't touch

- It reads **only the folders you name** in `process_folders`. It does not crawl your whole mailbox.
- Private mail (Gate B) is filed and **not summarised** in the digest, MCP-connected or not.
- It **moves/files** mail only if your MCP supports it *and* you've asked for it; otherwise "FILE/NOISE" is a routing decision Porter records in the digest, and you file by hand or with a rule in your client. Porter's value is the *decision*, not the folder-move.
- It writes reply drafts to your **Drafts** folder (or returns them as text if the MCP can't draft). Nothing is ever sent.

If you'd rather not connect anything: stay on `mode: paste`. Everything in `rules.md`, the card output, and the digest works identically on pasted email — the MCP only changes how the mail *arrives*, never how Porter *decides*.
