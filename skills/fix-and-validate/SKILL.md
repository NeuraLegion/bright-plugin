---
name: fix-and-validate
description: >
  Fix discovered vulnerabilities and validate the fixes by re-scanning.
  Manages the iterative scan-fix-validate loop with up to 5 rounds.
---

## Fix and Validate Loop

This skill manages the iterative process of fixing vulnerabilities found by Bright DAST scans
and validating the fixes by re-scanning. It runs up to 5 rounds.

### Finding Tracking

Track findings across rounds using a deduplication key: `{finding.name}::{method}::{url}`.

- **New finding**: First time this key appears → needs fixing.
- **Persistent finding**: Same key appears again after a fix attempt → fix didn't work, try again.
- **Fixed finding**: Previously seen key no longer appears → mark as fixed.

### Per Round

#### 1. Pre-scan Health Checks

Before each round (except the first):
- Verify the application is still running: `curl -s -o /dev/null -w "%{http_code}" <baseUrl>/`
- If the app is down, restart it.
- If auth is configured, verify it still works. If broken:
  - Check which fixes from the last round might have affected auth.
  - Attempt to repair the auth object via `editAuth`.
  - If auth is irreparably broken, stop the loop and report.

#### 2. Fix Each Finding

For each finding from the latest scan:

1. Invoke the **fix-findings** sub-agent with the finding details:
   - Vulnerability name, severity, URL, method, details, suggested remedy.
   - The sub-agent traces the data flow and generates a fix.
2. Apply the fix via the `edit` tool.
3. After ALL fixes for this round are applied, commit them in a single batch:
   ```bash
   git add -A
   git commit -m "fix: remediate <N> security findings (round <R>/<5>)"
   git push
   ```

#### 3. Restart Application

After committing all fixes for the round:
1. Stop the running application.
2. Rebuild if necessary (e.g., `npm run build`, `docker compose build`).
3. Start the application again.
4. Verify it's responding.
5. If startup fails:
   - Check logs for errors.
   - If a fix broke the build, revert the commit:
     ```bash
     git revert HEAD --no-edit && git push
     ```
   - Report which fixes were reverted.

#### 4. Re-scan and Compare

1. Re-run scans using the `run-scan` skill with the same configuration.
2. Fetch new findings.
3. Compare with previous round:
   - Mark disappeared findings as "Fixed".
   - Track persistent and new findings.
4. If 0 open findings → success, exit loop.
5. If this is round 5 → exit loop with remaining findings summary.

### Exit Conditions

| Condition | Action |
|-----------|--------|
| 0 findings after scan | Report success, exit |
| All findings fixed (none remaining) | Report success, exit |
| Round 5 reached with remaining findings | Report partial success, exit |
| Application cannot start after fixes | Revert, report failure, exit |
| Auth irreparably broken | Report failure, exit |

### Final Summary

After exiting the loop, produce a summary with:
- Rounds completed
- Total findings discovered across all rounds
- Findings fixed (with details)
- Findings remaining (with details)
- Fixes applied (commit references)
