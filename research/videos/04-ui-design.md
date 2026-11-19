# UI Design: top 20 videos

How these were picked: yt-dlp search across 6 queries for this topic, about 25 results each, Shorts removed. Videos were ranked by reach (log of views) and relevance (how many queries returned them, and how high), then hand-checked for topic fit. View counts are from Nov 2026.

How much to trust each takeaway: **4/20** are well-documented talks or essays, summarised from what they're known to cover. The other 16 are **from title + description**: YouTube blocked transcript downloads from the cloud session, so read those as hypotheses until you've watched the video or run `research/tools/fetch_transcripts.py` on your own computer.

## Recurring patterns across the 20

- **Mobile-first sizing.** Most Roblox players are on phones: Scale-based layouts, aspect-ratio constraints, safe areas, and thumb-sized buttons (≥ ~44px).
- **Consistency beats decoration.** One palette, one button style, consistent spacing and icons do more than individual flashy elements.
- **Every button reacts.** Hover/press tweens + a click sound are the cheapest polish with the biggest feel improvement.
- **Design in Figma, build in Studio.** Pros mock up screens first, then import; stud/cartoony styles fit Roblox's visual language.
- **Color and type carry meaning.** Use color to encode rarity/reward/danger and keep fonts legible at small sizes.
- **Minimal HUD, clear hierarchy.** Show only what matters now; surface the shop and next goal clearly without clutter.

## Video log

| # | Video | Creator | Views | Length | Source of takeaway | Core takeaway |
|---|---|---|---:|---:|---|---|
| 1 | [Make Your Roblox UI Look 10x Better](https://www.youtube.com/watch?v=F6AtQKo3uIY) | Develuper | 169,878 | 7:03 | From title + description | Fast UI upgrades: consistent palette, rounded corners, strokes, gradients, drop shadows and clear hierarchy make Roblox UI look professional. |
| 2 | [Making Good UI is EASY, People Are Just Lazy](https://www.youtube.com/watch?v=ZTzUHfMeYKA) | ByteBlox | 177,127 | 17:29 | From title + description | Good UI is mostly discipline: consistent spacing, alignment, readable fonts and a limited palette; laziness, not talent, is the gap. |
| 3 | [How Modern Roblox UI Actually Works](https://www.youtube.com/watch?v=Ezk3vEOvv8o) | Leif | 185,001 | 14:56 | From title + description | Modern pro Roblox UI is built with React-Luau (component-based, state-driven) for maintainability in larger games. |
| 4 | [The Greatest Cartoony UI Tutorial on Roblox (w/ Figma)](https://www.youtube.com/watch?v=z16zs2v-FNI) | Kek | 98,009 | 41:54 | From title + description | Design cartoony Roblox UI in Figma first (thick outlines, bold colors, chunky buttons), then import to Studio. |
| 5 | [The Greatest Stud UI Tutorial on Roblox (w/ Figma)](https://www.youtube.com/watch?v=gnIKtS3nUqo) | Kek | 74,772 | 61:51 | From title + description | Stud-style UI (Roblox-native chunky 3D look) workflow in Figma; matches the visual language many top games use. |
| 6 | [The Ultimate Beginner’s Guide to Roblox GUI](https://www.youtube.com/watch?v=lmNWskz9cEI) | Kek | 150,571 | 18:16 | From title + description | Beginner GUI fundamentals: ScreenGui, Frames, Scale vs Offset, layouts (UIListLayout/UIGridLayout), anchoring. |
| 7 | [How To Improve Your UI In Roblox Studio](https://www.youtube.com/watch?v=RPqIm0I_gsw) | Kingkade 3D | 47,324 | 11:44 | From title + description | Improve existing UI step by step: reduce clutter, add icons, use consistent button styles, improve contrast. |
| 8 | [How To Scale UI Across Devices In Roblox Studio](https://www.youtube.com/watch?v=1B46XsUvi2E) | Kingkade 3D | 38,856 | 4:36 | From title + description | Scale UI across phones, tablets and PC: use Scale sizing, UIAspectRatioConstraint, anchor points, and test on device emulators. |
| 9 | [Make Your Roblox UI Buttons SUPER Smooth in 8 Minutes!](https://www.youtube.com/watch?v=2z4rebjBnQA) | PineappleDev | 138,106 | 8:35 | From title + description | Smooth button feedback with TweenService: hover/press scale, color shift, and sound make buttons feel responsive. |
| 10 | [Make Your UI Feel 10x Times Better With ANIMATIONS](https://www.youtube.com/watch?v=8pJGBz-J75w) | Develuper | 56,933 | 6:59 | From title + description | Animate UI (open/close transitions, hover states, bounces) so the interface feels alive and responsive. |
| 11 | [How To Add Effects To UI In Roblox Studio](https://www.youtube.com/watch?v=p_T0V9Lg2Ns) | gfxcomet | 139,825 | 11:27 | From title + description | Add effects to UI (gradients animating, shine sweeps, particles) to draw attention to important buttons like the shop. |
| 12 | [Roblox UI Design Basics for Beginners](https://www.youtube.com/watch?v=FK3kBKCn6s8) | gfxcomet | 15,690 | 6:10 | From title + description | UI design basics for Roblox: hierarchy, contrast, consistency, and leaving breathing room. |
| 13 | [i hate modern game user interfaces](https://www.youtube.com/watch?v=gfEGk5rgdwc) | Stryxo | 1,291,591 | 14:20 | Known talk | Critique of modern game UIs: cluttered HUDs, menus nested too deep, and style over readability hurt the experience. |
| 14 | [The Power of Font In Video Games](https://www.youtube.com/watch?v=KIvLywqLCW0) | Juniper Dev | 899,326 | 15:09 | Known talk | Fonts carry tone and readability; pick a font that fits the game's mood and stays legible at small sizes. |
| 15 | [The Psychology of Color In Video Games](https://www.youtube.com/watch?v=IG5BIAaBwdE) | Juniper Dev | 215,985 | 13:38 | Known talk | Color psychology: use color consistently to signal meaning (rarity, danger, reward) and set emotional tone. |
| 16 | [Diegetic UI - Realistic, or Distracting? - Extra Credits](https://www.youtube.com/watch?v=-auyB19Mc6U) | Extra Credits | 269,062 | 7:54 | Known talk | Diegetic (in-world) UI can increase immersion but must stay readable; mix diegetic and screen UI pragmatically. |
| 17 | [10 Video Games With The BEST UI Design](https://www.youtube.com/watch?v=1PTkJTJE_Kc) | MojoPlays | 54,100 | 10:07 | From title + description | Examples of games with great UI: strong style identity, clarity under pressure, and smooth navigation. |
| 18 | [Game UI Design - How to design mobile game UI / BOOM QUEST E01 #gameart](https://www.youtube.com/watch?v=YJmbKrL_BUY) | Rushan Sanjana | 6,034 | 7:11 | From title + description | Mobile game UI workflow: big thumb-friendly buttons, bright readable icons, and layouts designed for the screen edges. |
| 19 | [How To Create Mobile Game UI Screen in Figma, Battlepass / Goldenpass Screen](https://www.youtube.com/watch?v=sVswlWdfqTs) | Game UI Design | 26,042 | 25:06 | From title + description | Designing a battle/season pass screen: clear tier track, free vs premium rows, and previewed rewards. |
| 20 | [How to make Animated Opening Shop Gui in Roblox (2024)](https://www.youtube.com/watch?v=u404sKevMPU) | Rileybytes | 132,312 | 8:40 | From title + description | Animated shop GUI in Roblox: open animation, item cards, and purchase buttons that feel rewarding. |
