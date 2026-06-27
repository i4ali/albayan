# Daily Challenge & Daily Crossword — Sunni content design

**Date:** 2026-06-24
**Status:** Approved (content layer). Engine/UI ports tracked separately in `daily-features-sunni/`.
**Scope of this doc:** the **content** to author for the two ported daily-habit features — *not* the engine (copy-verbatim) or UI (rebuild-in-theme) layers. Those are fully specified in the handoff package at `daily-features-sunni/README.md`, `01-daily-challenge.md`, `02-daily-crossword.md`.

---

## 1. Context

We are porting two "daily habit" features from the Shia app (Thaqalayn) into AlBayan/Tafakkur:

- **Daily Challenge** — one bite-size question per day in one of 4 formats (multiple-choice, true/false, flashcard, fill-in-the-blank). Tap the Today card → answer in a sheet → see the explanation → streak updates.
- **Daily Crossword** — one small criss-cross mini-crossword per day (~6 interlocking words, 5–7 cell grid). Tap the Today card → solve on a grid → solved overlay → streak updates.

Both are premium-gated cards on the Today tab, **local-only** (no account/sync), and **streak-only** (no points/badges).

The handoff package splits everything into three layers; **only the content layer requires authoring decisions** (the subject of this doc):

| Layer | Action | Covered here? |
|---|---|---|
| Engine (models, managers, providers, Python crossword pipeline) | Copy verbatim | No — see handoff |
| UI (play screens, cards, onboarding) | Rebuild in AlBayan theme | No — see handoff |
| **Content** (challenge pool + crossword word bank) | **Author fresh Sunni content** | **Yes** |

**Multilingual:** AlBayan is trilingual — `CommentaryLanguage` = `en / ur / ar` (+ `fr`→`en`), `AlBayan/Models/QuranModels.swift:587`. Every authored string exists in all three languages. `LocalizedText` (handoff §4.1) maps cleanly onto this enum as-is.

---

## 2. Decisions (from brainstorming)

