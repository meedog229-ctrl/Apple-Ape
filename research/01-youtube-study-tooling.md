# Step 1: YouTube study tooling

*Researched 2026-11-19 with GitHub repository search. Each candidate below was shallow-cloned and its README and requirements checked.*

## What the workflow needs

1. **Discover** videos for a topic and rank them, using title, channel, views and length.
2. **Fetch transcripts** so takeaways come from what the video actually says.
3. **Summarise and compare** across videos. Claude does this once transcripts are saved as text.
4. *(Optional)* **Look at frames or visuals** when the point is visual, such as UI or VFX breakdowns.

## Comparison

| Tool | Stars / last commit | What it does | Setup | Reliability | Needs |
|---|---|---|---|---|---|
| **[yt-dlp/yt-dlp](https://github.com/yt-dlp/yt-dlp)** | ~209k / Nov 2026 | Search, metadata, subtitles, downloads | `pip install yt-dlp` | Best maintained. Search worked from the cloud session. Subtitles and video pages hit YouTube's bot check on cloud IPs. | Nothing. Optionally `deno` for full extraction. |
| **[jdepoix/youtube-transcript-api](https://github.com/jdepoix/youtube-transcript-api)** | ~8.6k / Nov 2026 | Transcripts with timestamps, no API key | `pip install youtube-transcript-api` | Very good from a home IP. Cloud IPs get blocked. Supports proxies. | Nothing |
| **[jkawamoto/mcp-youtube-transcript](https://github.com/jkawamoto/mcp-youtube-transcript)** | ~500 / Nov 2026, MIT | MCP server that lets Claude Code read transcripts directly | `uvx` one-liner (below) | Good. Has proxy settings for IP bans. | `uv` installed |
| [kimtaeyoon83/mcp-server-youtube-transcript](https://github.com/kimtaeyoon83/mcp-server-youtube-transcript) | ~600 / Jul 2026 | MCP transcripts. Optional video analysis. | `npx` | Good | Node. A TwelveLabs key only for the analysis feature. |
| [coyaSONG/youtube-mcp-server](https://github.com/coyaSONG/youtube-mcp-server) | ~27 / Oct 2026 | Citation-ready transcript search across 2–5 videos. Optional Data API search. | `npx` or Docker | Newer and smaller project | YouTube Data API key only for search |
| [guimatheus92/mcp-video-analyzer](https://github.com/guimatheus92/mcp-video-analyzer) | ~130 / Nov 2026 | Frames, OCR, Whisper fallback, works on many sites | `claude mcp add video-analyzer -- npx mcp-video-analyzer@latest` | Heavier (downloads video) | Node 22+, optional Whisper |
| [Galbaz1/video-research-mcp](https://github.com/Galbaz1/video-research-mcp) | ~24 / Nov 2026 | Full video understanding through Gemini | `uvx` | Powerful, but its analysis runs on a third-party model | **Gemini API key**, FFmpeg |
| [ZeroPointRepo/youtube-skills](https://github.com/ZeroPointRepo/youtube-skills) | ~1.2k / Sep 2026 | Claude skills for transcripts, search and channels | Skill install | Depends on an external service | **TranscriptAPI.com key** (paid service, free tier). The agent stores the key in your shell config. |
| [Dicklesworthstone/bulk_transcribe_youtube_videos_from_playlist](https://github.com/Dicklesworthstone/bulk_transcribe_youtube_videos_from_playlist) | ~700 / Feb 2025 | Whisper transcription of whole playlists | Python + Whisper | Slow without a GPU. Inactive. | GPU recommended |

## Recommendation

**Use yt-dlp for discovery and youtube-transcript-api for transcripts, running on your own computer.** Optionally add the jkawamoto MCP server so Claude can read transcripts while you chat.

Why:
- Both are free, keyless, MIT/Unlicense, actively maintained, and very widely used.
- The MCP and skill options mostly wrap these same libraries, or add paid or third-party model dependencies (Gemini, TranscriptAPI, TwelveLabs). This workflow doesn't need those.
- Frame analysis (mcp-video-analyzer) is worth adding later only for visual studies, such as breaking down a top game's UI or VFX.

### What happened in the cloud session

- Search worked: all 36 discovery searches ran through yt-dlp. The results are saved in `research/data/search-results-raw.json`.
- Transcripts did not. YouTube answered both yt-dlp and youtube-transcript-api with **"Sign in to confirm you're not a bot"**, which it does for most datacenter IPs. I did not try to get around it with cookies or browser impersonation.
- So the takeaways in `research/videos/` are labelled by where they came from. Well-documented talks are summarised from what they're known to cover. The rest are from title + description and should be checked against transcripts.
- The network change was saved as a personal cloud environment, **"Apple-Ape (YouTube research)"**. It allows `www.youtube.com`, `youtube.com`, `m.youtube.com` and `i.ytimg.com`.

## How to run it cleanly (on your own computer)

```bash
# from the Apple-Ape repo root
python3 -m venv .venv && source .venv/bin/activate     # Windows: .venv\Scripts\activate
pip install yt-dlp youtube-transcript-api

# 1) Re-run discovery (optional; results are already saved)
python research/tools/discover.py "$(which yt-dlp)" research/data/search-results-raw.json
python research/tools/rank.py research/data/search-results-raw.json 30 retention   # inspect the ranking

# 2) Fetch transcripts for the 120 curated videos -> research/transcripts/<category>/<id>.md
python research/tools/fetch_transcripts.py            # or: ... fetch_transcripts.py fun monetization

# 3) Rebuild the category reports after editing research/data/curated-input.json
python research/tools/render.py
```

Then ask Claude Code: *"Read research/transcripts/monetization and correct the takeaways marked 'From title + description' in research/videos/05-monetization.md."*

### Optional: let Claude read transcripts directly (MCP)

```bash
claude mcp add youtube-transcript -- uvx --from git+https://github.com/jkawamoto/mcp-youtube-transcript mcp-youtube-transcript
```

This needs [`uv`](https://docs.astral.sh/uv/). If YouTube starts blocking your IP after heavy use, the README covers proxy settings.

## Files

| Path | Purpose |
|---|---|
| `research/tools/discover.py` | Runs the 36 topic searches through yt-dlp and saves raw results |
| `research/tools/rank.py` | Scores candidates by reach (log of views) and relevance, and removes Shorts |
| `research/tools/fetch_transcripts.py` | Saves timestamped transcripts as Markdown (run it locally) |
| `research/tools/render.py` | Builds `research/videos/*.md` from `research/data/curated-input.json` |
| `research/data/curated-videos.json` | The final 120 videos with metadata and takeaways |
