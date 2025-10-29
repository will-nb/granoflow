#!/usr/bin/env python3
"""
批量补齐 documents/architecture/* 下的 YAML 规范字段：
- 若缺失这些字段则添加空默认值：schema_version, last_synced_sha, source_of_truth,
  called_by, calls, test_mapping, i18n_keys, design_tokens, supersedes, deprecated_since

仅补齐缺失，不覆盖已有值；输出修改的文件清单。
"""
import sys
from pathlib import Path
import yaml

SCRIPT_DIR = Path(__file__).resolve().parent
ROOT = SCRIPT_DIR.parents[2]
ARCH_DIR = ROOT / 'documents' / 'architecture'

DEFAULTS = {
    'meta': {
        'schema_version': 1,
        'last_synced_sha': ''
    },
    'source_of_truth': '',
    'called_by': [],
    'calls': [],
    'test_mapping': {
        'unit': [],
        'widget': [],
        'integration': []
    },
    'i18n_keys': [],
    'design_tokens': [],
    'supersedes': [],
    'deprecated_since': ''
}

def load_yaml(p: Path):
    try:
        with p.open('r', encoding='utf-8') as f:
            return yaml.safe_load(f) or {}
    except Exception as e:
        return None

def dump_yaml(p: Path, data: dict):
    with p.open('w', encoding='utf-8') as f:
        yaml.safe_dump(data, f, allow_unicode=True, sort_keys=False)

def ensure_defaults(doc: dict) -> bool:
    changed = False
    # meta subfields
    meta = doc.get('meta') or {}
    if 'schema_version' not in meta:
        meta['schema_version'] = DEFAULTS['meta']['schema_version']
        changed = True
    if 'last_synced_sha' not in meta:
        meta['last_synced_sha'] = DEFAULTS['meta']['last_synced_sha']
        changed = True
    if meta != doc.get('meta'):
        doc['meta'] = meta

    # top-level fields
    for k in ['source_of_truth', 'called_by', 'calls', 'test_mapping', 'i18n_keys', 'design_tokens', 'supersedes', 'deprecated_since']:
        if k not in doc:
            doc[k] = DEFAULTS[k]
            changed = True
    return changed

def main():
    modified = []
    for p in ARCH_DIR.rglob('*.y*ml'):
        doc = load_yaml(p)
        if not isinstance(doc, dict) or 'meta' not in doc:
            # 跳过无法解析或非架构格式的 YAML
            continue
        if ensure_defaults(doc):
            dump_yaml(p, doc)
            modified.append(str(p.relative_to(ROOT)))

    if modified:
        print('[bulk-update] 修改文件:')
        for m in modified:
            print(' -', m)
    else:
        print('[bulk-update] 无需修改')

if __name__ == '__main__':
    sys.exit(main())
