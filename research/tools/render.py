"""Render research/videos/*.md from curated-input.json + search metadata.

Usage: python research/tools/render.py
Writes research/data/curated-videos.json (enriched) and one Markdown report per category.
"""
import json
import pathlib

ROOT = pathlib.Path(__file__).resolve().parents[1]
raw = json.loads((ROOT / "data" / "search-results-raw.json").read_text(encoding="utf-8"))
cur = json.loads((ROOT / "data" / "curated-input.json").read_text(encoding="utf-8"))

meta = {}
for vids in raw.values():
    for v in vids:
        meta[v["id"]] = v
meta.update({k: {**v, "id": k} for k, v in cur["extra_metadata"].items()})

BASIS = {
    "known": "Known talk",
    "inferred": "From title + description",
}


def fmt_dur(s):
    s = int(s or 0)
    return f"{s // 60}:{s % 60:02d}"


out = {"categories": {}}
for key, cat in cur["categories"].items():
    rows, enriched = [], []
    for i, (vid, basis, take) in enumerate(cat["videos"], 1):
        m = meta[vid]
        title = m["title"].replace("|", "/")
        enriched.append({"id": vid, "title": m["title"], "channel": m["channel"], "views": m["views"],
                         "duration": m["duration"], "basis": basis, "takeaway": take})
        rows.append(f"| {i} | [{title}](https://www.youtube.com/watch?v={vid}) | {m['channel']} | "
                    f"{m['views']:,} | {fmt_dur(m['duration'])} | {BASIS[basis]} | {take} |")
    out["categories"][key] = {"name": cat["name"], "videos": enriched}
    n_known = sum(1 for v in cat["videos"] if v[1] == "known")
    md = [
        f"# {cat['name']}: top 20 videos",
        "",
        "How these were picked: yt-dlp search across 6 queries for this topic, about 25 results each, Shorts removed. "
        "Videos were ranked by reach (log of views) and relevance (how many queries returned them, and how high), "
        "then hand-checked for topic fit. View counts are from Nov 2026.",
        "",
        f"How much to trust each takeaway: **{n_known}/20** are well-documented talks or essays, summarised from what they're known to cover. "
        f"The other {20 - n_known} are **from title + description**: YouTube blocked transcript downloads from the cloud session, "
        "so read those as hypotheses until you've watched the video or run "
        "`research/tools/fetch_transcripts.py` on your own computer.",
        "",
        "## Recurring patterns across the 20",
        "",
        *[f"- {p}" for p in cat["patterns"]],
        "",
        "## Video log",
        "",
        "| # | Video | Creator | Views | Length | Source of takeaway | Core takeaway |",
        "|---|---|---|---:|---:|---|---|",
        *rows,
        "",
    ]
    (ROOT / "videos" / cat["file"]).write_text("\n".join(md), encoding="utf-8")
    print("wrote", cat["file"], f"({len(rows)} videos, {n_known} known)")

(ROOT / "data" / "curated-videos.json").write_text(json.dumps(out, indent=1, ensure_ascii=False), encoding="utf-8")
