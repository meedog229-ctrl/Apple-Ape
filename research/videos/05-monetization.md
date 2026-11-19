# Monetization: top 20 videos

How these were picked: yt-dlp search across 6 queries for this topic, about 25 results each, Shorts removed. Videos were ranked by reach (log of views) and relevance (how many queries returned them, and how high), then hand-checked for topic fit. View counts are from Nov 2026.

How much to trust each takeaway: **1/20** are well-documented talks or essays, summarised from what they're known to cover. The other 19 are **from title + description**: YouTube blocked transcript downloads from the cloud session, so read those as hypotheses until you've watched the video or run `research/tools/fetch_transcripts.py` on your own computer.

## Recurring patterns across the 20

- **Sell pain-relievers and expression, not walls.** Best sellers remove friction (speed, auto-collect, protection, offline gains) or let players show off (cosmetics, rare items).
- **Layer products.** Combine one-time game passes, repeatable developer products, and optional subscriptions/VIP servers at several price points.
- **Consumables build habits.** Cheap repeatable products (boosts, refills) raise spending frequency more than one-off passes.
- **Placement and timing matter.** Put offers where players are and when they feel the need (e.g. 'not enough coins' → shop), not as interrupting popups.
- **Revenue per CCU varies 10-30x.** Monetization depth and retention, not player count, decide earnings.
- **Server-authoritative, idempotent purchases.** Grant in ProcessReceipt on the server and persist safely - lost purchases destroy trust.
- **No pay-to-win or manipulative pressure.** Creators and the critical videos agree: it kills retention and reputation.

## Video log

