"""Small executable model of document 23; NOT production auth, storage or an API.

Trusted principals and transaction outcomes are supplied by the test harness.
In-memory copy/replace simulates atomic commit; actual DB/mobile behavior remains
ACCOUNT-01..12 implementation evidence. No network, tokens, PII or world saves.
"""
from __future__ import annotations

from copy import deepcopy
from dataclasses import dataclass, field
import hashlib
import json
from typing import Any

from contract_model import strict_json

SOURCE = 'offline_client_report'
FIELDS = {'report_id', 'run_id', 'release_hash', 'milestone', 'outcome', 'revision'}
MAX_BYTES = 4096  # Fixture bound only; production bound is a reviewed API decision.


def canonical(value: Any) -> str:
    return json.dumps(value, sort_keys=True, separators=(',', ':'), ensure_ascii=True)


def parse_report(raw: str) -> dict:
    if not isinstance(raw, str) or len(raw.encode('utf-8')) > MAX_BYTES:
        raise ValueError('report_size')
    data = strict_json(raw)
    if not isinstance(data, dict) or set(data) != FIELDS:
        raise ValueError('report_fields')
    for name in FIELDS - {'revision'}:
        if not isinstance(data[name], str) or not 0 < len(data[name]) <= 128:
            raise ValueError('report_value')
    if type(data['revision']) is not int or not 0 <= data['revision'] < 2**53:
        raise ValueError('report_revision')
    return data


@dataclass
class AccountProgress:
    """Server model. `principal` is trusted auth output, never payload input."""
    known: dict[tuple[str, str], frozenset[str]]
    requirements: dict[str, dict]
    active: set[str] = field(default_factory=set)
    used_accounts: set[str] = field(default_factory=set)
    bindings: dict[str, tuple[str, str]] = field(default_factory=dict)
    receipts: dict[tuple[str, str], tuple[str, dict]] = field(default_factory=dict)
    milestones: dict[tuple[str, str, str], dict] = field(default_factory=dict)
    progress_version: int = 0

    def create(self, account: str) -> None:
        if account in self.used_accounts:
            raise ValueError('identity_not_reusable')
        self.used_accounts.add(account)
        self.active.add(account)

    def authorize(self, principal: str | None) -> None:
        if principal is None or principal not in self.active:
            raise ValueError('account_unavailable')

    def bind(self, principal: str | None, run: str, release_hash: str) -> None:
        self.authorize(principal)
        if run in self.bindings and self.bindings[run] != (principal, release_hash):
            raise ValueError('run_bound_elsewhere')
        self.bindings[run] = (principal, release_hash)

    def delete(self, principal: str) -> None:
        self.authorize(principal)
        self.active.remove(principal)
        self.receipts = {k: v for k, v in self.receipts.items() if k[0] != principal}
        self.milestones = {k: v for k, v in self.milestones.items() if k[0] != principal}
        # Abstract tombstones: run/account identities cannot be recycled. Production
        # stores minimum necessary lifecycle data under its deletion/retention policy.
        self.progress_version += 1

    def ingest(self, principal: str | None, raw: str, *, fault: str | None = None) -> dict:
        if fault not in {None, 'before_commit', 'after_commit', 'delete_before_commit'}:
            raise ValueError('unknown_fixture_fault')
        self.authorize(principal)
        data = parse_report(raw)
        if self.bindings.get(data['run_id']) != (principal, data['release_hash']):
            raise ValueError('run_not_owned')
        digest = hashlib.sha256(canonical(data).encode()).hexdigest()
        rid = (principal, data['report_id'])
        if rid in self.receipts:
            old_digest, result = self.receipts[rid]
            if old_digest != digest:
                raise ValueError('idempotency_conflict')
            return deepcopy(result)  # Does not reactivate a withdrawn milestone.
        allowed = self.known.get((data['release_hash'], data['milestone']))
        if allowed is None or data['outcome'] not in allowed:
            raise ValueError('unknown_release_milestone_outcome')
        mid = (principal, data['run_id'], data['milestone'])
        content = {k: data[k] for k in ('release_hash', 'milestone', 'outcome')}
        if mid in self.milestones and self.milestones[mid]['content'] != content:
            raise ValueError('milestone_conflict')
        staged = deepcopy(self.milestones)
        if mid not in staged:
            staged[mid] = {'content': content, 'source': SOURCE, 'effective': True}
        result = {'status': 'accepted', 'report_id': data['report_id'],
                  'source': SOURCE, 'acceptance_policy': 'offline-onboarding@1'}
        if fault == 'before_commit':
            raise ValueError('confirmed_rollback')
        if fault == 'delete_before_commit':
            self.delete(principal)
        self.authorize(principal)  # Models deletion-versus-ingestion serialization.
        self.milestones = staged
        self.receipts[rid] = (digest, deepcopy(result))
        self.progress_version += 1
        if fault == 'after_commit':
            raise ValueError('acknowledgement_lost')
        return result

    def withdraw(self, principal: str, run: str, milestone: str) -> None:
        """Trusted fixture operation representing separately authorized correction."""
        self.milestones[(principal, run, milestone)]['effective'] = False
        self.progress_version += 1

    def completed(self, principal: str | None) -> bool:
        self.authorize(principal)
        return any(k[0] == principal and m['effective'] and k[2] == 'prologue_completed'
                   for k, m in self.milestones.items())

    def admit(self, principal: str | None, policy: dict, *, expected_version: int | None = None, expected_policy_version: int | None = None) -> dict:
        self.authorize(principal)
        if set(policy) != {'version', 'requires', 'ungated'} or type(policy['version']) is not int:
            raise ValueError('invalid_policy')
        if type(policy['ungated']) is not bool or not isinstance(policy['requires'], list):
            raise ValueError('invalid_policy')
        required = policy['requires']
        if (any(not isinstance(r, str) for r in required) or len(required) != len(set(required))
                or not 0 < policy['version'] < 2**53 or len(required) > 16):
            raise ValueError('invalid_policy')
        if not required and not policy['ungated']:
            raise ValueError('empty_policy_not_explicit')
        if required and policy['ungated']:
            raise ValueError('invalid_policy')
        if expected_version is not None and expected_version != self.progress_version:
            raise ValueError('stale_progress')
        if expected_policy_version is not None and expected_policy_version != policy['version']:
            raise ValueError('stale_policy')
        missing = []
        for key in required:
            rule = self.requirements.get(key)
            if (not isinstance(rule, dict) or set(rule) != {'purpose', 'sources', 'alternatives'}
                    or rule['purpose'] != 'onboarding' or not rule['alternatives']):
                raise ValueError('unknown_or_invalid_requirement')
            if (not rule['sources'] or not set(rule['sources']) <=
                    {SOURCE, 'server_replayed_trace', 'server_authoritative_run'}):
                raise ValueError('invalid_evidence_policy')
            qualifies = any(
                mid[0] == principal and m['effective'] and m['source'] in rule['sources']
                and (m['content']['release_hash'], m['content']['milestone'], m['content']['outcome'])
                in rule['alternatives'] for mid, m in self.milestones.items())
            if not qualifies:
                missing.append(key)
        return {'eligible': not missing, 'missing': missing, 'policy_version': policy['version'],
                'progress_version': self.progress_version}


