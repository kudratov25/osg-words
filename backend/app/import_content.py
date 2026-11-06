"""Import content files into DATABASE_URL (upsert by external_id), with the
same rules and version bumps as POST /admin/import.

    python -m app.import_content                        # dry run, content/*.json
    python -m app.import_content --apply                # write
    python -m app.import_content --apply content/de.json
"""

import argparse
import json
from pathlib import Path

from sqlmodel import Session

from . import packs
from .database import engine, init_db


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("files", nargs="*", type=Path, help="default: backend/content/*.json")
    ap.add_argument("--apply", action="store_true", help="write changes (default: dry run)")
    args = ap.parse_args()

    init_db()
    files = args.files or packs.content_files()
    if not files:
        raise SystemExit("No content files found.")
    with Session(engine) as session:
        packs.ensure_pack_meta(session)
        for path in files:
            target, words = packs.load_content_file(path)
            res = packs.import_words(session, words, default_target=target or path.stem, dry_run=not args.apply)
            errors = res.pop("errors")
            print(f"{path.name}: {json.dumps(res)}  errors={len(errors)}")
            for err in errors[:50]:
                print(f"  #{err['index']} {err['external_id']}: {err['error']}")


if __name__ == "__main__":
    main()
