# Rename: AlBayan → Tafakkur — Design

**Date:** 2026-06-08
**Status:** Approved (brainstorming)
**App version at design time:** v1.2 (build 4)

## Summary

Rebrand the app from **AlBayan: Quran & Tafsir** to **Tafakkur: Quran
Reflection**. This is a **display-name + App Store listing** change only — the
bundle ID (`MAHR.Partner.AlBayan`) stays untouched, so existing installs,
ratings, reviews, purchases, and CloudKit data are all preserved. The rename
realigns the brand with the app's chosen identity — **reflection & spiritual
growth** ("Read. Reflect. Grow.") — and moves it out of the crowded, hard-to-own
"Bayan" namespace into an ownable one.

## Why rename (strategic rationale)

The trigger was a download gap vs. the sibling Shia app *Thaqalayn: Two Weighty
Things*. Analysis during brainstorming concluded:

1. **The gap is mostly market structure, not the name.** The Sunni Quran-app
   space is saturated (Quran.com, Muslim Pro, Quran Majeed, Tarteel, Ayah…);
   the Shia niche *Thaqalayn* occupies is nearly empty. A rename alone won't
   close that gap — **the subtitle + keyword field do more for installs than the
   brand word**, so we fix those regardless.
2. **But the name genuinely hurts on one axis: ownability.** "Al Bayan" is a
   common term (UAE newspaper, other "Bayan" apps, a common Arabic word) — it
   can't *own* its search results the way the unusual word *Thaqalayn* does.
3. **The old name also fights the positioning.** "AlBayan" = *the clear
   exposition* (a study/explanation frame). The app is being built toward
   **reflection & growth** (Today tab, daily du'as, journeys, the reflection
   layer of the 3-layer tafsir). The brand word should mean what we want to be
   known for.

## Decisions (from brainstorming)

1. **Positioning / hero promise:** *Reflect & grow* — heart-centered, not
   study-centered. Crossover with the app's motivational / mental-health content
   voice.
2. **Direction:** Replace the brand word (not keep "AlBayan"), with a unique,
   **ownable** Arabic/Quranic term — the *Thaqalayn* move.
3. **Name:** **Tafakkur** (تفكّر). Verified open on the US/English App Store.
4. **Title variant:** **positioning-forward** (`Tafakkur: Quran Reflection`),
   chosen over the keyword-max `Tafakkur: Quran & Tafsir` — the latter reads
   almost identically to the old AlBayan title and re-buys the "blends into the
   category" problem.
5. **The QuranReflect overlap is acceptable.** "Quran reflection" is a generic
   positioning, not a brand a competitor can fence off; multiple apps can use it.

### Names considered and rejected (all verified *taken*, several by 2024–25 apps in the exact positioning)

| Word | Meaning | Why rejected |
|------|---------|--------------|
| Tadabbur | reflection on the Quran | ≥4 apps inc. *Tadabbur: Quran Journaling* (MWM) & *Tadabbur – Daily Quran* |
| Sakina | tranquility (48:4) | *Sakina: An Islamic Companion* (same wellness angle) + women's app; mild Karbala/Shia name association |
| Tazkiyah | growth/purification (91:9) | *Tazkiyah — Reset your Iman* + others |
| Sukoon | stillness/calm | *Sukoon: An Islamic App* (MWM) + *Sukoon Life* |
| Ihsan | excellence in faith | *Ihsan* (Ihsan Path) — exact "spiritual growth" pitch; common name |

Survivors that were verified **ownable**: **Tafakkur** (chosen), Baseerah,
Inshirah. Backups held in reserve: Rusūkh, Itmīnān, Tilāwah.

## The brand package

### Name & meaning
**Tafakkur — تفكّر**, the Quran's own word for deep reflection:
*"…and they reflect (yatafakkarūn) upon the creation of the heavens and the
earth"* (3:191). The name *is* the act the app exists for.

### Tagline / voice triad
**Read. Reflect. Grow.** — echoed across tagline, onboarding, screenshot
captions.

### App Store unit (the highest-weighted fields)
- **Title:** `Tafakkur: Quran Reflection` *(26/30 chars)*
- **Subtitle:** `Deep tafsir, duas & journeys` *(28/30 chars)*

Across both visible fields we own: **Quran · Reflection · Tafsir · Duas ·
Journeys**.

### Keyword field (hidden, 100 chars; no spaces; don't repeat title/subtitle words)
```
tafseer,commentary,ayah,surah,islam,muslim,urdu,dhikr,tadabbur,contemplation,journal,mushaf,recite
```
(~98 chars. "tafseer" catches the common alt-spelling. Tunable later with an ASO
tool.)

### Promotional text (updatable anytime, not indexed)
> *3-layer tafsir that finally makes every verse click — plus daily reflections,
> du'as, and guided journeys. Read. Reflect. Grow, with the Quran every day.*

### Wordmark / optics note
Always render title-case **Tafakkur** (never all-caps `TAFAKKUR`) and keep the
subtitle paired with it. Next to "Quran" the word reads unmistakably as Arabic;
established Tafakkur institutes/books confirm it's a non-issue in practice. The
Arabic **تفكّر** can anchor the icon/wordmark.

## What changes — and what is preserved

**Preserved (because the bundle ID does not change):**
- ✅ All installs, ratings, and reviews (same app record; users get an update).
- ✅ No reinstall; purchases, account, and CloudKit data intact.

**Costs:**
- ⚠️ Some keyword *ranking* re-seeds (offset by the stronger new subtitle).
- ⚠️ Brand *recognition* resets — acceptable at current scale.

**Rename surface area (becomes the implementation plan):**
- Xcode: `CFBundleDisplayName` (and any `PRODUCT_NAME`/display strings) →
  "Tafakkur". **Bundle ID unchanged.**
- App Store Connect: app name, subtitle, keywords, promotional text, full
  description.
- App icon / wordmark with the new name (+ optional Arabic mark).
- In-app strings referencing "AlBayan" (onboarding, about, settings, share text).
- Screenshot captions (the ASO screenshot set under
  `screenshots/appstore/aso/…`).
- Marketing/support site, Privacy Policy, and any GitHub Pages references.

## Out of scope / YAGNI
- Renaming the Xcode **target / scheme / folder** (`AlBayan`) — cosmetic, churn-
  heavy, and invisible to users. Keep as-is unless a later cleanup wants it.
- Changing the **bundle ID** — would orphan the app record and destroy all
  equity. Explicitly *not* done.

## Open items / due diligence before shipping
- Confirm the exact name **"Tafakkur: Quran Reflection" is available** in App
  Store Connect (name uniqueness is enforced at submission).
- Light **trademark** sanity check on "Tafakkur" as an app brand.
- Design the new **icon/wordmark**.
- Decide rollout: bundle the rename into the next version (e.g. v1.3) alongside
  the Today-tab / daily-du'as work already in flight.