| # | Video | Creator | Views | Length | Source of takeaway | Core takeaway |
|---|---|---|---:|---:|---|---|
| 1 | [Mastering Monetization: Lessons from Top Creators / RDC 2026](https://www.youtube.com/watch?v=hoMbv_R8AMU) | Roblox | 8,412 | 30:23 | From title + description | Official RDC 2026 session with top creators' monetization lessons; layered products (passes, dev products, subscriptions) tied to gameplay value. |
| 2 | [Here's how I made 2.3M Robux in 3 days of work](https://www.youtube.com/watch?v=zW0VdnOqxMk) | waveshine | 1,507,933 | 4:01 | From title + description | The two easiest ways the creator found to earn Robux on Roblox, framed against low-effort tutorials; focus on proven product types. |
| 3 | [My Roblox Game Makes $119,300/mo (38K CCU, here's how)](https://www.youtube.com/watch?v=LZOohZHsJus) | Tizzy RBLX | 383,410 | 23:03 | From title + description | Breakdown of a 38K-CCU game's strategy and products; revenue comes from retention and many purchase pathways, not one product. |
| 4 | [How My 100 Player AI Roblox Game Made 2,000,000 Robux (NO BULLSH*T)](https://www.youtube.com/watch?v=KoGT6LokHBE) | Tap | 194,425 | 24:06 | From title + description | A 100-CCU game earned ~2M Robux: game passes and dev products that sold, and why retention/monetization depth beats raw CCU. |
| 5 | [How I made 23M ROBUX this year as a small roblox developer (5M Visits)](https://www.youtube.com/watch?v=wKI3PBO3bB0) | BruceDevs | 150,129 | 17:11 | From title + description | Small developer's year earning 23M Robux across games: many smaller titles, data-driven iteration, and focused products. |
| 6 | [Roblox Game Monetization Explained Like You're 5](https://www.youtube.com/watch?v=zoz3PSMqets) | Tizzy RBLX | 32,400 | 15:08 | From title + description | Monetization basics: game passes (one-time perks), developer products (repeatable), Premium payouts, and how to price them. |
| 7 | [Top 5 Ways to MONETIZE Your Roblox Game!](https://www.youtube.com/watch?v=5uXLixtTgJM) | RoBuilder | 44,344 | 8:36 | From title + description | Top monetization methods for Roblox games: passes, dev products, VIP/private servers, cosmetics, and limited-time offers. |
| 8 | [My Roblox Game Made $43,292 (Here's Exactly How to Monetize Yours)](https://www.youtube.com/watch?v=-PoyiiGhoNo) | MoseyTube77 | 34,616 | 6:05 | From title + description | Which developer products sold most in a $43K game and why: products that solve a pain at the moment players feel it. |
| 9 | [How to MONETIZE your ROBLOX GAME to EARN ROBUX](https://www.youtube.com/watch?v=r_p3iqil94Q) | Abstro | 54,347 | 8:47 | From title + description | How to add monetization to your game: placement of shop/purchase prompts and the types of items that sell. |
| 10 | [Every Roblox Monetization Strategy Explained in 5 Minutes](https://www.youtube.com/watch?v=k4j5DsbQnHM) | Wyrq | 2,095 | 5:13 | From title + description | Eight psychological 'traps' behind Roblox spending (scarcity, anchoring, sunk cost...) - know them to use ethically or avoid. |
| 11 | [Developer Products (Repeated Robux Pass) - Roblox Advanced Scripting #22](https://www.youtube.com/watch?v=n29WMYNTZHs) | BrawlDev | 64,485 | 30:52 | From title + description | Scripting developer products correctly: ProcessReceipt, idempotent server-side granting, saving purchases. |
| 12 | [Sell Developer Products EASILY with ProfileStore (Roblox Tutorial)](https://www.youtube.com/watch?v=8FIj3gmP5Ls) | Rileybytes | 20,623 | 38:14 | From title + description | Selling developer products with ProfileStore so purchases are granted once and persist safely. |
| 13 | [Let’s go whaling: Tricks for monetising mobile game players with free-to-play](https://www.youtube.com/watch?v=xNjI03CGkb4) | None | 0 | 19:49 | Known talk | F2P 'whale' monetization tricks explained; a cautionary look at manipulative designs and their reputational cost. |
| 14 | [I Spent 24 Hours With Roblox Millionaires](https://www.youtube.com/watch?v=8xgnm6SynH4) | Starter Story | 4,405,944 | 20:31 | From title + description | Day with Roblox millionaire devs: teams treat games as businesses - data, updates, ads, and monetization tuning. |
| 15 | [How much my 2k+ CCU Roblox game makes](https://www.youtube.com/watch?v=ZradA-cygP0) | Kradez | 30,365 | 11:26 | From title + description | Real earnings of a 2k+ CCU game; shows revenue per CCU varies hugely with monetization design. |
| 16 | [How Much Money Does a Roblox Game Actually Make?](https://www.youtube.com/watch?v=2Q4NqQikzsY) | VuukStudios | 32,669 | 15:19 | From title + description | Realistic earnings ranges for Roblox games and what separates well- from poorly-monetized games. |
| 17 | [How Much Money Roblox Developers Make?](https://www.youtube.com/watch?v=hxjumUFspP0) | janisjanis01 | 182,604 | 8:36 | From title + description | How much Roblox developers actually make: a few hits earn most; most games earn little - plan for many attempts. |
| 18 | [Converting $11,592,856 Robux to REAL LIFE MONEY As a Small Developer (Roblox DevEx)](https://www.youtube.com/watch?v=SUMTYryynss) | Kyblox | 1,089,889 | 4:39 | From title + description | DevEx walkthrough: converting earned Robux to real money, rates and requirements. |
| 19 | [How I Made $14M Robux in 1 WEEK](https://www.youtube.com/watch?v=K-4fRBnN2Ek) | Laughability | 6,657,745 | 51:51 | From title + description | Story of a game earning ~14M Robux in one week; how a viral spike plus ready monetization captured revenue. |
| 20 | [How Much Money I Made With 3 Roblox Games](https://www.youtube.com/watch?v=LD7LGP10dRc) | MonarchDev | 45,286 | 6:02 | From title + description | Small-scale reality check: three games, $130 of ads, ~9k visits - read straight from the dashboard. |
