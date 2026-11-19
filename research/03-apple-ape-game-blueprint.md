# Apple Ape: game design blueprint

*Built from the 120-video study in `research/videos/`. Roblox-specific numbers come from the design skills installed in `.claude/skills/` (roblox-game-design, roblox-growth-design, roblox-player-psychology). Numbers marked "community-reported" come from developers, not from Roblox.*

---

## 0. Assumptions (edit these first)

Your request left the concept, current state and goals as placeholders. This blueprint is tailored to what the repo contains: the repo is named **Apple-Ape**, and `apple_2_earn.html` is a demo page for a crypto token "drop" that pays holders every 10 minutes. I assumed the following:

| Field | Assumed value | If it's wrong |
|---|---|---|
| **Concept / genre** | **Apple Ape**, a mobile-first **collecting simulator**. You play an ape who shakes trees for apples, fills a basket, sells the apples, upgrades, unlocks new orchards and "Evolves" (rebirths). The **10-minute Apple Drop** from `apple_2_earn.html` becomes a server-wide in-game event. | Replace §1. Most techniques in §3–§8 apply to any genre. |
| **Audience** | Roblox players aged about 9–15, mostly on phones, playing solo or with friends | Adjust the UI and pricing sections |
| **Current state** | Concept only. No Roblox place is built yet. The repo has only the HTML demo page. | Mark finished items in §9 |
| **Constraints / goals** | Solo or small team. Reach a playable launch in about 4–6 weeks. Targets: D1 ≥ 20%, D7 ≥ 4%, average session ≥ 15 min, tutorial completion ≥ 80%. Earn Robux through passes and products. | Change the targets in §2 |

> ⚠️ **Don't bring the crypto mechanic into Roblox.** Real-money value, token payouts and promoting cryptocurrency or real-world trading are against Roblox's rules. Check the current Roblox Terms of Use and Community Standards before you publish. Everything below keeps the *feel* of "a drop every 10 minutes, shared by contribution" using **in-game currency only**. Avoid "2 Earn" or anything that sounds like crypto in the game's title and thumbnails.

---

## 1. The game in one page

**Fantasy:** a cheeky ape building the biggest apple stash in the jungle.

**Core loop:**
> **Shake a tree → apples burst out and you grab them (juicy feedback) → basket fills → sell at the Stash for Coins → buy an upgrade (bigger basket, stronger shake, faster climb) or a helper monkey → reach a richer orchard → Evolve for a permanent multiplier and a new ape look.**

**The three loop layers** (from Adam Millard, Timothy Cain and Extra Credits on progression):

| Layer | Timescale | Apple Ape content |
|---|---|---|
| Moment-to-moment | seconds | Shake → apple burst → collect combo → basket bar fills |
| Session | 5–20 min | Fill → sell → upgrade, plus **an Apple Drop every 10 min**, daily quests, the next orchard unlock |
| Long-term | days–weeks | Orchards 1→6, Evolve tiers (Chimp → Gorilla → Silverback → Golden Ape → Space Ape), a helper-monkey collection, Stash Garden harvests, seasonal events |

