# Paywall Redesign — Tafakkur (AlBayan)

**Date:** 2026-06-16
**Status:** Approved design, ready to build
**Reference:** Thaqalyn premium paywall (`simulator_screenshot_3DE32EE9…png`, `…CA09EE31…png`)

## Goal
Redesign `PaywallView` for appeal + conversion, modeled on the approved reference. One-time lifetime model stays. Authentic trust signals only.

## Backend — UNCHANGED
- StoreKit 2, single product `com.albayan.premium.tafsir`, one-time non-consumable (lifetime).
- Price from `PurchaseManager.getProductPrice()` (`Product.displayPrice`) + an "ONE-TIME" suffix; fallback `"$9.99"` if not yet loaded.
- Purchase/restore via existing `PurchaseManager`; entitlement via `PremiumManager.isPremium`.
- **No new products, no subscription/trial, no backend or trigger changes.** All existing trigger points keep presenting `PaywallView`.

## Visual direction — FIXED dark premium (NOT theme-adaptive)
The paywall always renders dark navy + gold regardless of `ThemeManager.selectedTheme`. Define a **local palette** in `PaywallView` (do **not** read `ThemeManager` colors):
- bg gradient `#0D1430 → #080D20`; card fill white @ 3.5%, stroke white @ 7%
- gold `#D9C079`, bright gold `#F2E2A8`, gold gradient (CTA/pills) `#F2E2A8 → #C19A3E`
- cream heading `#F4ECD6`, primary text `#EDE6D0`, muted `#828BA3`/`#7F88A0`
- stars `#F2C84B`, check green `#6BCB77`, on-gold text `#1B1606`
- Force dark status-bar content (screen is dark on every theme).

## Layout (single scroll, top → bottom)
1. **Close ✕** top-right, subtle circle — `@Environment(\.dismiss)`.
2. **Eyebrow:** `TAFAKKUR PREMIUM` (gold, tracked, centered).
3. **Hero headline** (serif, centered): "Everything." / "Forever." (two lines).
4. **Price pill** (centered, gold outline): `{displayPrice}` + `ONE-TIME`.
5. **Lede** (centered, muted): "One payment. No renewals. Your daily companion, for life."
6. **Layers card** — header `📖 4 Layers of Tafsir` + "All 114 surahs · English, Urdu & Arabic", then numbered rows 1–4 sourced from `TafsirLayer.title` (concise paywall copy):
   1. Foundation — Historical context & basics
   2. Classical Sunni — Tabari, Ibn Kathir, Qurtubi
   3. Contemporary — Modern scholars & insights
   4. Comparative — Scholarly perspectives, side by side — **[EXCLUSIVE]** gold pill
7. **Feature cards** (stacked: icon tile + title + optional badge + subtitle):
   - `✨ Gems` — **[MOST LOVED]** — "Bite-size insights for every verse"
   - `🌙 Seasonal Journeys` — **[dynamic season badge]** — "Ramadan · Hajj · Fasting verses"
   - `🧠 Surah Quizzes` — "Test your understanding, earn badges"
   - `🔊 Listen Mode` — "Commentary read aloud, word by word"
8. **Rating block** (centered): `★★★★★` — five static gold stars. **Stars only** — no number, caption, review quote, or count.
9. **Trust row:** `✓ Family Sharing · ✓ Works offline · ✓ No ads, ever`.
10. **CTA:** full-width gold-gradient `★  Unlock Premium` → `purchaseManager.purchase()`. Show progress while purchasing; on success keep existing alert + auto-dismiss.
11. **Footer:** "One-time · yours for life · **Restore**" (Restore → `purchaseManager.restore()`).

## Dynamic Seasonal badge (uses existing `IslamicCalendarManager`)
- `isRamadanSeason()` → badge `RAMADAN` (append `· DAY n` when `currentRamadanDay()` non-nil); subtitle leads with Ramadan.
- else `isHajjSeason()` → badge `HAJJ` (append `· DAY n` when `currentHajjDay()` non-nil); subtitle leads with Hajj.
- else (off-season) → no date badge (plain "Seasonal" or none); subtitle "Ramadan · Hajj · Fasting verses".
- Seasons are already mutually exclusive in the manager.

## Rating note
App Store does not expose an app's own rating to the binary, so the five stars are a **static visual** asserting the 5-star rating we have (per request) — no StoreKit/review API.

## Files
- **Rewrite** `AlBayan/Views/PaywallView.swift`: replace the `PaywallView` body and its now-superseded private sub-components (`PaywallLayersHero`, `PaywallLayerCard`, `PaywallProgressTeaser`, `ProgressTeaserItem`, `PaywallQuickGemsFeature`, `PremiumBenefitRow`) with the new structure + a local color palette + the dynamic-season helper. Preserve StoreKit wiring (purchaseManager/premiumManager, alert, dismiss-on-success).
- No other files change.
- Verify with a compile build.

## Out of app (user action — flagged, not code)
- **Family Sharing** trust claim requires marking IAP `com.albayan.premium.tafsir` **Family Shareable** in App Store Connect for it to be true.

## Out of scope
No subscriptions/trial, no analytics, no UI localization, `WelcomeView` untouched.
