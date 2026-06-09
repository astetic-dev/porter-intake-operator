<#
  build-dashboard.ps1 - Porter standalone dashboard generator

  Reads a Porter/Astrid workspace and emits a single self-contained dashboard.html
  with two tabs:
    Tab 1  Open actions     - every open action-card, urgent/late first, by project
    Tab 2  To read, per day  - the FILE (informative) mail from mail-log.jsonl, by day

  The cards (JSON) are the source of truth; this file is derived and disposable.

  Target runtime: PowerShell 7+ on the local workstation. ASCII-only, no 5.1-breaking
  syntax (no ternary / ?? / ?.), so it parses everywhere.

  Usage:
    pwsh -File tools/build-dashboard.ps1 -Root <workspace_root> [-MailLog <path>] [-Out <path>] [-Accent "#2f6f9f"]
#>
[CmdletBinding()]
param(
  [string]$Root = ".",
  [string]$MailLog = "",
  [string]$Out = "",
  [string]$Accent = "#2f6f9f"
)

$ErrorActionPreference = "Stop"

$Root = (Resolve-Path $Root).Path
if (-not $MailLog) { $MailLog = Join-Path $Root "mail-log.jsonl" }
if (-not $Out)     { $Out     = Join-Path $Root "dashboard.html" }
$today = (Get-Date).ToString("yyyy-MM-dd")
$builtAt = (Get-Date).ToString("yyyy-MM-dd HH:mm")

function Enc {
  param([object]$s)
  if ($null -eq $s) { return "" }
  $t = [string]$s
  $t = $t -replace '&', '&amp;'
  $t = $t -replace '<', '&lt;'
  $t = $t -replace '>', '&gt;'
  $t = $t -replace '"', '&quot;'
  return $t
}

# ------------------------------------------------------------------ Tab 1: cards
$openStatuses = @("TODO", "DOING", "WAIT", "PLAN", "BLOCKED")
$actionTypes  = @("task", "decision", "monitoring", "blocker")
$priOrder     = @{ "high" = 0; "medium" = 1; "low" = 2; "none" = 3 }

$cards = New-Object System.Collections.Generic.List[object]

$jsonFiles = Get-ChildItem -Path $Root -Recurse -Filter *.json -File -ErrorAction SilentlyContinue |
  Where-Object { $_.FullName -notmatch '[\\/](node_modules|schemas|_index)[\\/]' }

foreach ($f in $jsonFiles) {
  try { $j = Get-Content -LiteralPath $f.FullName -Raw | ConvertFrom-Json } catch { continue }
  if ($null -eq $j) { continue }
  if (-not ($j.PSObject.Properties.Name -contains "status")) { continue }
  if (-not ($j.PSObject.Properties.Name -contains "type"))   { continue }
  if ($actionTypes -notcontains [string]$j.type)   { continue }
  if ($openStatuses -notcontains [string]$j.status) { continue }

  $proj = ""
  if ($j.project) { $proj = "$($j.project.customer_code)-$($j.project.project_code)" }

  $owner = $null
  if ($j.assignee) { $owner = $j.assignee.person }

  $dueDate = $null
  $dueText = ""
  if ($j.deadline) {
    if ($j.deadline.date) { $dueDate = [string]$j.deadline.date }
    if ($j.deadline.text) { $dueText = [string]$j.deadline.text }
  }

  $late = $false
  if ($dueDate -and ($dueDate -lt $today)) { $late = $true }

  $urgent = $false
  if ([string]$j.priority -eq "high") { $urgent = $true }
  if ($late -and ([string]$j.priority -eq "medium")) { $urgent = $true }

  $latest = ""
  if ($j.latest_update -and $j.latest_update.summary) { $latest = [string]$j.latest_update.summary }

  $sortPri = 9
  if ($priOrder.ContainsKey([string]$j.priority)) { $sortPri = $priOrder[[string]$j.priority] }
  $sortDue = "9999-99-99"
  if ($dueDate) { $sortDue = $dueDate }

  $cards.Add([pscustomobject]@{
    id      = [string]$j.id
    title   = [string]$j.title
    type    = [string]$j.type
    status  = [string]$j.status
    project = $proj
    owner   = $owner
    dueDate = $dueDate
    dueText = $dueText
    latest  = $latest
    late    = $late
    urgent  = $urgent
    sortUrg = $(if ($urgent) { 0 } else { 1 })
    sortLate= $(if ($late) { 0 } else { 1 })
    sortPri = $sortPri
    sortDue = $sortDue
  })
}

