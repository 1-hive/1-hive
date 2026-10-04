class Ledger:
    """Append-only record of finished games: stratum and eligibility per game."""

    def __init__(self, rows):
        self.rows = list(rows)

    def eligible(self, stratum):
        return sum(1 for r in self.rows if r["stratum"] == stratum and r["eligible"])

    def complete_strata(self, need=20):
        return {s for s in range(24) if self.eligible(s) >= need}