1. **Thematic lean:** content leans into **reflect/grow** themes (aligns with the Tafakkur "Read. Reflect. Grow." identity and the motivational/mental-health crossover audience) — not a generic knowledge quiz.
2. **Lean depth:** **themed + concretely anchored.** Every item is *about* a reflect/grow quality but always pinned to a concrete, checkable hook (a prophet, an āyah, a du'ā, a hadith) so questions/answers stay crisp. This resolves the tension between abstract virtues and formats that need definite answers.
3. **Primary anchoring device:** **prophets-as-exemplars** — each quality has a Qur'anic embodiment; 100% mainstream-Sunni and uncontroversial.
4. **Crossword shared-figures line:** **keep & reclue** the central figures venerated in both traditions — `ALI`, `HASAN`, `ZAHRA` (Fāṭima), `ABBAS`, `TALIB`, `JAFAR` (the Companion) — with fresh Sunni clues (no "Imam", no "(a)"). **Remove** the Twelve-Imams enumeration (`SADIQ`, `BAQIR`, `KAZIM`, `JAWAD`, `MAHDI`) plus `SHIA` and `KHUMS`. `IMAM` is **kept but reclued** to the generic Sunni sense ("one who leads the congregational prayer").

---

## 3. The theme spine (shared by both features)

Both features draw from one backbone of **14 reflect/grow themes**. Each theme: a concrete anchor for challenge items, and (where the term is 3–6 letters) a crossword answer. The crossword clue carries the reflective voice.

| # | Theme | Concrete anchor / hook | Crossword term |
|---|---|---|---|
| 1 | **Sabr** — patience, perseverance | Ayyūb (21:83); "Allah is with the patient" (2:153); 94:5–6 | `SABR` |
| 2 | **Shukr** — gratitude | "If you are grateful, I will increase you" (14:7); Sulaymān (27:40) | `SHUKR` |
| 3 | **Tawakkul** — reliance on God | "Whoever relies on Allah, He is enough for him" (65:3); "tie your camel, then trust" (Tirmidhī) | *(challenges)* |
| 4 | **Tawba / Istighfār** — repentance, return | Yūnus' du'ā (21:87); "do not despair of Allah's mercy" (39:53); Sayyid al-Istighfār (Bukhārī) | `TAWBA` |
| 5 | **Raḥma** — mercy, compassion | Bismillāh; "a mercy to the worlds" (21:107); "the merciful are shown mercy" (Tirmidhī) | `RAHMA` |
| 6 | **Riḍā / Qanāʿa** — contentment | "Richness is the contentment of the heart" (Bukhārī) | `RIDA` |
| 7 | **Rajāʾ** — hope in God | "Who despairs of his Lord's mercy but the astray?" (15:56) | `RAJA` |
| 8 | **Īmān / Yaqīn** — faith, certainty | Ḥadīth of Jibrīl (Muslim); "faith has 70-odd branches" (Muslim) | `IMAN`, `YAQIN` |
| 9 | **Ikhlāṣ / Niyya** — sincerity, intention | "Actions are but by intentions" (Bukhārī #1); Sūrat al-Ikhlāṣ | `NIYYA`, `IKHLAS` |
| 10 | **Dhikr** — remembrance, inner calm | "In the remembrance of Allah hearts find rest" (13:28) | `DHIKR` |
| 11 | **Ḥusn al-khuluq** — good character | "I was sent to perfect good character" (Aḥmad); "you are upon a great character" (68:4) | `KHULUQ` |
| 12 | **Ḥilm / ʿAfw** — forbearance, forgiving others | Yūsuf forgives his brothers (12:92); 7:199; 24:22 | `AFW`, `HILM` |
| 13 | **Tawāḍuʿ** — humility | "The servants of the Most Merciful walk humbly" (25:63) | *(challenges)* |
| 14 | **Tafakkur** — reflection (the app's namesake) | "In the creation of the heavens and earth… signs for those who reflect" (3:190–191) | *(challenges)* |

---

## 4. Daily Challenge content spec (`daily_challenges.json`)

**Volume:** ~72 items, **~5 per theme**, each theme spanning ≥3 of the 4 formats.

**Format distribution** (tunable; land near these totals):

| Format | ~Count | Job for the reflect/grow lean |
|---|---|---|
| `multipleChoice` | ~24 | prophet-as-exemplar / "which āyah/concept" — crispest, concrete |
| `fillInBlank` | ~16 | āyah completion — showcases the Arabic, anchors the theme in revelation |
| `flashcard` | ~16 | du'ās + self-reflection reveals — the most "reflective" format |
| `trueFalse` | ~16 | gentle myth-busting from hadith — engaging, corrects misconceptions |

**Field rules** (per handoff `01-daily-challenge.md`):

| Format | `prompt` | `options` | `correctIndex` | `answer` | `arabicText` |
|---|---|---|---|---|---|
| `multipleChoice` | question | 3–4 choices | index of correct | nil | optional |
| `trueFalse` | statement | nil | **1 = true, 0 = false** | nil | optional |
| `flashcard` | front (question) | nil | nil | back (revealed) | optional |
| `fillInBlank` | sentence with `____` | 3 choices | index of correct | nil | usually the full āyah |

- `explanation` shown after answering for **every** format; written in the warm reflect/grow voice.
- `arabicText` = verbatim āyah/du'ā, **never a translation**.
- `topic` is a free curation tag; use the 14 theme slugs.
- `id` = stable `dc_001`…

**Voice:** warm, growth-oriented, second-person where natural; tie the fact back to the reader's inner life. Not academic ("grammatical analysis"), not dry trivia. (Consistent with the established tafsir-video voice guidance.)

### Sample items (authoring templates — English; ur/ar added by translation step)

```jsonc
// MC · Sabr
{
  "id": "dc_001", "format": "multipleChoice", "topic": "sabr",
  "prompt": { "en": "The Qur'an holds up one prophet as the very emblem of patience through loss and illness. Who?" },
  "options": [ {"en":"Ayyūb (Job)"}, {"en":"Yūnus"}, {"en":"Idrīs"}, {"en":"Dhul-Kifl"} ],
  "correctIndex": 0,
  "explanation": { "en": "Ayyūb ﷺ lost health, wealth, and family, yet his prayer was never a complaint — only 'harm has touched me, and You are the Most Merciful' (21:83). Sabr isn't gritting your teeth; it's keeping a soft heart turned toward Allah while you wait." },
  "arabicText": null, "source": "Qur'an 21:83"
}

// Fill-in-blank · Rajāʾ / hope
{
  "id": "dc_002", "format": "fillInBlank", "topic": "raja",
  "prompt": { "en": "\"Indeed, with hardship comes ____.\"  (ash-Sharḥ)" },
  "options": [ {"en":"ease (yusrā)"}, {"en":"patience (ṣabr)"}, {"en":"reward (ajr)"} ],
  "correctIndex": 0,
  "explanation": { "en": "94:6 — and the verse says it twice. The hardship is named once; the ease, twice. Whatever is pressing on you tonight already has its ease written beside it." },
  "arabicText": "إِنَّ مَعَ ٱلْعُسْرِ يُسْرًا", "source": "Qur'an 94:6"
}

// Flashcard · Dhikr / anxiety
{
  "id": "dc_003", "format": "flashcard", "topic": "dhikr",
  "prompt": { "en": "When worry and grief crowd in, the Prophet ﷺ taught a specific du'ā. Can you recall it?" },
  "options": null, "correctIndex": null,
  "answer": { "en": "'Allāhumma innī aʿūdhu bika minal-hammi wal-ḥazan' — O Allah, I seek refuge in You from anxiety and grief." },
  "explanation": { "en": "From a longer du'ā in al-Bukhārī. Naming the feeling to Allah is itself the first relief." },
  "arabicText": "اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْهَمِّ وَالْحَزَنِ", "source": "Sahih al-Bukhari"
}

// True/False · Ḥusn al-khuluq
{
  "id": "dc_004", "format": "trueFalse", "topic": "khuluq",
  "prompt": { "en": "The Prophet ﷺ said the strong person is the one who overpowers others in wrestling." },
  "options": null, "correctIndex": 0, "answer": null,
  "explanation": { "en": "'The strong is not the one who throws others down; the strong is the one who controls himself when angry' (Bukhārī & Muslim). Real strength is inward." },
  "arabicText": null, "source": "Bukhari & Muslim"
}
```

---

## 5. Daily Crossword bank spec (`bank.json` → generated `daily_crosswords.json`)

**Approach:** virtue terms are the **answers**; the **reflective voice lives in the clues**. Keep a high density of 3–4 letter connectors so the generator can build 365 distinct puzzles.

**Target:** ~110 terms, all A–Z uppercase, 3–6 letters, trilingual clues (`clue_en` / `clue_ur` / `clue_ar`).

### Composition

**KEEP (already sect-neutral — retain term + clue, light edits only):**
- *Practice:* `DUA FAJR ZUHR ASR ISHA SALAH WUDU RAKA SUJUD ADHAN QIBLA ZAKAT SAWM HAJJ UMRAH TAWAF IHRAM DHIKR NIYYA EID HALAL HARAM TAQWA`
- *Qur'an / letters / surahs:* `SURA AYAH QAF SAD NUN NOOR TUR KAHF TAHA YASIN QURAN JUDI`
- *Prophets:* `ADAM NUH HUD MUSA ISA NABI`
- *Names of God:* `RABB RAHIM KARIM WAHID BASIR SAMAD SABUR RAQIB HAQ`
- *Concepts:* `NUR RUH ILM DIN DEEN AMAL ISLAM SABR IMAN UMMAH SUNNAH MUMIN IBLIS ADN`
- *Places:* `MECCA MINA SAFA AQSA KAABA BADR UHUD TABUK SHAAM`
- *People (neutral):* `BILAL ZAYD AMINA`

**ADD — virtue terms (the spine):** `SHUKR TAWBA RAHMA RIDA RAJA YAQIN IKHLAS KHULUQ AFW HILM SIDQ` (optional: `ADL` justice, `HUDA` guidance, `SAKINA` tranquillity, `SHIFA` healing, `RIZQ` provision)

**ADD — prophet-exemplars:** `AYYUB YUNUS YUSUF SALIH IDRIS LUT HARUN DAWUD YAHYA ILYAS ISHAQ YAQUB ISMAIL SHUAYB`

**ADD — Companions / Rightly-Guided Caliphs / Mothers of the Believers:** `ABU` (Abū Bakr), `UMAR UTHMAN AISHA HAFSA HAMZA KHALID SAAD TALHA SALMAN ANAS MUADH`

**RECLUE (keep term, Sunni framing — drop "Imam"/"(a)"):**
```
ALI   → "Fourth Rightly-Guided Caliph; cousin & son-in-law of the Prophet ﷺ"
HASAN → "Grandson of the Prophet ﷺ who set aside power to unite the ummah"
ZAHRA → "Al-___, title of Fāṭima, the Prophet's ﷺ beloved daughter"
ABBAS → "Al-___ ibn ʿAbd al-Muṭṭalib, the Prophet's ﷺ uncle"
TALIB → "Abū ___, the uncle who protected the Prophet ﷺ"
JAFAR → "___ aṭ-Ṭayyār, Companion who led the emigration to Abyssinia"
KUFA  → "Early garrison city in Iraq"
BAYT  → "House — as in Bayt Allah, the Kaʿba"
IMAM  → "One who leads the congregational prayer"
```

**REMOVE entirely:** `SHIA` `KHUMS` `MAHDI` `SADIQ` `BAQIR` `KAZIM` `JAWAD` `QUM`

**Sample reclued/virtue clues (reflective voice):**
```
SABR  → "The quality Allah pairs with His own help: 'Allah is with the ___'"
SHUKR → "Thankfulness that, the Qur'an promises, makes blessings grow (14:7)"
TAWBA → "The turn back to Allah that He loves; the door for it never shuts"
RIDA  → "Contentment of heart — the 'richness' the Prophet ﷺ praised"
AYYUB → "The prophet whose name became a byword for patience"
```

---

## 6. Production pipeline (trilingual)

Mirrors how AlBayan's existing tafsir/quiz content is produced:

1. **Author English** content theme-by-theme — challenge clusters + bank terms/clues.
2. **Translate** `ur` / `ar` via the `urdu-translator` and `arabic-translator` subagents.
3. **Quality-check** Arabic via `arabic-quality-checker`; eyeball Urdu.
4. **Crossword build:** trilingual `bank.json` → `python3 scripts/crossword/generate.py` (emits `Data/daily_crosswords.json`, 365 puzzles, fixed seed) → `python3 scripts/crossword/validate.py`.
   - The two scripts hardcode the source app's path — change `"Thaqalayn"` → AlBayan's source-dir name in **both** before running (handoff `02-daily-crossword.md`).

---

## 7. Validation & review gates

- **Crossword:** `validate.py` must print **"ALL N PUZZLES VALID"** — it enforces crossing-letter consistency, `[A-Z]{3,6}` answers, and that every clue has `en`/`ur`/`ar`.
- **Challenge:** lightweight JSON sanity check — unique `id`s; `correctIndex` valid per format (in-range for MC/fill, 1/0 for true-false, nil for flashcard); all three languages present on every string.
- **Doctrinal review (hard pre-release gate):** a qualified Sunni scholar reviews the full challenge pool + crossword clues before release (handoff §7). Virtue content is low-risk, but sourcing/attribution gets a human pass.

---

## 8. Scope summary & non-goals

**In scope (this design):** `daily_challenges.json` (~72 items) and `bank.json` (~110 terms) → generated `daily_crosswords.json`, all trilingual, plus the chrome strings review.

**Non-goals:**
- No cloud sync / accounts (local-only by design — handoff §4.7).
- No points or badges (streak-only — handoff §4.8).
- Engine is copy-verbatim; UI is rebuilt from the handoff UX specs — neither is re-specified here.
- Reading text-size scaling applies to Daily Challenge reading content only, never the crossword grid (handoff §6) — a UI concern with no content impact.

**Open items for the implementation plan:**
- Final per-theme × format allocation worksheet for the 72 challenge items.
- Final bank term list pinned to exactly ~110 with verified connector density.
- English-only fallback is **not** needed (AlBayan is trilingual) — author all three languages.
