# AlBayan — Urdu + Arabic Verse Translations with a Unified Language Toggle

**Date:** 2026-06-08
**Status:** Approved (brainstorm) → implementing

## Goal

Add **Urdu** and **Arabic** translations for every Qur'an verse, and a single **global** language toggle (EN/UR/AR) so the translation shown below the Arabic scripture switches everywhere it appears — driven by one persisted singleton.

## Decisions

- **Urdu edition:** Fateh Muhammad Jalandhry (`ur.jalandhry`, Al-Quran Cloud) — classic, widely-printed traditional Sunni.
- **Arabic edition:** Tafsīr al-Muyassar (`ar.muyassar`, Al-Quran Cloud) — concise plain-Arabic meaning, shown as the translation line (the Arabic *scripture* always stays on top).
- **One unified language:** reuse `CommentaryLanguageManager.shared` (EN/UR/AR, persisted under `commentaryLanguage`). It now governs verse translation **and** commentary **and** Gems **and** summary. No rename (avoid churn).
- **Storage:** bake translations into `quran_data.json` (offline, least code). Optional fields → English fallback.

## Components

1. **Data pipeline** — `scripts/fetch_verse_translations.py`: fetch both editions (one request each), merge `translation_urdu` / `translation_ar` into each `verses["{surah}"]["{ayah}"]` in `quran_data.json`. Assert per-surah ayah counts match before writing. Re-runnable.
2. **Model** (`QuranModels.swift`): `Verse` + `VerseWithTafsir` gain `translation_urdu: String?`, `translation_ar: String?` and `func translation(for: CommentaryLanguage) -> String` (UR→urdu ?? en, AR→ar ?? en, else en).
3. **Singleton unification:** fix `QuickOverviewView` + `VerseSummaryView` to bind to `CommentaryLanguageManager.shared` instead of their local `@State selectedLanguage`.
4. **UI:**
   - Verse list: language toggle chip in `ModernSurahHeader` next to "Aa" (reuse the `languageToggle` idiom; cycles EN→UR→AR via the singleton).
   - Translation sweep: every Qur'an-verse translation line → `verse.translation(for: lang)`, observe the singleton, RTL-align for UR/AR. Screens: `ModernVerseCard`, `StoryVerseCard`, `Hajj/RamadanVerseCard`, `FastingVerseCard`, `AhlulbaytVerseCard`, `ParallelVerseCard`, `VerseAnswerCard`, `VerseSummary` fallback. **Du'ās excluded** (not Qur'an verses).
   - Composes with the text-size feature: font keeps `× readingSettings.scale`; language only changes text + alignment.

## Data flow

`toggle → CommentaryLanguageManager.selectedLanguage (persisted) → observed by every verse card → renders verse.translation(for: lang) with RTL for UR/AR`.

## Error handling

Optional model fields → automatic English fallback if a translation is missing; the script validates per-surah counts before writing; no runtime networking.

## Verification (no XCTest, per project convention)

Build-gate + manual matrix: toggle EN/UR/AR on the verse list switches the line + RTL; set UR then open commentary/Gems → also Urdu (unified) and survives relaunch; spot-check a journey/story screen follows the language.
