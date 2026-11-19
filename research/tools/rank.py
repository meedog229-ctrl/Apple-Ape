"""Score discovered videos: reach (log views) + search relevance (hits, best rank). Print top N per category."""
import json, math, sys

data = json.load(open(sys.argv[1]))
N = int(sys.argv[2])
cats = sys.argv[3:] or list(data)
for cat in cats:
    vids = [v for v in data[cat] if (v["duration"] or 0) >= 90]  # drop Shorts
    for v in vids:
        best = min(h["rank"] for h in v["hits"])
        rel = len(v["hits"]) * 1.5 + max(0, 25 - best) / 5
        v["score"] = round(math.log10(max(v["views"], 10)) * 2 + rel, 2)
    vids.sort(key=lambda v: -v["score"])
    print(f"\n##### {cat} ({len(vids)} candidates)")
    for i, v in enumerate(vids[:N], 1):
        print(f"{i:2} {v['score']:5} {v['id']} | {v['views']:>9,} | {v['duration']//60:>3}m | {v['channel'][:22]:22} | {v['title'][:85]}")
