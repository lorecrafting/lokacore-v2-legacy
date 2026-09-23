"""Small specification model for 04 §5.2–5.4, NOT a production engine.

Fixed abstract fields/operations deliberately bound the example. No compiler,
real host, storage, authentication, wall clock, or actual scheduler is modeled.
"""
from __future__ import annotations

from collections import deque
from copy import deepcopy
from dataclasses import dataclass
from typing import Any
import re

from contract_model import canonical


@dataclass
class RuleFault(Exception):
    code: str


class CompositionModel:
    """Evaluate one isolated proposal; faults return the unchanged input state."""
    FIELDS = {
        'fact.set': {'op', 'fact', 'value'},
        'fact.add': {'op', 'fact', 'amount'},
        'event.emit': {'op', 'event', 'payload'},
        'subscription.activate': {'op', 'rule'},
        'item.transfer': {'op', 'item', 'source', 'destination'},
        'job.schedule': {'op', 'id', 'due'},
    }
    FACTS = {'flag': (0, 2), 'seen': (0, 2), 'count': (-2147483648, 2147483647)}
    CUSTOM = {'proof.signal', 'proof.followup'}

    def __init__(self, limits: dict[str, int]):
        self.limits = deepcopy(limits)

    @staticmethod
    def initial() -> dict[str, Any]:
        return {'facts': {'flag': 0, 'seen': 0, 'count': 0},
                'locations': {'lantern': 'hero', 'stone': 'room', 'bag': 'hero'},
                'capacities': {'bag': 1}, 'active': [], 'clock': 6, 'jobs': {}}

    @staticmethod
    def _check_op(op: dict, rule_ids: set[str]) -> None:
        if type(op) is not dict or op.get('op') not in CompositionModel.FIELDS:
            raise RuleFault('unknown_operation')
        kind = op['op']
        if set(op) != CompositionModel.FIELDS[kind]:
            raise RuleFault('invalid_operation')
        if kind.startswith('fact.'):
            if op['fact'] not in CompositionModel.FACTS:
                raise RuleFault('unknown_fact')
            if kind == 'fact.add' and op['fact'] != 'count':
                raise RuleFault('invalid_operation')
            value = op['value'] if kind == 'fact.set' else op['amount']
            if type(value) is not int:
                raise RuleFault('invalid_value')
        elif kind == 'event.emit':
            if op['event'] not in CompositionModel.CUSTOM:
                raise RuleFault('forbidden_event')
            if type(op['payload']) is not dict:
                raise RuleFault('invalid_event')
            canonical(op['payload'])
        elif kind == 'subscription.activate':
            if op['rule'] not in rule_ids:
                raise RuleFault('unknown_subscription')
        elif kind == 'item.transfer':
            if any(type(op[k]) is not str or not op[k] for k in ('item', 'source', 'destination')):
                raise RuleFault('invalid_target')
        elif kind == 'job.schedule':
            if type(op['id']) is not str or not op['id'] or type(op['due']) is not int:
                raise RuleFault('invalid_job')

    def evaluate(self, initial: dict, root: list[dict], rules: list[dict], *, advance_target: int | None = None) -> dict:
        state = deepcopy(initial)
        events: list[dict] = []
        deliveries: list[str] = []
        queue: deque = deque()
        writers: dict[tuple, str] = {}
        used = {k: 0 for k in ('operations', 'query_steps', 'events', 'deliveries', 'created_jobs')}

        def spend(key: str, count: int = 1) -> None:
            used[key] += count
            if used[key] > self.limits[key]:
                raise RuleFault('budget_' + key)

        def write(target: tuple, group: str) -> None:
            if target in writers and writers[target] != group:
                raise RuleFault('conflicting_write')
            writers[target] = group

        def emit(name: str, payload: dict, depth: int) -> None:
            spend('events')
            if depth > self.limits['reaction_depth']:
                raise RuleFault('budget_reaction_depth')
            event = {'type': name, 'payload': deepcopy(payload), 'position': len(events) + 1,
                     'time': state['clock']}
            # Lifecycle eligibility is snapshotted at EMISSION, not delivery.
            eligible = tuple(r for r in ordered if r['event'] == name and r['id'] in state['active'])
            spend('query_steps', len(ordered))
            events.append(event)
            queue.append((event, eligible, depth))
            if len(canonical(events)) > self.limits['output_bytes']:
                raise RuleFault('budget_output_bytes')

        def sequence(ops: list[dict], group: str, depth: int) -> None:
            for op in ops:
                spend('operations')
                kind = op['op']
                if kind.startswith('fact.'):
                    name = op['fact']
                    write(('fact', name), group)
                    value = op['value'] if kind == 'fact.set' else state['facts'][name] + op['amount']
                    low, high = self.FACTS[name]
                    if not low <= value <= high:
                        raise RuleFault('resource_bounds')
                    state['facts'][name] = value
                elif kind == 'event.emit':
                    emit(op['event'], op['payload'], depth)
                elif kind == 'subscription.activate':
                    write(('subscription', op['rule']), group)
                    if op['rule'] not in state['active']:
                        state['active'].append(op['rule'])
                        state['active'].sort()
                elif kind == 'item.transfer':
                    item = op['item']
                    write(('item', item), group)
                    if state['locations'].get(item) != op['source']:
                        raise RuleFault('not_owned')
                    if op['destination'] not in {'hero', 'room'} | set(state['locations']):
                        raise RuleFault('unknown_destination')
                    state['locations'][item] = op['destination']
                    emit('engine.item_transferred', {'item': item, 'from': op['source'], 'to': op['destination']}, depth)
                elif kind == 'job.schedule':
                    write(('job', op['id']), group)
                    barrier = state['clock'] if advance_target is None else max(state['clock'], advance_target)
                    if op['due'] <= barrier:
                        raise RuleFault('nonfuture_job')
                    if op['id'] in state['jobs']:
                        raise RuleFault('duplicate_job')
                    spend('created_jobs')
                    state['jobs'][op['id']] = op['due']
                    if len(state['jobs']) > self.limits['pending_jobs']:
                        raise RuleFault('budget_pending_jobs')

        try:
            canonical(initial)
            if advance_target is not None and (type(advance_target) is not int or advance_target < state['clock']):
                raise RuleFault('invalid_time')
            if type(root) is not list or type(rules) is not list:
                raise RuleFault('invalid_plan')
            ids = [r['id'] for r in rules]
            if any(type(i) is not str or not re.fullmatch(r'[a-z][a-z0-9_-]*', i) for i in ids) or len(ids) != len(set(ids)):
                raise RuleFault('invalid_registry')
            ordered = sorted(rules, key=lambda r: r['id'])
            for rule in ordered:
                if set(rule) != {'id', 'event', 'guard', 'ops'} or rule['event'] not in self.CUSTOM | {'engine.item_transferred'}:
                    raise RuleFault('invalid_rule')
                guard = rule['guard']
                if guard is not None:
                    if (type(guard) is not dict or set(guard) != {'source', 'key', 'equals'}
                            or guard['source'] not in {'overlay', 'event'}
                            or type(guard['key']) is not str
                            or (guard['source'] == 'overlay' and guard['key'] not in self.FACTS)):
                        raise RuleFault('unknown_policy')
                if type(rule['ops']) is not list:
                    raise RuleFault('invalid_plan')
                for op in rule['ops']:
                    self._check_op(op, set(ids))
            if set(state['active']) - set(ids):
                raise RuleFault('unknown_subscription')
            for op in root:
                self._check_op(op, set(ids))
            sequence(root, 'root', 0)
            while queue:
                event, eligible, depth = queue.popleft()
                for rule in eligible:
                    spend('deliveries')
                    guard = rule['guard']
                    if guard is not None:
                        spend('query_steps')
                        source = state['facts'] if guard['source'] == 'overlay' else event['payload']
                        if guard['key'] not in source or canonical(source[guard['key']]) != canonical(guard['equals']):
                            continue
                    deliveries.append(f"{event['position']}:{rule['id']}")
                    sequence(rule['ops'], f"delivery:{event['position']}:{rule['id']}", depth + 1)
            for item in sorted(state['locations']):
                visited = set()
                cursor = item
                while cursor in state['locations']:
                    spend('query_steps')
                    if cursor in visited:
                        raise RuleFault('containment_cycle')
                    visited.add(cursor)
                    cursor = state['locations'][cursor]
            for container, capacity in state['capacities'].items():
                spend('query_steps', len(state['locations']))
                if sum(v == container for v in state['locations'].values()) > capacity:
                    raise RuleFault('capacity_exceeded')
            result = {'kind': 'accepted', 'code': 'ok', 'state': state, 'events': events, 'deliveries': deliveries}
            if len(canonical(result)) > self.limits['output_bytes']:
                raise RuleFault('budget_output_bytes')
            return result
        except (RuleFault, ValueError, KeyError, TypeError, UnicodeError) as exc:
            code = exc.code if isinstance(exc, RuleFault) else 'invalid_plan'
            return {'kind': 'fault', 'code': code, 'state': deepcopy(initial), 'events': [], 'deliveries': []}


def all_matches(items: list, limit: int) -> list:
    """Only the cardinality example; not a production selector/query compiler."""
    if type(items) is not list or type(limit) is not int or limit < 0:
        raise ValueError('invalid_selector')
    if len(items) > limit:
        raise ValueError('selector_cardinality')
    return deepcopy(items)
