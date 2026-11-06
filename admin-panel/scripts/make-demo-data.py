#!/usr/bin/env python3
"""Export the data the dashboard shows into static JSON for the demo build.

    python3 scripts/make-demo-data.py http://127.0.0.1:8000 <ADMIN_API_KEY>

Run it against a backend with demo data (never your production server:
the demo is public). Writes demo-public/demo-data/*.json; then
`npm run build:demo` -> dist-demo/.
"""
import json
import sys
import urllib.request
from pathlib import Path

base, key = sys.argv[1].rstrip('/'), sys.argv[2]
out = Path(__file__).resolve().parent.parent / 'demo-public' / 'demo-data'
out.mkdir(parents=True, exist_ok=True)


def get(path):
    req = urllib.request.Request(base + path, headers={'X-Admin-Key': key})
    with urllib.request.urlopen(req, timeout=60) as r:
        return json.loads(r.read())


def all_devices():
    items, offset = [], 0
    while True:
        page = get(f'/admin/devices?limit=200&offset={offset}')
        items += page['items']
        offset += 200
        if offset >= page['total']:
            return items


files = {
    'stats': get('/admin/stats'),
    'coverage': get('/admin/coverage'),
    'words': get('/admin/words'),
    'devices': all_devices(),
    'word-issues': get('/admin/word-issues?limit=200'),
}
for name, data in files.items():
    (out / f'{name}.json').write_text(json.dumps(data, ensure_ascii=False, separators=(',', ':')), encoding='utf-8')
    print(name, len(data) if isinstance(data, list) else 'ok')
