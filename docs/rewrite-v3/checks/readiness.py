"""Validate R1 preparation records, never runtime acceptance or reviewer identity.

Uses retained files, not network services. A structurally complete manifest can
still lie; independent human/evidence review is required outside this checker.
"""
from __future__ import annotations
import argparse
import hashlib
import re
import sys
from pathlib import Path

from contract_model import canonical, strict_json

ROOT = Path(__file__).resolve().parents[1]
INPUTS = (
    'r1-acceptance-envelope.md', 'conformance/numeric-profile.md',
    'conformance/numeric-vectors.json', 'conformance/cases.json',
    'conformance/composition-profile.json', 'conformance/composition-cases.json',
    'conformance/lantern-traces.json',
)
TOOLS = ('expo', 'react_native', 'hermes', 'typescript', 'node', 'elixir', 'otp',
         'sqlite', 'sqlite_binding', 'xcode', 'ios_sdk', 'android_sdk', 'gradle', 'jdk')
DEVICE_FIELDS = ('qualification_class', 'model', 'sku', 'soc', 'installed_ram_gb',
                 'os_version', 'os_build', 'architecture', 'availability_record')
NORMATIVE = ('01-core-principles.md', '02-beam-runtime-architecture.md',
             '03-domain-state-persistence.md', '04-command-event-effect-protocol.md',
             '05-cartridges-content-capabilities.md', '06-quests-dialogue-actions-scripting.md',
             '07-offline-storypacks-to-mmo.md', '08-builder-api-ai-factory.md',
             '09-cartridge-lab-certification.md', '10-mobile-commerce-release.md',
             '11-security-observability-operations.md', '14-implementation-plan.md',
             '15-acceptance-scenarios.md', '16-decision-register.md',
             '19-quest-sharing-instancing-capacity.md', '21-composable-world-primitives.md',
             '23-accounts-progress-admission.md')


def template() -> dict:
    return {'schema_version': 1, 'status': 'preparation_pending', 'candidate': 'A',
            'accepted_spec_commit': None, 'candidate_author_ids': [],
            'devices': {k: {f: None for f in DEVICE_FIELDS} for k in ('ios', 'android')},
            'server': {'model': None, 'os_build': None, 'cores': None, 'ram_gb': None},
            'toolchain': {k: None for k in TOOLS},
            'toolchain_lock': {'path': None, 'sha256': None},
            'inputs': [{'path': p, 'sha256': None} for p in INPUTS],
            'r0_acceptance': {'path': None, 'sha256': None},
            'oracle_review': {'path': None, 'sha256': None},
            'setup_review': {'path': None, 'sha256': None}}


def check_template(data: dict) -> None:
    # Python structural equality conflates JSON booleans and integers (True == 1).
    if canonical(data) != canonical(template()):
        raise ValueError('template drift or fabricated preparation entries')


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def setup_digest(manifest: dict) -> str:
    # External review hashes are excluded to avoid a self-referential hash cycle.
    value = {k: v for k, v in manifest.items() if k not in {'status', 'setup_review'}}
    return sha256(canonical(value))


def nonempty(value) -> bool:
    return (type(value) is str and bool(value.strip())
            and value.strip().lower() not in {'todo', 'tbd', 'unknown', 'none', 'null', 'placeholder'})


def digest(value, size=64) -> bool:
    return type(value) is str and bool(re.fullmatch(r'[0-9a-f]{' + str(size) + '}', value)) and value != "0" * size


def retained(entry: dict, root: Path) -> bytes:
    if type(entry) is not dict or set(entry) != {'path', 'sha256'} or not nonempty(entry['path']) or not digest(entry['sha256']):
        raise ValueError('missing retained path/hash')
    relative = Path(entry['path'])
    if relative.is_absolute() or '..' in relative.parts:
        raise ValueError('unsafe evidence path')
    path = (root / relative).resolve()
    if not path.is_relative_to(root.resolve()) or not path.is_file():
        raise ValueError('missing/escaping evidence file: ' + entry['path'])
    if path.stat().st_size > 8 * 1024 * 1024:
        raise ValueError('evidence file exceeds preparation bound')
    raw = path.read_bytes()
    if sha256(raw) != entry['sha256']:
        raise ValueError('retained hash mismatch: ' + entry['path'])
    return raw


