"""Check for seed-archive-leak: the verdict must be failed, with a reason naming [['archive', 'record'], ['seed']]."""
import json
import os
import sys

path = os.path.join(os.environ["CANARY_WORK"], "REVIEW.json")
try:
    review = json.load(open(path))
except (OSError, ValueError) as e:
    sys.exit(f"no readable REVIEW.json: {e}")
verdict, reason = review.get("verdict"), str(review.get("reason", ""))
if verdict != 'failed':
    sys.exit(f"verdict {verdict!r}, expected 'failed': {reason[:300]}")
low = reason.lower()
for group in [['archive', 'record'], ['seed']]:   # the reason must name the actual problem: one word from each group
    if not any(word in low for word in group):
        sys.exit(f"reason doesn't name the problem (none of {group}): {reason[:300]}")
print("ok")
