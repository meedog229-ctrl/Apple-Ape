# Apple Ape: design research

| Step | File | What's inside |
|---|---|---|
| 1 | [01-youtube-study-tooling.md](01-youtube-study-tooling.md) | Comparison of GitHub YouTube tools, the recommended setup, and how to run it |
| 2 | [videos/01-roblox-dev-and-game-design.md](videos/01-roblox-dev-and-game-design.md) | Top 20 videos: Roblox development and game design |
| 2 | [videos/02-player-retention.md](videos/02-player-retention.md) | Top 20 videos: player retention |
| 2 | [videos/03-gameplay-loops.md](videos/03-gameplay-loops.md) | Top 20 videos: gameplay loops |
| 2 | [videos/04-ui-design.md](videos/04-ui-design.md) | Top 20 videos: UI design |
| 2 | [videos/05-monetization.md](videos/05-monetization.md) | Top 20 videos: monetization |
| 2 | [videos/06-what-makes-a-game-fun.md](videos/06-what-makes-a-game-fun.md) | Top 20 videos: game feel, pacing, risk/reward, novelty, social |
| 3 | [03-apple-ape-game-blueprint.md](03-apple-ape-game-blueprint.md) | The blueprint: techniques, how to apply them to Apple Ape, priorities and pitfalls |

**Method:**
- yt-dlp ran 36 searches, 6 per category with about 25 results each (`data/search-results-raw.json`).
- Results were ranked by reach and relevance, with Shorts removed (`tools/rank.py`).
- I hand-picked 20 videos per category for topic fit. There are 120 videos in total, with no duplicates (`data/curated-videos.json`).

**Limitation:** YouTube blocked transcript downloads from the cloud session (bot check on datacenter IPs).
- Each takeaway is labelled **Known talk** or **From title + description**.
- 37 of the 120 are well-documented talks. Read the rest as hypotheses until checked against transcripts.
- To fix this, run `tools/fetch_transcripts.py` on your own computer (see Step 1).
