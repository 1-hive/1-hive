import json, os, subprocess, tempfile

ARCHIVE = os.path.expanduser("~/work/parity/archive")   # the coordinator's archive


def launch_seat(game_id, seat):
    """Start one seat process: same user, empty cwd, scrubbed environment."""
    cwd = tempfile.mkdtemp()
    env = {"PATH": "/usr/bin", "GAME": game_id, "SEAT": str(seat)}
    return subprocess.Popen(["python3", "seat.py"], cwd=cwd, env=env)


def run_game(server, seed, stratum):
    game = server.create_game(seed=seed, stratum=stratum)
    seats = [launch_seat(game.id, s) for s in (0, 1)]
    for p in seats:
        p.wait()
    record = server.owner_record(game.id)          # full record: config (with seed) and result
    os.makedirs(ARCHIVE, exist_ok=True)
    with open(os.path.join(ARCHIVE, f"{game.id}.jsonl"), "w") as f:
        for line in record:
            f.write(json.dumps(line) + "\n")
    row = {"game": game.id, "stratum": stratum, "winner": record[-1]["winner"]}
    return row                                      # the summary row carries no seed


def run_all(server, seeds):
    return [run_game(server, s, i % 24) for i, s in enumerate(seeds)]
