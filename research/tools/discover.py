"""Run yt-dlp searches per category and save merged, de-duplicated results as JSON."""
import json, subprocess, sys, concurrent.futures as cf

YTDLP = sys.argv[1]
OUT = sys.argv[2]

QUERIES = {
    "roblox-dev": [
        "roblox game design tips", "how to make a successful roblox game",
        "roblox developer postmortem", "roblox game development advice front page",
        "roblox studio game dev mistakes", "how I made a popular roblox game",
    ],
    "retention": [
        "roblox player retention", "game player retention design",
        "how to make players come back game design", "roblox D1 D7 retention",
        "mobile game retention mechanics GDC", "first time user experience game onboarding",
    ],
    "gameplay-loops": [
        "core gameplay loop explained", "game design core loop meta loop",
        "roblox simulator game loop", "compulsion loop game design",
        "progression systems game design", "roblox tycoon game design loop",
    ],
    "ui-design": [
        "game UI design tips", "roblox UI design tutorial",
        "game UX design GDC", "mobile game UI design",
        "game HUD design", "roblox UI tips better ui",
    ],
    "monetization": [
        "roblox monetization tips robux", "roblox game passes developer products earn",
        "free to play monetization design GDC", "how roblox games make money",
        "ethical game monetization", "roblox devex earnings game",
    ],
    "fun": [
        "game feel juice", "what makes a game fun",
        "game design risk reward", "game pacing design",
        "why games are fun psychology", "social gameplay design multiplayer fun",
    ],
}


def search(cat, q):
    r = subprocess.run([YTDLP, "--flat-playlist", "-J", f"ytsearch25:{q}"],
                       capture_output=True, text=True, timeout=180)
    try:
        ents = json.loads(r.stdout)["entries"]
    except Exception:
        return cat, q, []
    return cat, q, ents


results = {c: {} for c in QUERIES}
jobs = [(c, q) for c, qs in QUERIES.items() for q in qs]
with cf.ThreadPoolExecutor(6) as ex:
    for cat, q, ents in ex.map(lambda a: search(*a), jobs):
        for rank, e in enumerate(ents):
            vid = e.get("id")
            if not vid:
                continue
            rec = results[cat].setdefault(vid, {
                "id": vid, "title": e.get("title"), "channel": e.get("channel"),
                "views": e.get("view_count") or 0, "duration": e.get("duration") or 0,
                "description": (e.get("description") or "")[:300],
                "url": f"https://www.youtube.com/watch?v={vid}", "hits": [],
            })
            rec["hits"].append({"q": q, "rank": rank})
        print(cat, q, len(ents), file=sys.stderr)

json.dump({c: list(v.values()) for c, v in results.items()}, open(OUT, "w"), indent=1)