@dataclass
class LocalJournal:
    """Host metadata lives alongside, not inside, canonical portable game state."""
    run: str
    release: str
    account: str | None = None
    state: dict = field(default_factory=lambda: {'milestones': {}, 'revision': 0})
    pending: dict[str, str] = field(default_factory=dict)
    accepted: set[str] = field(default_factory=set)
    stopped: bool = False

    def reach(self, milestone: str, outcome: str, *, rollback: bool = False) -> str:
        if milestone in self.state['milestones']:
            return self.state['milestones'][milestone]
        revision = self.state['revision'] + 1
        rid = hashlib.sha256(f'{self.run}:{milestone}:{revision}'.encode()).hexdigest()
        raw = canonical({'report_id': rid, 'run_id': self.run, 'release_hash': self.release,
                         'milestone': milestone, 'outcome': outcome, 'revision': revision})
        state = deepcopy(self.state)
        pending = dict(self.pending)
        state['milestones'][milestone] = rid
        state['revision'] = revision
        pending[rid] = raw
        if not rollback:
            self.state, self.pending = state, pending
        return rid

    def claim(self, principal: str, server: AccountProgress) -> None:
        if self.stopped or self.account not in {None, principal}:
            raise ValueError('local_binding_conflict')
        server.bind(principal, self.run, self.release)
        self.account = principal

    def flush(self, principal: str | None, server: AccountProgress, *, online: bool = True,
              fault: str | None = None) -> int:
        if not online or self.stopped or principal is None:
            return 0
        if self.account != principal:
            raise ValueError('local_binding_conflict')
        try:
            server.authorize(principal)
        except ValueError:
            # The model represents a confirmed deleted-account response here.
            # Production distinguishes expiry (retry/sign-in) from deletion.
            self.stopped = principal in server.used_accounts and principal not in server.active
            raise
        sent = 0
        for rid, raw in list(self.pending.items()):
            server.ingest(principal, raw, fault=fault)
            self.accepted.add(rid)
            del self.pending[rid]
            sent += 1
        return sent