$sorted = $cards | Sort-Object sortUrg, sortLate, sortPri, sortDue, project, id
$openCount   = $sorted.Count
$urgentCount = ($sorted | Where-Object { $_.urgent }).Count
$lateCount   = ($sorted | Where-Object { $_.late }).Count

# group cards by project
$cardRows = ""
if ($openCount -eq 0) {
  $cardRows = '<p class="empty">No open actions. Inbox is under control.</p>'
} else {
  $byProject = $sorted | Group-Object project | Sort-Object Name
  foreach ($grp in $byProject) {
    $projName = $grp.Name
    if (-not $projName) { $projName = "(no project)" }
    $cardRows += "<h3 class=""proj"">$(Enc $projName)</h3>`n"
    $cardRows += "<table><thead><tr><th></th><th>Title</th><th>Type</th><th>Status</th><th>Owner</th><th>Due</th><th>Last update</th></tr></thead><tbody>`n"
    foreach ($c in $grp.Group) {
      $badges = ""
      if ($c.urgent) { $badges += '<span class="badge urgent">urgent</span>' }
      if ($c.late)   { $badges += '<span class="badge late">late</span>' }

      $ownerCell = Enc $c.owner
      if (-not $c.owner) { $ownerCell = '<span class="gap">? - assign</span>' }

      $dueCell = ""
      if ($c.dueDate) { $dueCell = Enc $c.dueDate } elseif ($c.dueText) { $dueCell = Enc $c.dueText }

      $rowCls = ""
      if ($c.urgent) { $rowCls = ' class="row-urgent"' }

      $cardRows += "<tr$rowCls><td class=""bd"">$badges</td><td><span class=""cid"">$(Enc $c.id)</span><br>$(Enc $c.title)</td><td>$(Enc $c.type)</td><td>$(Enc $c.status)</td><td>$ownerCell</td><td>$dueCell</td><td class=""upd"">$(Enc $c.latest)</td></tr>`n"
    }
    $cardRows += "</tbody></table>`n"
  }
}

# ------------------------------------------------------------- Tab 2: to-read feed
$feed = New-Object System.Collections.Generic.List[object]
if (Test-Path -LiteralPath $MailLog) {
  foreach ($line in (Get-Content -LiteralPath $MailLog)) {
    $t = $line.Trim()
    if (-not $t) { continue }
    try { $e = $t | ConvertFrom-Json } catch { continue }
    $feed.Add($e)
  }
}

$toRead = $feed | Where-Object { ([string]$_.outcome -eq "FILE") -and (-not $_.private) }
$noise  = $feed | Where-Object { [string]$_.outcome -eq "NOISE" }
$toReadCount = ($toRead | Measure-Object).Count

$noiseByDay = @{}
foreach ($n in $noise) {
  $d = [string]$n.date
  if (-not $d) { continue }
  if ($noiseByDay.ContainsKey($d)) { $noiseByDay[$d] = $noiseByDay[$d] + 1 } else { $noiseByDay[$d] = 1 }
}

$readRows = ""
if ($toReadCount -eq 0) {
  $readRows = '<p class="empty">Nothing to catch up on. No informative mail filed yet.</p>'
} else {
  $byDay = $toRead | Group-Object date | Sort-Object Name -Descending
  foreach ($day in $byDay) {
    $d = $day.Name
    $readRows += "<div class=""day""><div class=""dayhdr"">$(Enc $d)</div>`n"
    foreach ($m in $day.Group) {
      $sender = [string]$m.from_name
      if (-not $sender) { $sender = [string]$m.from_addr }
      $tag = ""
      if ($m.project) { $tag = "<span class=""tag"">$(Enc $m.project)</span>" }
      $readRows += "<div class=""msg""><div class=""msgtop""><span class=""sender"">$(Enc $sender)</span>$tag</div><div class=""subj"">$(Enc $m.subject)</div><div class=""sum"">$(Enc $m.summary)</div></div>`n"
    }
    $nc = 0
    if ($noiseByDay.ContainsKey($d)) { $nc = $noiseByDay[$d] }
    if ($nc -gt 0) { $readRows += "<div class=""noise"">+$nc filtered as noise</div>`n" }
    $readRows += "</div>`n"
  }
}

