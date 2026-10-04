import argparse
from ledger import Ledger

ALL = set(range(24))


def run_arm(ledger, strata, play):
    """Play each requested stratum until it has 20 eligible games."""
    for s in strata:
        while ledger.eligible(s) < 20:
            ledger.rows.append(play(s))


def main(argv, ledger, play, restore_archive):
    ap = argparse.ArgumentParser()
    ap.add_argument("--strata", type=int, nargs="*", default=sorted(ALL))
    a = ap.parse_args(argv)
    run_arm(ledger, a.strata, play)
    study_complete = ledger.complete_strata() == ALL    # the whole study, from the ledger
    if study_complete:
        restore_archive()
    return study_complete
