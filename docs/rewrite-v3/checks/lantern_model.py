"""Four-place narrative specification example, NOT a reusable game engine.

Reuses the existing abstract receipt/transaction fault model. No actual SQLite,
compiler, scene framework, real account, event engine or device evidence here.
"""
from __future__ import annotations
from copy import deepcopy

from contract_model import ContractModel


class LanternModel(ContractModel):
    EXITS = {'landing': {'north': 'green'}, 'green': {'south': 'landing', 'east': 'reed_bank'},
             'reed_bank': {'west': 'green', 'east': 'shelter'}, 'shelter': {'west': 'reed_bank'}}

    def __init__(self):
        super().__init__('state')
        self.memory = {'revision': 0, 'room': 'landing', 'lantern': 'shelter', 'quest': 'absent',
                       'choice': None, 'search_plan': 'undecided', 'clock': 6, 'bram_room': 'landing',
                       'rng': [1, 2, 3, 4], 'narration': [], 'milestone': None}
        self.durable = deepcopy(self.memory)

    def _decide(self, req):
        s = deepcopy(self.memory)
        action, payload = req['action'], req.get('input', {})
        fields = {'look': set(), 'activate': set(), 'move': {'direction'}, 'take': set(), 'drop': set(),
                  'talk': set(), 'choose': {'choice_id', 'continuation_id'}, 'close_choice': set(), 'wait': {'until'}}
        if action not in fields or set(payload) != fields[action]:
            return s, 'invalid_input', [], False
        if action == 'look':
            return s, 'observed', [], True
        if action == 'activate':
            if s['quest'] != 'absent' or s['room'] != s['bram_room']:
                return s, 'not_eligible', [], False
            s['quest'] = 'active'
            code = 'activated_with_possession' if s['lantern'] == 'hero' else 'activated'
        elif action == 'move':
            if type(payload['direction']) is not str:
                return s, 'invalid_input', [], False
            dest = self.EXITS[s['room']].get(payload['direction'])
            if not dest:
                return s, 'exit_unavailable', [], False
            s['room'] = dest
            code = 'moved'
        elif action == 'take':
            if s['lantern'] != s['room']:
                return s, 'not_present', [], False
            s['lantern'] = 'hero'
            code = 'taken'
        elif action == 'drop':
            if s['lantern'] != 'hero':
                return s, 'not_owned', [], False
            s['lantern'] = s['room']
            code = 'dropped'
        elif action == 'talk':
            if s['quest'] != 'active' or s['room'] != s['bram_room']:
                return s, 'not_eligible', [], False
            if s['lantern'] != 'hero':
                return s, 'not_owned', [], False
            # Reopening a still-pending choice does not mint a new occurrence.
            s['choice'] = s['choice'] or 'proof-choice:' + req['id']
            code = 'choice_opened'
        elif action == 'choose':
            if (s['choice'] is None or payload['continuation_id'] != s['choice']
                    or payload['choice_id'] not in ('carry', 'leave')):
                return s, 'invalid_choice', [], False
            if s['lantern'] != 'hero':
                return s, 'not_owned', [], False
            if s['room'] != s['bram_room']:
                return s, 'not_present', [], False
            choice = payload['choice_id']
            occurrence = s['choice']
            s['quest'], s['choice'] = 'resolved', None
            s['search_plan'] = 'player_led' if choice == 'carry' else 'party_led'
            if choice == 'leave':
                s['lantern'] = 'bram'
            s['narration'].append({'id': occurrence + ':outcome', 'text_key': 'proof.' + choice,
                                   'bindings': {'actor': 'hero', 'bram': 'bram', 'lantern': 'lantern'}})
            s['milestone'] = {'key': 'proof.terminal', 'occurrence': occurrence, 'outcome': choice}
            code = 'resolved_' + choice
        elif action == 'close_choice':
            if s['choice'] is None:
                return s, 'invalid_choice', [], False
            s['choice'] = None
            code = 'choice_closed'
        else:
            until = payload['until']
            if type(until) is not int or not s['clock'] < until <= 23:
                return s, 'invalid_time', [], False
            s['clock'] = until
            s['bram_room'] = 'landing' if until < 19 else 'green'
            code = 'waited'
        s['revision'] += 1
        return s, code, [code], True
