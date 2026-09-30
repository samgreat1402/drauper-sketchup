from pathlib import Path
import base64, json
root = Path(__file__).resolve().parents[1]
manifest_path = root / '.asset-source' / 'manifest.json'
if not manifest_path.exists():
    raise SystemExit(0)
for item in json.loads(manifest_path.read_text()):
    target = root / item['path']
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_bytes(base64.b64decode((manifest_path.parent / item['source']).read_text()))
print('Materialized binary assets.')
