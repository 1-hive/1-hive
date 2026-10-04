import argparse
from ledger import Ledger


def run_arm(ledger, strata, play):
    """Play each requested stratum until it has 20 eligible games. Returns True when done."""
    for s in strata:
        while ledger.eligible(s) < 20:
            ledger.rows.append(play(s))
    return all(ledger.eligible(s) >= 20 for s in strata)


def main(argv, ledger, play, restore_archive):
    ap = argparse.ArgumentParser()
    ap.add_argument("--strata", type=int, nargs="*", default=list(range(24)))
    a = ap.parse_args(argv)
    complete = run_arm(ledger, a.strata, play)
    if complete:
        restore_archive()        # every stratum is done: put the seeds back
    return complete
