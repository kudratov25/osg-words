"""Languages, pairs and categories (docs/SPEC-v2.md sections 1-2).

A pair is "source-target": the user speaks `source` and learns `target`.
"""

TARGETS: tuple[str, ...] = ("de", "en")  # words to learn
SOURCES: tuple[str, ...] = ("en", "uz", "ru")  # translations + app interface
LANGS: tuple[str, ...] = ("en", "de", "uz", "ru")

# The pair app v1.0.x knows (and bundles offline). It is what /content/*
# serves without parameters and is always served, whatever its word count.
DEFAULT_SOURCE = "en"
DEFAULT_TARGET = "de"

# Every source x target combination with source != target.
PAIRS: tuple[tuple[str, str], ...] = tuple(
    (s, t) for t in TARGETS for s in SOURCES if s != t
)

CATEGORIES: tuple[str, ...] = (
    "Daily Life", "Work", "Food", "Common Verbs", "Travel", "Emotions",
    "Adjectives", "Time", "Money", "Health", "Weather", "Social", "Home",
    "Family", "Education", "Shopping", "Nature",
)

# CEFR levels (v2.1). The user picks one; words of that level and above are
# planned. `difficulty` (beginner/intermediate/advanced, read by app <= 2.0)
# is derived from it.
LEVELS: tuple[str, ...] = ("A1", "A2", "B1", "B2", "C1")
LEVEL_DIFFICULTY: dict[str, str] = {
    "A1": "beginner", "A2": "beginner", "B1": "intermediate", "B2": "advanced", "C1": "advanced",
}

# Job areas (v2.1). A word with topics is a "topic word": served only to
# apps that ask for them (`/content/words?topics=true`) and planned only for
# users who picked one of its topics. Words without topics are general.
TOPICS: tuple[str, ...] = (
    "retail", "it", "medicine", "hospitality", "construction", "logistics", "office", "care",
)

ARTICLES: dict[str, tuple[str, ...]] = {"de": ("der", "die", "das")}


def pair_key(source: str, target: str) -> str:
    return f"{source}-{target}"


def is_pair(source: str, target: str) -> bool:
    return (source, target) in PAIRS
