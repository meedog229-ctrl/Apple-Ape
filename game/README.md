# Apple Ape: Phase A prototype

This is the playable first slice of [the blueprint](../research/03-apple-ape-game-blueprint.md). Its job is to answer one question: **is shaking trees fun?**

## Play it in 30 seconds (no tools needed)

1. Download **`game/build/AppleApe.rbxlx`** from this branch.
2. Open Roblox Studio, then **File → Open from File…**, and pick that file.
3. Press **Play** (F5).

The whole map is built by code when the game starts, so the place looks empty in edit mode. That's expected.

**Controls:** walk up to a tree, then press **E**, click or tap the tree, or press the green **SHAKE** button. Walk near apples to collect them. Stand on the gold **SELL** pad to sell. Open the **🛒 SHOP** (or the **+** next to your coins) to upgrade.

## What's in this prototype

| Blueprint item | What you'll see |
|---|---|
| R1, R3: action in 10 seconds, teach by doing | You spawn facing the orchard. A golden beam and a bouncing arrow lead you to a tree, then to the sell stand. No text walls. |
| R2: early win | The **first shake is 10× bigger** and always includes a golden apple: "WOW! MEGA SHAKE!" |
| R4: visible next goal | Goal panel on the right, always showing one next step |
| L1, F1: juicy core action | Tree wobble, leaf burst, apples arcing out and bobbing, magnet pickup, pitch-rising pop combo, "+N" floating numbers, camera shake |
| F2: hit-stop on big moments | Golden apples: FOV punch, white flash, sparkles |
| L7, U1–U3, U5, U8 | Mobile-first HUD: basket bar, coins with +, golden counter, shop, buttons that squish when pressed, numbers that count up |
| R5, F5: the Apple Drop | Countdown top-centre and on the plaza tower. At zero, **Apple Rain** falls on the plaza for 30 s and anyone can grab apples. The cycle is **10 min live and 2 min in Studio**, aligned to UTC so every server agrees. The last 10 seconds tick and pulse. |
| D2: server authority | The server decides every apple, validates range, cooldowns, basket space and distance, and owns all currency. Remotes are rate-limited. |
| D3: safe saves | Session-locked DataStore saves with autosave and a final save on shutdown. Falls back to memory-only in unpublished places. |
| D6: analytics | Onboarding funnel steps (Joined → FirstShake → FirstCollect → BasketFull → FirstSell → FirstUpgrade → SawAppleDrop) and economy events |

**Not in Phase A yet:** the Drop's shared pool and golden payout, helper monkeys, Evolve, Stash Garden, daily streak and Robux products. Those are Phase B in the blueprint.

## Before you go further: the fun test (blueprint L1)

Get **3 people who don't know the game** to play for 5 minutes. Don't explain anything. Watch and note:

- [ ] Did they find and shake a tree without help?
- [ ] Did they keep shaking after the tutorial ended, without being told?
- [ ] Did they find the SELL pad and the SHOP?
- [ ] Did anyone react to the golden apple or the Apple Rain?
- [ ] Where did they get confused or stop?

If shaking isn't fun on its own, change the core action before adding Phase B. Ideas: timing-based "Perfect Shake", combos, bigger bursts. Tune numbers in `src/shared/Config.luau`.

## Saving data

- **Unpublished place:** progress resets when you stop. This is intentional, and you'll see a warning in Output.
- **To test real saves:** publish the place, then **Game Settings → Security → Enable Studio Access to API Services**. Use a test place, not your live game.

## Working on the code

The source is in `src/`, which is a Rojo 7 project (`default.project.json`):

```
src/shared/   Config (all tunable numbers), Remotes, Format      -> ReplicatedStorage.Shared
src/server/   World, PlayerData, PlayerState, Apples, Trees,
              Economy, AppleDrop, Analytics, RateLimiter         -> ServerScriptService.Server
src/client/   Hud, Juice, AppleVisuals, Guide, Sounds, Main      -> StarterPlayerScripts.Client
```

Two ways to work:

1. **Rojo live sync (recommended):** install [Rokit](https://github.com/rojo-rbx/rokit), run `rokit add rojo-rbx/rojo@7.6.1`, then `rojo plugin install`, then `rojo serve` inside `game/`. In Studio, open the Rojo plugin and click **Connect**.
2. **Rebuild the place file:** run `rojo build -o build/AppleApe.rbxlx` inside `game/`.

Checks used here: `stylua src` (formatting and Luau parse) and `selene src` (lint). `roblox-lite.yml` is a minimal Roblox globals file because the full selene Roblox std downloads from Roblox's CDN.

**Sounds** use built-in Studio sounds, so no uploads are needed. Swap the ids in `Config.Sounds` for your own when you have them.

## Known limits of this prototype

- **Primitive-part art.** Trees, apples and the stand are placeholders. Keep the `AppleTree` tag and the `TreeId`/`Base` attributes when you swap in real models.
- **Not yet run in Studio.** The code was written and checked in a cloud environment without Studio: it parses, lints clean and builds, but hasn't been run. Expect a few small fixes on the first Play. Paste any red Output errors back to Claude.
