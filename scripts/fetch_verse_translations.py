#!/usr/bin/env python3
"""Fetch Urdu (Jalandhry) + Arabic (al-Muyassar) verse translations from the
Al-Quran Cloud API and merge them into quran_data.json as `translationUrdu`
and `translationArabic` on each verse object (camelCase, matching the file).

- Urdu : ur.jalandhry  (Fateh Muhammad Jalandhry — traditional Sunni)
- Arabic: ar.muyassar   (Tafsir al-Muyassar, King Fahd Complex — plain Sunni Arabic)

Re-runnable and idempotent. Validates per-surah ayah counts before writing, and
preserves the file's 2-space, raw-UTF8 pretty-print so the diff only adds fields.

Run from the repo root:  python3 scripts/fetch_verse_translations.py
"""
import json
import urllib.request

API = "https://api.alquran.cloud/v1/quran/"
EDITIONS = [("translationUrdu", "ur.jalandhry"), ("translationArabic", "ar.muyassar")]
QURAN_DATA = "AlBayan/AlBayan/Data/quran_data.json"  # the bundled copy (loaded via Bundle.main)

# al-Muyassar prepends an al-Fatiha surah-introduction to verse 1:1; the basmala
# gloss itself begins at this marker, so we trim everything before it for 1:1.
FATIHA_BASMALA_MARKER = "أبتدئ قراءة القرآن"
INTRO_PHRASE = "سميت هذه السورة"  # generic surah-intro marker — warn if seen elsewhere


def fetch(edition):
    url = API + edition
    print(f"Fetching {url} ...")
    with urllib.request.urlopen(url, timeout=180) as resp:
        payload = json.load(resp)
    assert payload.get("status") == "OK", f"API status {payload.get('status')} for {edition}"
    out = {}  # surah-number(int) -> { ayah-in-surah(int): text }
    for surah in payload["data"]["surahs"]:
        out[surah["number"]] = {a["numberInSurah"]: a["text"] for a in surah["ayahs"]}
    total = sum(len(x) for x in out.values())
    print(f"  {edition}: {len(out)} surahs, {total} ayahs")
    return out


def main():
    data = json.load(open(QURAN_DATA, encoding="utf-8"))
    verses = data["verses"]  # {"1": {"1": {...}, ...}, ...}
    sources = {field: fetch(edition) for field, edition in EDITIONS}

    # Validate per-surah ayah counts before mutating anything.
    for s_str, ayahs in verses.items():
        s = int(s_str)
        for field, src in sources.items():
            assert s in src, f"surah {s} missing in {field} source"
            assert len(src[s]) == len(ayahs), (
                f"ayah-count mismatch surah {s}: quran_data={len(ayahs)} {field}={len(src[s])}"
            )

    urdu_src = sources["translationUrdu"]
    arabic_src = sources["translationArabic"]
    n = 0
    for s_str, ayahs in verses.items():
        s = int(s_str)
        for a_str, vobj in ayahs.items():
            a = int(a_str)
            urdu = urdu_src[s][a]
            arabic = arabic_src[s][a]
            if s == 1 and a == 1:
                i = arabic.find(FATIHA_BASMALA_MARKER)
                if i > 0:
                    arabic = arabic[i:].strip()
            elif INTRO_PHRASE in arabic:
                print(f"  ! WARN: surah-intro text detected in {s}:{a} — review trimming")
            vobj["translationUrdu"] = urdu
            vobj["translationArabic"] = arabic
            n += 1

    with open(QURAN_DATA, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write("\n")
    print(f"Merged Urdu + Arabic translations into {n} verses across {len(verses)} surahs.")


if __name__ == "__main__":
    main()