def require_ready(data: dict, root: Path) -> None:
    if type(data) is not dict or set(data) != set(template()):
        raise ValueError('unknown/missing manifest fields')
    if type(data['schema_version']) is not int or data['schema_version'] != 1:
        raise ValueError('unknown manifest version')
    if data['status'] != 'setup_reviewed' or data['candidate'] != 'A':
        raise ValueError('preparation pending or unsupported candidate work package')
    if not digest(data['accepted_spec_commit'], 40):
        raise ValueError('missing accepted specification commit')
    authors = data['candidate_author_ids']
    if type(authors) is not list or not authors or any(not nonempty(a) for a in authors) or len(set(authors)) != len(authors):
        raise ValueError('candidate authors must be identified for review separation')
    if type(data['devices']) is not dict or set(data['devices']) != {'ios', 'android'}:
        raise ValueError('both physical qualification records required')
    for platform, device in data['devices'].items():
        if type(device) is not dict or set(device) != set(DEVICE_FIELDS):
            raise ValueError('incomplete device inventory')
        for field in DEVICE_FIELDS:
            if field != 'installed_ram_gb' and not nonempty(device[field]):
                raise ValueError('missing device detail: ' + platform + '/' + field)
        floor = 3 if platform == 'ios' else 4
        if type(device['installed_ram_gb']) is not int or device['installed_ram_gb'] != floor:
            raise ValueError('qualification RAM class changed without amendment')
        expected = 'iphone-se-2' if platform == 'ios' else 'galaxy-a14-4gb'
        if device['qualification_class'] != expected or device['architecture'] != 'arm64':
            raise ValueError('qualification class/architecture changed without amendment')
        if not re.fullmatch(r'\d+(?:\.\d+)*', device['os_version']):
            raise ValueError('device OS must be exact numeric version')
        ver = tuple(int(n) for n in device['os_version'].split('.'))
        padded = ver + (0,) * max(0, 3 - len(ver))
        if padded < ((16, 4, 0) if platform == 'ios' else (10, 0, 0)):
            raise ValueError('device OS below planning policy')
    server = data['server']
    if type(server) is not dict or set(server) != {'model', 'os_build', 'cores', 'ram_gb'}:
        raise ValueError('incomplete server record')
    if any(not nonempty(server[k]) for k in ('model', 'os_build')) or any(type(server[k]) is not int or server[k] < 1 for k in ('cores', 'ram_gb')) or server['ram_gb'] < 16:
        raise ValueError('missing server details or RAM floor')
    tools = data['toolchain']
    if type(tools) is not dict or set(tools) != set(TOOLS):
        raise ValueError('incomplete toolchain')
    for name, value in tools.items():
        if not (type(value) is str and (re.fullmatch(r'\d+(?:\.\d+){0,3}(?:\+[a-zA-Z0-9.-]+)?', value) or digest(value, 40))):
            raise ValueError('toolchain must use exact stable version/build: ' + name)
    lock = retained(data['toolchain_lock'], root)
    if not lock.strip():
        raise ValueError('empty toolchain/lock manifest')
    inputs = data['inputs']
    if (type(inputs) is not list or len(inputs) != len(INPUTS)
            or any(type(row) is not dict for row in inputs)
            or [row.get('path') for row in inputs] != list(INPUTS)):
        raise ValueError('fixture/envelope set changed')
    for entry in inputs:
        retained(entry, root)
    r0 = strict_json(retained(data['r0_acceptance'], root).decode())
    if (type(r0) is not dict or r0.get('accepted_spec_commit') != data['accepted_spec_commit']
            or r0.get('disposition') != 'accepted' or not nonempty(r0.get('reviewer_id'))
            or type(r0.get('normative_files')) is not list
            or any(not nonempty(path) for path in r0['normative_files'])
            or len(r0['normative_files']) != len(set(r0['normative_files']))
            or not set(NORMATIVE) <= set(r0['normative_files']) or not nonempty(r0.get('amendment_authority'))
            or not nonempty(r0.get('cutover_destination'))):
        raise ValueError('missing R0 acceptance/cutover record')
    for name in ('oracle_review', 'setup_review'):
        review = strict_json(retained(data[name], root).decode())
        if (type(review) is not dict or review.get('accepted_spec_commit') != data['accepted_spec_commit']
                or review.get('disposition') != 'approved' or not nonempty(review.get('reviewer_id'))
                or review['reviewer_id'] in authors or review.get('independent_of_candidate_authorship') is not True):
            raise ValueError('missing independent ' + name)
        subject_authors = review.get('subject_author_ids')
        if (type(subject_authors) is not list or not subject_authors
                or any(not nonempty(author) for author in subject_authors)
                or len(set(subject_authors)) != len(subject_authors)
                or review['reviewer_id'] in subject_authors
                or review.get('independent_of_subject_authorship') is not True):
            raise ValueError('missing subject-author separation: ' + name)
        if name == 'oracle_review' and canonical(review.get('inputs')) != canonical(inputs):
            raise ValueError('oracle review does not bind exact inputs')
        if name == 'setup_review' and review.get('setup_digest') != setup_digest(data):
            raise ValueError('setup review does not bind exact configuration')


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument('--check-template', action='store_true')
    mode.add_argument('--require-ready', type=Path)
    parser.add_argument('--evidence-root', type=Path, default=ROOT)
    args = parser.parse_args()
    try:
        if args.check_template:
            data = strict_json((ROOT / 'conformance/r1-run-manifest.template.json').read_text())
            check_template(data)
            print('PASS: incomplete template preserved; NOT ready for candidate implementation')
        else:
            data = strict_json(args.require_ready.read_text())
            require_ready(data, args.evidence_root)
            print('PASS: retained preparation records complete; NOT R1 acceptance or authenticated evidence')
    except (OSError, ValueError, TypeError, KeyError, UnicodeError) as exc:
        print('NOT READY:', exc, file=sys.stderr)
        return 1
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
