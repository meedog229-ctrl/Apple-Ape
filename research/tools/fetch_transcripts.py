"""Fetch YouTube transcripts for the curated video list and save one Markdown file per video.

Run this on your OWN computer (home internet). YouTube blocks most cloud/datacenter IPs
with a "confirm you're not a bot" wall, which is why the cloud research session could not
pull transcripts itself.

Setup (once):
    python3 -m venv .venv && source .venv/bin/activate      # Windows: .venv\\Scripts\\activate
    pip install youtube-transcript-api

Usage:
    python research/tools/fetch_transcripts.py                 # all categories
    python research/tools/fetch_transcripts.py fun retention   # only some categories

Output: research/transcripts/<category>/<video-id>.md  (skips files that already exist)
Then ask Claude: "read research/transcripts/fun and update research/videos/06-fun.md takeaways".
"""
import json
import pathlib
import sys
import time

from youtube_transcript_api import YouTubeTranscriptApi

ROOT = pathlib.Path(__file__).resolve().parents[1]
curated = json.loads((ROOT / "data" / "curated-videos.json").read_text(encoding="utf-8"))
wanted = sys.argv[1:] or list(curated["categories"])
api = YouTubeTranscriptApi()

for cat in wanted:
    out_dir = ROOT / "transcripts" / cat
    out_dir.mkdir(parents=True, exist_ok=True)
    for v in curated["categories"][cat]["videos"]:
        vid = v["id"]
        out = out_dir / f"{vid}.md"
        if out.exists():
            continue
        try:
            t = api.fetch(vid, languages=["en", "en-US", "en-GB"])
        except Exception as e:  # no captions, private video, rate limit...
            print(f"[skip] {cat}/{vid}: {type(e).__name__}")
            continue
        lines = []
        for s in t.snippets:
            m, sec = divmod(int(s.start), 60)
            lines.append(f"[{m:02d}:{sec:02d}] {s.text}")
        out.write_text(
            f"# {v.get('title', vid)}\n\nhttps://www.youtube.com/watch?v={vid}\n\n" + "\n".join(lines) + "\n",
            encoding="utf-8",
        )
        print(f"[ok]   {cat}/{vid} ({len(lines)} lines)")
        time.sleep(1.5)  # be polite; avoids rate limiting
