"""Validate/render reviewed planning input; not the runtime certification registry."""
from __future__ import annotations
import argparse
import json
from pathlib import Path
import re
import sys
from contract_model import strict_json

ROOT = Path(__file__).resolve().parents[1]

def validate(data: dict, root: Path = ROOT) -> None:
    required = {'schema_version','status','release_order','chapter_one','always_gates',
                'release_gates','platform_gates','gates','capabilities','features','deferred_new_capabilities','notes'}
    if (set(data) != required or type(data['schema_version']) is not int or data['schema_version'] != 2
            or data['status'] != 'proposed-planning-not-release-certificate'):
        raise ValueError('unknown or missing release-scope fields/version')
    order = data['release_order']
    if order != ['proof','chapter_one','chapter_two','chapter_three','realm']:
        raise ValueError('unknown/reordered release tiers')
    if data['chapter_one'] != {'rooms':57,'quests':10,'endings':2,'source':'00a-chapter-one-content.md'}:
        raise ValueError('chapter-one product scope changed; requires owner review')
    source = (root / data['chapter_one']['source']).read_text().split('## 2. Rooms')[0]
    lock = re.findall(r'^    - ([a-z_]+@\d+)$', source, re.M)
    if not lock or len(set(lock)) != len(lock):
        raise ValueError('missing/duplicate chapter-one manifest lock')
    caps = data['capabilities']; names = [c['id'] for c in caps]
    if len(names) != len(set(names)) or set(names) != set(lock):
        raise ValueError('planning capabilities do not match chapter-one manifest')
    gates = data['gates']
    for c in caps:
        if set(c) != {'id','first_required','phase','gates'}:
            raise ValueError('invalid capability record')
        if c['first_required'] not in {'proof','chapter_one'}:
            raise ValueError('chapter-one capability deferred')
    seen = set()
    for f in data['features']:
        if set(f) != {'id','capability','first_required','phase','gates','reason'}:
            raise ValueError('invalid feature record')
        if f['id'] in seen or f['capability'] not in names:
            raise ValueError('duplicate feature or unknown capability')
        seen.add(f['id'])
    for item in caps + data['features']:
        if (item['first_required'] not in order or item['phase'] not in {'R5','R7','R8'}
                or not item['gates'] or len(set(item['gates'])) != len(item['gates'])
                or not set(item['gates']) <= set(gates)):
            raise ValueError('unknown phase/release/gate')
    if set(data['always_gates']) != {'STATIC','DETERMINISM','AUTHORITY','RULES'}:
        raise ValueError('always-required planning gates changed')
    if set(data['release_gates']) != {'DEVICE','HUMAN'}:
        raise ValueError('device/human evidence cannot disappear')
    expected_platform = {tier: ([] if tier == 'proof' else ['ACCOUNT'] if tier == 'realm' else ['ACCOUNT', 'RUN']) for tier in order}
    if data['platform_gates'] != expected_platform or not {'ACCOUNT', 'RUN'} <= set(gates):
        raise ValueError('public account/run gate missing or incorrectly blocks proof/Realm')
    if not set(data['always_gates'] + data['release_gates']) <= set(gates):
        raise ValueError('unknown mandatory gate')


def applicable(data: dict, release: str) -> tuple[list[dict], list[dict], list[str]]:
    order = data['release_order']; level = order.index(release)
    caps = [c for c in data['capabilities'] if order.index(c['first_required']) <= level]
    features = [f for f in data['features'] if order.index(f['first_required']) <= level]
    gates = set(data['always_gates'] + data['release_gates'] + data['platform_gates'][release])
    for item in caps + features:
        gates.update(item['gates'])
    return caps, features, sorted(gates)


def render(data: dict) -> str:
    lines = ['# Generated release scope', '',
             'Generated from `release-scope.json`; edit that reviewed planning input, then run',
             '`python3 docs/rewrite-v3/checks/release_scope.py --write`.', '',
             '**Full chapter one remains 57 rooms, 10 quests, two endings.** R6P is a separate early proof.',
             'This is planning applicability, not a release certificate or a frozen engine registry.', '']
    for release in ['proof','chapter_one']:
        caps,features,gates=applicable(data,release)
        lines += [f'## {release}', '', '| Capability | First slice | Phase | Gates |', '|---|---|---|---|']
        lines += [f"| `{c['id']}` | {c['first_required']} | {c['phase']} | {', '.join(c['gates'])} |" for c in caps]
        engine_gates = [g for g in gates if g not in data['platform_gates'][release]]
        lines += ['', '**Engine/device/human planning gates:** '+', '.join(engine_gates)+'.', '']
        if data['platform_gates'][release]:
            lines += ['**Additional public-app/platform gates (not pure cartridge certification):** '
                      + ', '.join(data['platform_gates'][release]) + '.', '']
    lines += ['## Feature-level applicability', '', '| Feature | Capability | First need | Phase | Evidence |', '|---|---|---|---|---|']
    lines += [f"| {f['id']} | `{f['capability']}` | {f['first_required']} | {f['phase']} | {f['reason']} Gates: {', '.join(f['gates'])}. |" for f in data['features']]
    lines += ['', '## Gate meanings', '']
    lines += [f'- **{key}:** {value}' for key,value in data['gates'].items()]
    lines += ['', '## Limits and later scope', ''] + data['notes']
    lines += ['', 'Later proposed new capability families: '+', '.join(data['deferred_new_capabilities'])+'.', '']
    return '\n'.join(lines)


def check_links(root: Path = ROOT) -> None:
    data=strict_json((root/'conformance/contract-links.json').read_text())
    index=(root/'INDEX.md').read_text(); scenarios=(root/'15-acceptance-scenarios.md').read_text()
    seen=set()
    for item in data['links']:
        if item['id'] in seen:
            raise ValueError('duplicate summary link')
        seen.add(item['id'])
        matches=[line.split('|')[2].strip() for line in index.splitlines() if line.startswith('| '+item['id']+' |')]
        if matches != [item['summary']]:
            raise ValueError('summary drift: '+item['id'])
        path=root/item['document']
        if root.resolve() not in path.resolve().parents or not path.is_file():
            raise ValueError('invalid contract path')
        if item['heading'] not in path.read_text().splitlines():
            raise ValueError('missing governing section: '+item['id'])
        if not re.search(r'^### '+re.escape(item['scenario'])+r' — ',scenarios,re.M):
            raise ValueError('missing acceptance scenario: '+item['scenario'])


def main() -> int:
    parser=argparse.ArgumentParser(description=__doc__)
    mode=parser.add_mutually_exclusive_group(required=True)
    mode.add_argument('--check',action='store_true'); mode.add_argument('--write',action='store_true')
    args=parser.parse_args()
    try:
        data=strict_json((ROOT/'release-scope.json').read_text())
        validate(data); check_links(); expected=render(data); target=ROOT/'release-scope.md'
        if args.write: target.write_text(expected)
        elif not target.exists() or target.read_text()!=expected:
            raise ValueError('generated release-scope.md is stale')
    except (ValueError,KeyError,TypeError,OSError) as exc:
        print('FAIL:',exc,file=sys.stderr); return 1
    print('PASS: scope, lock, generated checklist and selected summary links'); return 0

if __name__=='__main__':
    raise SystemExit(main())
