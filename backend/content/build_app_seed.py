#!/usr/bin/env python3
"""Regenerate the app's bundled offline words (en-de, general words only)
from backend/content/de.json:

    python3 backend/content/build_app_seed.py

Writes app/assets/words_seed.json (same shape as GET /content/words).
"""

import json
from pathlib import Path

HERE = Path(__file__).resolve().parent
OUT = HERE.parent.parent / "app" / "assets" / "words_seed.json"

words = json.loads((HERE / "de.json").read_text(encoding="utf-8"))["words"]
seed = {"version": 3, "source": "en", "target": "de", "words": [
    {
        "external_id": w["external_id"], "lang": "de", "term": w["term"], "article": w["article"],
        "translation": w["translations"]["en"]["translation"], "example": w["example"],
        "example_translation": w["translations"]["en"].get("example_translation"),
        "pronunciation": w["pronunciation"], "category": w["category"], "difficulty": w["difficulty"],
        "level": w["level"], "topics": [],
    }
    for w in words
]}
OUT.write_text(json.dumps(seed, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print(f"{OUT}: {len(seed['words'])} words")