# ----------------------------------------------------------------------- assemble
$html = @"
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Porter - dashboard</title>
<style>
  :root { --accent: $Accent; }
  * { box-sizing: border-box; }
  body { margin: 0; font-family: -apple-system, Segoe UI, Roboto, Helvetica, Arial, sans-serif;
         background: #f4f6f8; color: #1f2430; font-size: 14px; line-height: 1.5; }
  header { background: var(--accent); color: #fff; padding: 18px 28px; }
  header h1 { margin: 0; font-size: 19px; font-weight: 600; letter-spacing: .02em; }
  header .meta { opacity: .85; font-size: 12px; margin-top: 3px; }
  .stats { display: flex; gap: 10px; padding: 14px 28px 0; flex-wrap: wrap; }
  .stat { background: #fff; border: 1px solid #e0e5ea; border-radius: 8px; padding: 8px 14px; }
  .stat b { font-size: 18px; display: block; }
  .stat.urgent b { color: #c0392b; }
  .stat.late b { color: #d68910; }
  .stat span { font-size: 11px; color: #6b7480; text-transform: uppercase; letter-spacing: .04em; }
  nav { display: flex; gap: 4px; padding: 16px 28px 0; border-bottom: 1px solid #e0e5ea; }
  nav button { border: none; background: none; padding: 10px 18px; font-size: 14px; cursor: pointer;
               color: #6b7480; border-bottom: 3px solid transparent; font-weight: 600; }
  nav button.active { color: var(--accent); border-bottom-color: var(--accent); }
  main { padding: 22px 28px 60px; }
  .tab { display: none; }
  .tab.active { display: block; }
  h3.proj { margin: 22px 0 6px; font-size: 13px; text-transform: uppercase; letter-spacing: .06em; color: #6b7480; }
  table { width: 100%; border-collapse: collapse; background: #fff; border: 1px solid #e0e5ea; border-radius: 8px; overflow: hidden; }
  th { background: #eef1f4; text-align: left; padding: 8px 10px; font-size: 11px; text-transform: uppercase;
       letter-spacing: .04em; color: #6b7480; }
  td { padding: 9px 10px; border-top: 1px solid #eef1f4; vertical-align: top; }
  td.bd { white-space: nowrap; }
  .cid { font-family: Consolas, monospace; font-size: 11px; color: #8a94a0; }
  .upd { color: #4a5360; font-size: 13px; max-width: 360px; }
  .row-urgent td { background: #fdf3f2; }
  .badge { display: inline-block; font-size: 10px; font-weight: 700; text-transform: uppercase;
           padding: 2px 6px; border-radius: 4px; margin-right: 3px; }
  .badge.urgent { background: #c0392b; color: #fff; }
  .badge.late { background: #d68910; color: #fff; }
  .gap { color: #c0392b; font-weight: 600; }
  .day { margin-bottom: 20px; }
  .dayhdr { font-weight: 700; color: var(--accent); border-bottom: 2px solid #e0e5ea; padding-bottom: 4px; margin-bottom: 8px; }
  .msg { background: #fff; border: 1px solid #e0e5ea; border-radius: 8px; padding: 10px 14px; margin-bottom: 8px; }
  .msgtop { display: flex; justify-content: space-between; align-items: center; }
  .sender { font-weight: 600; }
  .tag { font-size: 10px; background: #eef1f4; color: #6b7480; padding: 2px 8px; border-radius: 10px;
         text-transform: uppercase; letter-spacing: .04em; }
  .subj { color: #2b3340; margin-top: 2px; }
  .sum { color: #6b7480; font-size: 13px; margin-top: 2px; }
  .noise { color: #aab2bd; font-size: 12px; font-style: italic; margin: 4px 0 0 2px; }
  .empty { color: #8a94a0; padding: 30px 0; text-align: center; }
</style>
</head>
<body>
<header>
  <h1>Porter - inbox dashboard</h1>
  <div class="meta">Generated $builtAt &middot; cards are the source of truth, this view is rebuilt each run</div>
</header>
<div class="stats">
  <div class="stat"><b>$openCount</b><span>open actions</span></div>
  <div class="stat urgent"><b>$urgentCount</b><span>urgent</span></div>
  <div class="stat late"><b>$lateCount</b><span>late</span></div>
  <div class="stat"><b>$toReadCount</b><span>to read</span></div>
</div>
<nav>
  <button id="t1" class="active" onclick="show(1)">Open actions</button>
  <button id="t2" onclick="show(2)">To read, per day</button>
</nav>
<main>
  <div id="tab1" class="tab active">
$cardRows
  </div>
  <div id="tab2" class="tab">
$readRows
  </div>
</main>
<script>
  function show(n) {
    document.getElementById('tab1').classList.toggle('active', n === 1);
    document.getElementById('tab2').classList.toggle('active', n === 2);
    document.getElementById('t1').classList.toggle('active', n === 1);
    document.getElementById('t2').classList.toggle('active', n === 2);
  }
</script>
</body>
</html>
"@

$html | Set-Content -LiteralPath $Out -Encoding utf8
Write-Host "Dashboard written to $Out  ($openCount open actions, $toReadCount to read)"
