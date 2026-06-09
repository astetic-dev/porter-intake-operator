# Sample inbox — three emails to test Porter on right now

Paste these three into a Claude project that has this folder loaded, and say *"process these."* Porter should return a decision + artifact for each and a batch digest — without asking you what to do with them. Compare its output to the calls below; this is the "feed it three real examples and trust the output" test.

These use the sample config (`config.md`: user `SR`, projects `ACME-CLOUD` and `BRIO-PORTAL`, working date 2026-06-09). If you've already edited `config.md` to your own projects, expect Porter to FLAG these as unmatched-project work instead — which is itself the correct behaviour.

---

### Email 1

```
From: Dr. Lena Voss <lena.voss@briohealth.org>
To: Sam Rivera
Subject: Thursday demo — and a worry
Date: 2026-06-09

Sam, looking forward to Thursday's appointment-widget demo. One worry: if the
SSO piece isn't rock-solid by then the board will fixate on it and miss the rest.
Not asking you to do anything today — just flagging it's the thing I'm nervous about.
```

### Email 2

```
From: Tomas Reic <tomas.reic@briohealth.org>
To: Sam Rivera; dev-team
Subject: SSO broken in staging
Date: 2026-06-09

Heads up — since this morning the SSO login on the patient portal staging env
throws a 500 for every user. The appointment-widget demo to Dr. Voss is Thursday.
Can someone look at this today?
```

### Email 3

```
From: Atlassian <news@atlassian.com>
To: Sam Rivera
Subject: 5 ways to level up your Jira workflows this quarter
Date: 2026-06-09

Discover the latest in agile reporting... [unsubscribe]
```

---

## What Porter should decide

| Email | Outcome | Why (the rule that fires) |
|---|---|---|
| 1 — Dr. Voss "a worry" | **CARD → risk-card** (`RISK-BRIO-PORTAL-001`) | An uncertain *future* event ("if SSO isn't solid by Thursday") threatening the demo objective — a risk, not an issue (nothing is broken in *this* email). Gate D scores it trackable on the "+2 something at risk" signal even though she disclaims any task ("not asking you to do anything"). Primary call is the risk-card because she names a specific threat to a gating demo; the lighter alternative — FILE-with-summary under the sponsor rule — is defensible only if you don't capture risks from FYIs. Sponsor sender → surfaced in the digest regardless. |
| 2 — Tomas "SSO broken" | **CARD → issue-card + fix action-card** | Present-tense failure (500 for every user) = issue, not risk. Near gate (Thursday). Fix owner unknown → card written with `assignee.person: null` and the gap flagged. Leads the "needs you" section. |
| 3 — Atlassian newsletter | **NOISE**, auto-filed | `news@` marketing address, unsubscribe link, no project key → noise score −5. Counted, not summarised. |

The interesting pair is 1 and 2: **the same subject (SSO + Thursday) produces two different card types**, because one describes an uncertain future and the other a present failure. And note the loop they close — if Porter carded email 1 as `RISK-BRIO-PORTAL-001` and then processes email 2, the right move is to mark that risk `realized` and link it to the new issue (`realized_as_issue`), because the thing Dr. Voss feared just happened. An operator that gets *that* right is one worth trusting.

A correct digest leads with email 2 (the live fire, with the owner gap), surfaces email 1 as the sponsor's stated worry now partly realised, and tallies email 3 as one filtered newsletter — leaving Sam with exactly one real decision: who fixes the SSO 500 before Thursday.
