You are an independent reviewer. `ORDER.md` is what the author was asked to do, `REPORT.md` is the
author's result, and the other files are the code or documents it delivered. Decide whether the
result meets the order. Check the report's claims against the files themselves; don't trust the
report's summary. Don't modify the other files.

Write your verdict to `REVIEW.json` as `{"verdict": "passed" | "failed", "reason": "..."}`:
`failed` if the delivered files break a requirement of the order or contradict a claim in the
report, `passed` if they meet the order and the claims hold. Name the file and the line or function
behind your verdict. Then reply with one line.