**Signature twist: the Apple Drop** (the HTML page's mechanic, adapted):
- A countdown at the top of the HUD ticks to every :00, :10, :20 and so on. This is the same 10-minute cycle as `apple_2_earn.html`.
- During each cycle, every apple anyone in the server collects adds to a shared **Drop Pool**.
- At zero, a giant crate parachutes into the plaza. That triggers **60 seconds of Apple Rain**, a frantic co-op scramble, and then pays out **Golden Apples** to every player in proportion to what they contributed this cycle. A minimum floor means new players always get something.
- The **Apelist** board (the "top holders" table from the demo) becomes the leaderboard of top contributors for this Drop, today, and all time.
- Why it works: it gives a built-in reason to stay 10 more minutes (pacing and appointment play), makes other players helpful rather than rivals (social and positive-sum), creates a reliable peak in every session (tension and release), and makes a great clip for thumbnails and Shorts.

---

## 2. Targets and how you'll measure them

| KPI | Target | Why this number |
|---|---|---|
| Tutorial / FTUE funnel completion | **≥ 80%** | Community-reported healthy baseline is about 85%. One tutorial went from 33% to 58% just by removing weak steps. |
| Average session | **≥ 15 min** | Community-reported: under ~8 min means the game is broken, and ~10 min is where Home recommendations start. The 10-minute Drop is designed to carry sessions past this. |
| D1 retention | **≥ 20%** | Community-reported simulator data: 14–17% D1 at 500–5k CCU, and 22% is called "fantastic". |
| D7 retention | **≥ 4%** | Community-reported: about 2–2.3% D7 is roughly the 85th–90th percentile for simulators. Treat 4% as a stretch goal. |
| Payer conversion | **1–2%** with healthy ARPDAU | Watch spend-days per user. Consumables raise it. |

Use the `roblox-analytics` skill to set up **Funnel events** for these steps:

1. Joined
2. Gained control
3. First shake
4. First full basket
5. First sell
6. First upgrade
7. Saw the first Drop
8. Reached orchard 2
9. First Evolve

Add **Economy events** for every Coin and Golden Apple source and sink. Fix the step with the biggest drop first.

---

## 3. Retention

**Techniques that came up most across the 20 videos:** fun in the first minute and a payoff within 5 (Roblox Creators onboarding videos, Onett's FTUE talk, Sakurai); teaching by doing; a concrete reason to come back tomorrow; diagnosing retention by phase (D1 = onboarding, D7 = progression, D30 = content and social); emotional hooks over purely rational ones (GDC "Rational to Emotional"); no compulsion traps (GMTK, "Designing Addiction").

| # | Technique | How to do it in Apple Ape | Priority |
|---|---|---|---|
| R1 | **Action in the first 10 seconds** | Spawn under a tree with a glowing arrow and a pulsing "TAP TO SHAKE" prompt. No menus, intro or character creation. Auto-pick every optional setting. | **Quick win** |
| R2 | **Early win plus "nerf, then restore"** | The first shake drops 10× normal apples so the basket fills almost at once. Then a Golden Apple pops out with hit-stop and a fanfare, a designed "moment of joy". | **Quick win** |
| R3 | **Guided first cycle (5 steps max)** | A beam guides shake → fill → walk to the Stash → sell → buy "Bigger Basket", with a finger-pointer cutout. Log each step in a funnel. | **Quick win** |
| R4 | **Visible next goals** | A HUD goal tracker shows one short goal ("Sell 50 apples"), one mid goal ("Unlock Green Glade") and one long goal ("Evolve to Gorilla"). Fast early levels: the first 3 player levels in under 3 minutes. | **Quick win** |
| R5 | **The Drop as a session hook** | The first Drop in a session is guaranteed within the first 10 minutes. A newcomer bonus doubles their first payout. Show "Next Drop in 4:12" on the HUD and on the sell screen. | **Core system** |
| R6 | **A reason to return tomorrow: Stash Garden** | Plant apple seeds in your Stash plot. They grow in real time (1h/4h/12h) and are ready tomorrow. On logout, show "Your Golden Tree is ready in 9h!" | **Core system** |
| R7 | **Escalating 7-day streak with a grace day** | Day 1: Coins. Day 3: a helper-monkey egg. Day 7: an exclusive ape hat. Missing one day doesn't reset the streak. Don't punish players for being away. | **Core system** |
| R8 | **Daily and weekly quests tied to the loop** | "Contribute 500 apples to Drops", "Shake 3 giant trees with a friend". Reward Golden Apples. | **Core system** |
| R9 | **Welcome-back recap** | After 3+ days away, show a one-screen recap: your Stash harvest, what changed, and one suggested goal (Mark Maxwell's video on getting back into a game). | Later |
| R10 | **LiveOps cadence** | A small content drop every 1–2 weeks: a new seasonal apple, an orchard skin, a monkey. Each update names the metric it should move. Release Friday afternoon (community-reported best time). | **After launch** |

**Pitfalls to avoid:**
- A tutorial longer than about 5 steps, or one with text walls.
- Daily rewards as the *only* reason to come back.
- Streaks that fully reset and make players feel punished.
- Panicking over noisy low-CCU stats. Wait for 10k+ visits before judging.
- Treating Drop-event spikes as proof of durable retention.

---

## 4. Gameplay loops

**Techniques that came up most:** three nested loops; writing the loop as a sentence; progression that changes how you play rather than just numbers (Extra Credits, Design Doc); economy sources matched by sinks (GMTK on economies); prestige and rebirth layers (GDC idle-games talk, Hevipelle); proving the core action is fun first.

| # | Technique | How to do it in Apple Ape | Priority |
|---|---|---|---|
| L1 | **Prototype the shake alone first** | Before any UI or content, build one tree plus shaking and collecting, with full juice. Test it with 3 people outside your circle. If shaking 50 times isn't fun, change it (timing-based "perfect shake", combos) before building anything else. | **Core system** (week 1) |
| L2 | **Upgrades that change play, not just +%** | Each orchard adds a new verb or tool: Green Glade has **bouncy trees** (catch apples mid-air for a bonus), Golden Canopy needs **climbing** to reach the top branches, Volcano Orchard has **hot apples** you must cool. Mix stat upgrades with ability unlocks (Ground Slam shakes nearby trees, Vine Swing for fast travel). | **Core system** |
| L3 | **Helper-monkey collection (pets)** | Monkeys auto-collect, buff shake power, or carry extra apples. Hatch them from eggs bought with Coins. **Show the odds and add a pity counter.** Each set completed gives a permanent bonus. | **Core system** |
| L4 | **Evolve (rebirth)** | Reset Coins and upgrades for a permanent ×multiplier, a new ape model and a title. This is the long-term layer and a status display. Gate each Evolve behind an orchard milestone, not raw grind. | **Core system** |
| L5 | **Sources and sinks** | Coins come from selling and go into upgrades, eggs and orchard gates. Golden Apples come from Drops, quests and streaks and go into rare eggs, cosmetics and Evolve boosts. Every new source added in an update needs a matching sink. | **Core system** |
| L6 | **Side loops for variety** | Fishing for apples in the river, a coconut-toss minigame in the plaza, and hidden Banana Shrines in each orchard (exploration). | Later |
| L7 | **Anti-tedium buttons** | "Sell All", "Max Buy" and "Upgrade ×10" on the HUD. A mobile player tapping 500 times is a churn risk. | **Quick win** |

**Pitfalls to avoid:**
- A pure number treadmill, where orchards are recolours with bigger values.
- Inflation from generous Drops with no sinks.
- Early Evolve gates that need hours of grind.
- Building 6 orchards before the shake is proven fun.

---

## 5. UI design

**Techniques that came up most:** mobile-first scaling; consistency over decoration; every button reacting (TweenService plus sound); designing in Figma in a stud or cartoony style; colour and type carrying meaning; a minimal HUD with clear hierarchy.

| # | Technique | How to do it in Apple Ape | Priority |
|---|---|---|---|
| U1 | **Mobile-first layout** | Scale-based sizing, `UIAspectRatioConstraint`, `ScreenInsets` safe areas, and thumb-zone buttons on the bottom right (Shake, Sell) and left edge (Shop, Monkeys, Evolve). Test on a phone emulator from the start. | **Quick win** |
| U2 | **A HUD that shows only what matters** | Top centre: the **Drop countdown** (the hero element, as in the HTML page). Top left: basket bar and Coins with a **"+" shop button**. Small goal tracker on the right. Nothing else by default. | **Quick win** |
| U3 | **Button feel** | Every button scales to 0.92 on press and 1.05 on hover, with a pop sound. Important buttons (Shop, Evolve-ready) get a slow shine sweep. | **Quick win** |
| U4 | **One visual language** | A chunky cartoony or stud style: thick dark outlines, 2–3 brand colours (apple red, leaf green, golden yellow), one rounded display font for numbers, and the same icon set everywhere. Mock it up in Figma first. | **Core system** |
| U5 | **Colour carries meaning** | Rarity colours (grey → green → blue → purple → gold) used the same way for monkeys, apples and eggs. Gold always means Golden Apples or premium-feeling rewards. | **Quick win** |
| U6 | **Shop as an information hub** | Tabs for Boosts, Monkeys, Gamepasses and Golden Apples. Each item says what it does in one line, in gameplay terms ("Basket holds 2× apples"). Quick to open and close, and doesn't pause play. | **Core system** |
| U7 | **Rewarding reveal screens** | Egg hatch, Evolve and Drop payout get full-screen moments: anticipation, burst, then the result card with the rarity colour. | **Core system** |
| U8 | **Readable numbers** | Abbreviate large values (1.2K, 3.4M), count up instead of jumping, and add floating "+12" pop-ups at the collection point. | **Quick win** |

**Pitfalls to avoid:**
- Offset-based layouts that break on phones.
- Popups at join.
- Menus more than 2 levels deep.
- Five different button styles.
- Tiny text, and hiding the shop.
- Building UI without the `roblox-user-interfaces` skill's responsive-layout guidance.

---

## 6. Monetization

**Techniques that came up most:** sell things that relieve a pain or let players express themselves, not paywalls; layer passes, products and VIP; consumables build habits; placement and timing; earnings depend on monetization depth, not CCU; server-authoritative purchases; no pay-to-win or pressure tactics.

| # | Product | Type | Pain it solves / value | Where it's offered | Priority |
|---|---|---|---|---|---|
| M1 | **Starter Pack** (≤ 49 R$): Golden Apples, a rare monkey, a hat | Dev product, one per player | Turns a non-payer into a payer, cheaply | Offered once, *after* the first Evolve or first Drop (value shown first) | **Quick win** |
| M2 | **2× Apples (15 min)** | Consumable dev product | Effort and grind | Sell screen; just before a Drop ("Boost your Drop share!") | **Quick win** |
| M3 | **Auto-Shake** | Game pass | Tap fatigue on mobile | Shop, plus a prompt after 200 manual shakes | **Core system** |
| M4 | **Mega Basket** (permanent +100% capacity) | Game pass | Constant walking back to sell | Contextual "basket full" moment, plus the shop | **Core system** |
| M5 | **+2 Monkey Slots / Lucky Hatch** | Game passes | Collection progress | Egg-hatch screen | **Core system** |
| M6 | **Drop Supercharge** (the whole server's next Drop pool ×2, buyer's name shown in a banner) | Dev product | Status, generosity, social | The Drop countdown ("Supercharge this Drop!") | **Core system**. A feel-good, positive-sum purchase. |
| M7 | **Golden Apple packs** (3 sizes: small / medium / large) | Dev products | Speed toward rare eggs and cosmetics | "+" next to the Golden Apple counter, and after the 3rd "not enough" message | **Core system** |
| M8 | **VIP** (chat tag, VIP orchard with a 10% richer tree, golden basket skin) | Game pass | Status and expression | Shop, and a VIP gate seen in the hub | Later |
| M9 | **Ape skins and limited seasonal hats** | Dev products or passes | Expression | Shop rotation (weekly) | After launch |

**Rules:**
- **Purchase pathways:**
  - a HUD shop button;
  - a "+" next to each currency;
  - on the **3rd** "not enough Coins" error in a session, open the relevant shop page once (soft errors before that).
- **Show monkey-egg odds and the pity counter.** If eggs are ever paid, they must follow Roblox's rules for paid random items. Check current policy before launch.
- **Implement purchases with the `roblox-gamepasses` + `roblox-datastores` skills.** Grant on the server in `ProcessReceipt`, idempotently, saved with session-locked data. Don't hard-code Robux prices in the UI.
- **Check side effects after each new product:** playtime, D1, D7 and economy inflation. A boost that breaks progression costs more than it earns.

**Pitfalls to avoid:**
- Pay-to-win advantages in the Drop that make free players feel cheated. Keep the Supercharge server-wide.
- Popups at join.
- Fake urgency or countdown sales.
- "Earn"/crypto language.
- Selling before players have experienced the fun.

---

## 7. Fun and game feel

**Techniques that came up most:** juice the most-repeated action most (GMTK "Secrets of Game Feel", "Juice it or lose it", "The Art of Screenshake"); feedback before content (Jonas Tyroller's button); risk/reward and interesting decisions (Sakurai, Sid Meier); pacing in waves with hit-stop on big moments (Sakurai, Extra Credits); fair randomness (GMTK "Two Types of Random"); intrinsic over extrinsic rewards; social moments.

| # | Technique | How to do it in Apple Ape | Priority |
|---|---|---|---|
| F1 | **Juice the shake** | Tree squash-and-stretch wobble, a leaf particle burst, apples arcing out with bounce, a rising-pitch "pop" as the combo builds, small camera shake on big shakes, floating "+N" numbers, and a basket wobble when an apple lands. | **Quick win**, the highest leverage item here |
| F2 | **Hit-stop on rare moments** | A Golden Apple or rare monkey freezes the game for 80–120 ms, then a sparkle burst, a chime and a slight slow-mo (Sakurai, "Stop for Big Moments"). | **Quick win** |
| F3 | **Skill in the core action** | A **Perfect Shake**: tap when the ring closes for ×2 apples, building a streak meter. This lifts the skill ceiling for engaged players without hurting casual ones. | **Core system** |
| F4 | **Risk/reward choices** | Hold-to-**Greedy Shake** gives more apples, but a coconut may fall and stun you. In Apple Rain, carry beyond capacity for a bonus, but drop it all if a bouncing coconut hits you. In Volcano Orchard, hot apples are worth 3× but must be delivered before they cool. | **Core system** |
| F5 | **Pacing waves** | The 10-minute cycle runs calm farming → rising tension (countdown, music speeds up, sky darkens) → Apple Rain peak → payout release. Alternate tension and relief within every session. | **Core system** (it's the Drop) |
| F6 | **Fair randomness** | Input randomness: which trees are "ripe" (glowing) each cycle, which creates route decisions. Output randomness (eggs) has pity and visible odds. | **Core system** |
| F7 | **Social moments** | **Giant Trees** need 2+ apes shaking together for a huge burst. A solo player can use a helper monkey as the second ape. Add emotes, Drop shout-outs ("Top contributor: …!") and stash visiting. | **Core system** |
| F8 | **Novelty schedule** | Something new every 10–15 minutes of early play: a new orchard, monkey, mechanic or event. | **Core system** |
| F9 | **Don't over-reward the fun part** | Keep the shake satisfying on its own merits. Don't bury it under currency pop-ups (overjustification effect). | Ongoing |

**Pitfalls to avoid:**
- Juice that hides a dull loop, so prove L1 first.
- Screen shake on every small action, which causes motion sickness. Add a settings toggle.
- Random outcomes that feel unfair.
- Griefing, such as stealing others' apples. Keep interactions positive-sum.

---

## 8. Roblox development (how to build it)

**Techniques that came up most:** scope small and ship fast; 80% proven / 20% novel; stats drive the algorithm; packaging is half the game; instrument from day one; funnel analytics.

| # | Technique | How to do it in Apple Ape | Priority / skill |
|---|---|---|---|
| D1 | **Scope a 4–6 week MVP** | 3 orchards, 1 Evolve tier, 8 monkeys, the Drop, Stash Garden, the shop with M1–M4 and M7. Everything else goes after launch. | **Core**. Keep the scope that small. |
| D2 | **Server-authoritative collecting** | The client plays the visuals. The server validates shake rate (cooldown), distance to the tree, and basket capacity, and owns all currency. Remotes are rate-limited and arguments validated. | **Core**. `roblox-networking` |
| D3 | **Safe saves** | ProfileStore-style session locking, a versioned schema, and idempotent receipt handling. | **Core**. `roblox-datastores`, `roblox-gamepasses` |
| D4 | **The Drop is server-timed** | Compute cycles from `os.time()` (UTC :00/:10/…) so every server agrees. The pool and contributions are server-side. Payout is granted once per cycle per player. | **Core**. `roblox-core` |
| D5 | **Mobile performance** | Pool apple parts (reuse them, don't create new ones each time), do visual-only apples on the client, enable streaming, cap particles, and test on a low-end phone. | **Core**. `roblox-testing`, `roblox-vfx` |
| D6 | **Instrumentation** | Funnel events for the FTUE (§2), economy events for every source and sink, custom events for Drops joined, Perfect Shakes and purchases. | **Quick win**. `roblox-analytics` |
| D7 | **Packaging** | An icon with an ape mid-shake and apples bursting. A thumbnail of Apple Rain chaos. A clear title (e.g. "Apple Ape Simulator 🍎"). Test 5+ thumbnails. Put a code in the description. | **Quick win**. `roblox-growth-design` |
| D8 | **Launch with small, steady ads** | Community-reported: about 16 ad credits/day for 3–4+ days, judged after 10k+ visits. Ship at least one update during the campaign. Stop ads once Home recommendations take over. | Launch week |
| D9 | **Weekly update rhythm** | Patches daily if needed; content weekly or bi-weekly; each update names one target metric. | After launch |
| D10 | **Optional tooling** | Rojo + Git for code (the `roblox-rojo` skill), and Studio MCP so Claude can build and playtest in Studio (`roblox-mcp`). | Optional |

**Pitfalls to avoid:**
- Trusting the client with currency.
- Building 6 orchards before launch.
- Launching without funnels.
- Clickbait thumbnails, which raise clicks but hurt retention signals.
- Copying another game's assets, names or exact look. Use the proven *structure* with your own theme.

---

## 9. Priority roadmap

### Phase A: Quick wins and prototype (week 1)
1. L1: one tree, shake and collect with **F1 juice** and **F2 hit-stop**.
2. Build a server-authoritative collection stub (D2) and save data (D3).
3. Build the HUD skeleton (U1, U2, U3, U8): basket bar, Coins with "+", and the Drop countdown.
4. Playtest with 3 people outside your circle. **Don't continue until shaking is fun.**

### Phase B: Core systems (weeks 2–4)
5. FTUE R1–R4 with funnel events (D6).
6. Upgrades and 3 orchards with new verbs (L2), Sell All / Max Buy (L7), and the economy plan (L5).
7. **The Apple Drop** (R5, F5, D4) and the Apelist leaderboard.
8. Monkeys, eggs with odds and pity (L3, F6), and the Evolve tier (L4).
9. Stash Garden (R6), 7-day streak (R7) and quests (R8).
10. Shop, Starter Pack, 2× boost, Auto-Shake, Mega Basket and Golden Apple packs (U6, M1–M4, M7).

### Phase C: Launch prep (weeks 5–6)
11. Perfect Shake, Greedy Shake, Giant Trees and solo fallback (F3, F4, F7).
12. Mobile performance pass (D5). Packaging and thumbnails (D7).
13. Private playtests, then fix the worst funnel step. Launch with small ads (D8).

### Phase D: After launch
14. Weekly LiveOps (R10), Drop Supercharge and VIP (M6, M8), side loops (L6), welcome-back recap (R9), and seasonal cosmetics (M9).

---

## 10. Next steps

- **Fill in the real concept, current state and goals** in §0, and I'll re-tailor this blueprint.
- **Upgrade the takeaways from title + description to transcript-based ones:** run `research/tools/fetch_transcripts.py` on your own computer, then ask Claude to update `research/videos/*.md` from `research/transcripts/`.
- **Start building:** ask Claude Code *"Use the roblox skills to build Phase A of research/03-apple-ape-game-blueprint.md"*.
