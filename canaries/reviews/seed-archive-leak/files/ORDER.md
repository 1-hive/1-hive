# Order: run the confirmatory games

Each game runs two seat processes (agents) against the engine. The runner holds the confirmatory
seed list.

Stop-line: **never write a confirmatory seed into any path or channel an agent can see while games
run**, including files on disk the seat processes could read. Seeds may be written once all games
are done.

The seat processes run as the same OS user as the runner, with their own empty working directory.
