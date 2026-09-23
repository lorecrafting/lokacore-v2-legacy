"""Small executable specification model; NOT a production kernel or database test.

It deliberately implements only the conformance/cases.json vocabulary. No legacy
engine imports, network, filesystem persistence, host clock, or global RNG.
"""
from __future__ import annotations

import copy
import hashlib
import json
from typing import Any

U32 = (1 << 32) - 1
SAFE_INT = (1 << 53) - 1


def canonical(value: Any) -> bytes:
    """The fixture codec: scalar Unicode values, ASCII keys, safe integers, no floats."""
    def check(x: Any) -> None:
        if x is None or type(x) is bool:
            return
        if type(x) is int:
            if abs(x) > SAFE_INT:
                raise ValueError("integer_out_of_range")
        elif type(x) is str:
            x.encode("utf-8", errors="strict")
        elif type(x) is list:
            for v in x:
                check(v)
        elif type(x) is dict:
            for k, v in x.items():
                if type(k) is not str or not k.isascii():
                    raise ValueError("non_ascii_key")
                check(v)
        else:
            raise ValueError("unsupported_canonical_value")
    check(value)
    return json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False,
                      allow_nan=False).encode("utf-8")


def strict_json(text: str) -> Any:
    def pairs(items: list[tuple[str, Any]]) -> dict[str, Any]:
        result: dict[str, Any] = {}
        for key, value in items:
            if key in result:
                raise ValueError("duplicate_key")
            result[key] = value
        return result
    def invalid_constant(value: str) -> Any:
        raise ValueError("invalid_number: " + value)
    value = json.loads(text, object_pairs_hook=pairs, parse_constant=invalid_constant)
    canonical(value)
    return value


def divide(a: int, b: int) -> tuple[int, int]:
    if type(a) is not int or type(b) is not int or abs(a) > SAFE_INT or abs(b) > SAFE_INT:
        raise ValueError("integer_out_of_range")
    if b == 0:
        raise ValueError("divide_by_zero")
    q = abs(a) // abs(b)
    if (a < 0) != (b < 0):
        q = -q
    return q, a - q * b


def rng_next(words: list[int]) -> tuple[int, list[int]]:
    """xoshiro128** 1.1; four explicit uint32 words, no implicit seed expansion."""
    if (type(words) is not list or len(words) != 4 or any(type(v) is not int or not 0 <= v <= U32 for v in words)
            or not any(words)):
        raise ValueError("invalid_rng_state")
    def rotl(v: int, n: int) -> int:
        return ((v << n) | (v >> (32 - n))) & U32
    a, b, c, d = words
    result = (rotl((b * 5) & U32, 7) * 9) & U32
    t = (b << 9) & U32
    c ^= a
    d ^= b
    b ^= c
    a ^= d
    c ^= t
    d = rotl(d, 11)
    return result, [a & U32, b & U32, c & U32, d & U32]


def uniform(words: list[int], bound: int, max_draws: int = 1024) -> tuple[int, list[int]]:
    if type(bound) is not int or not 1 <= bound <= (1 << 32):
        raise ValueError("invalid_bound")
    if type(max_draws) is not int or max_draws < 0:
        raise ValueError("invalid_rng_budget")
    if (type(words) is not list or len(words) != 4
            or any(type(v) is not int or not 0 <= v <= U32 for v in words) or not any(words)):
        raise ValueError("invalid_rng_state")
    limit = (1 << 32) - ((1 << 32) % bound)
    next_words = list(words)
    for _ in range(max_draws):
        raw, next_words = rng_next(next_words)
        if raw < limit:
            return raw % bound, next_words
    raise ValueError("rng_budget_exhausted")


def initial_state() -> dict[str, Any]:
    return {"revision": 0, "room": "landing", "lantern": "green", "quest": "absent",
            "arrived": False, "clock": 6, "bram_room": "landing", "job_pending": True,
            "rng": [1, 2, 3, 4], "choice": None, "outcome": None}


class ContractModel:
    """Abstract serial owner with simulated durable storage and fault boundaries."""
    def __init__(self, credit: str = "event") -> None:
        if credit not in {"event", "state"}:
            raise ValueError("unknown_credit_policy")
        self.credit = credit
        self.memory = initial_state()
        self.durable = initial_state()
        self.receipts: dict[str, dict[str, Any]] = {}
        self.published: list[str] = []
        self.in_doubt = False
        self.pending: tuple[str, dict[str, Any], dict[str, Any]] | None = None

    @staticmethod
    def _response(kind: str, code: str, revision: int, delivery: str = "new") -> dict[str, Any]:
        return {"kind": kind, "code": code, "revision": revision, "delivery": delivery}

    def _intent(self, request: dict[str, Any]) -> str:
        allowed = {"id", "actor", "action", "targets", "input", "view", "session", "route", "seq"}
        if (set(request) - allowed or not {"id", "actor", "action"} <= set(request)
                or any(type(request[k]) is not str or not request[k] for k in ("id", "actor", "action"))
                or type(request.get("targets", [])) is not list
                or any(type(x) is not str for x in request.get("targets", []))
                or type(request.get("input", {})) is not dict):
            raise ValueError("invalid_envelope")
        canonical(request)
        value = {"actor": request["actor"], "action": request["action"],
                 "targets": request.get("targets", []), "input": request.get("input", {})}
        return hashlib.sha256(canonical(value)).hexdigest()

    def _decide(self, request: dict[str, Any]) -> tuple[dict[str, Any], str, list[str], bool]:
        state = copy.deepcopy(self.memory)
        action, payload = request["action"], request.get("input", {})
        fields = {"look": set(), "activate": set(), "move": {"direction"},
                  "take": set(), "drop": set(), "wait": {"until"},
                  "choose": {"choice_id", "continuation_id"}}
        if action not in fields or set(payload) != fields[action]:
            return state, "invalid_input", [], False
        events: list[str] = []
        if action == "look":
            return state, "observed", [], True
        if action == "activate":
            if state["quest"] != "absent" or state["room"] != state["bram_room"]:
                return state, "not_eligible", [], False
            state["quest"] = "active"
            events.append("quest_activated")
            if self.credit == "state" and state["lantern"] == "hero":
                state["quest"], state["arrived"] = "resolved", True
                state["choice"] = "lantern-offer-1"
                events.extend(["quest_resolved", "fact_changed"])
            code = "activated"
        elif action == "move":
            exits = {"landing": {"north": "green"}, "green": {"south": "landing"}}
            if type(payload["direction"]) is not str:
                return state, "invalid_input", [], False
            destination = exits[state["room"]].get(payload["direction"])
            if not destination:
                return state, "no_exit", [], False
            state["room"] = destination
            code = "moved"
            events.append("entity_entered_room")
        elif action == "take":
            if state["lantern"] != state["room"]:
                return state, "not_present", [], False
            roll, state["rng"] = uniform(state["rng"], 100)
            if roll < 50:
                state["lantern"] = "hero"
                code = "taken"
                events.extend(["check_passed", "item_acquired"])
                if state["quest"] == "active":
                    state["quest"], state["arrived"] = "resolved", True
                    state["choice"] = "lantern-offer-1"
                    events.extend(["quest_resolved", "fact_changed"])
            else:
                code = "check_failed"
                events.append("check_failed")
        elif action == "choose":
            if (state["choice"] is None or payload["continuation_id"] != state["choice"]
                    or payload["choice_id"] not in ("carry", "leave")):
                return state, "invalid_choice", [], False
            state["choice"], state["outcome"] = None, payload["choice_id"]
            code = "choice_completed"
            events.append("choice_completed")
        elif action == "drop":
            if state["lantern"] != "hero":
                return state, "not_owned", [], False
            state["lantern"] = state["room"]
            code = "dropped"
            events.append("item_dropped")
        else:
            until = payload["until"]
            if type(until) is not int or not state["clock"] < until <= 48:
                return state, "invalid_time", [], False
            state["clock"] = until
            if state["job_pending"] and until >= 19:
                state["bram_room"], state["job_pending"] = "green", False
                events.append("schedule_completed")
            code = "waited"
        state["revision"] += 1
        return state, code, events, True

    def invoke(self, request: dict[str, Any], *, authorized: bool = True,
               fault: str | None = None) -> dict[str, Any]:
        if fault not in {None, "before_commit", "commit_pending",
                         "after_commit_before_memory", "after_memory_before_response"}:
            raise ValueError("unknown_fault")
        if type(request) is not dict:
            return self._response("rejected", "invalid_envelope", self.memory["revision"])
        # Model authorization is supplied by the test harness, never by request content.
        if not authorized or request.get("actor") != "hero":
            return self._response("rejected", "unauthorized", self.memory["revision"])
        try:
            digest = self._intent(request)
        except (ValueError, UnicodeError, TypeError):
            return self._response("rejected", "invalid_envelope", self.memory["revision"])
        if self.in_doubt:
            return self._response("retryable", "commit_pending", self.memory["revision"])
        identity = request["id"]  # One trusted lineage/actor in this intentionally tiny model.
        prior = self.receipts.get(identity)
        if prior:
            if prior["intent"] != digest:
                return self._response("rejected", "integrity_conflict", self.memory["revision"])
            result = copy.deepcopy(prior["result"])
            result["delivery"] = "replay"
            return result
        if "view" in request and request["view"] != f"view:{self.memory['revision']}":
            result = self._response("rejected", "stale_view", self.memory["revision"])
            self.receipts[identity] = {"intent": digest, "result": result}
            return copy.deepcopy(result)
        proposed, code, events, accepted = self._decide(request)
        result = self._response("accepted" if accepted else "rejected", code, proposed["revision"])
        receipt = {"intent": digest, "result": result}
        if fault == "before_commit":
            return self._response("retryable", "rolled_back", self.memory["revision"])
        if fault == "commit_pending":
            self.in_doubt = True
            self.pending = (identity, proposed, receipt)
            return self._response("retryable", "commit_pending", self.memory["revision"])
        self.durable = copy.deepcopy(proposed)
        self.receipts[identity] = copy.deepcopy(receipt)
        if fault == "after_commit_before_memory":
            self.in_doubt = True
            return self._response("retryable", "commit_unknown", self.memory["revision"])
        self.memory = copy.deepcopy(proposed)
        self.published.extend(events)
        if fault == "after_memory_before_response":
            return self._response("retryable", "response_lost", self.memory["revision"])
        if fault is not None:
            raise ValueError("unknown_fault")
        return copy.deepcopy(result)

    def settle(self, committed: bool) -> None:
        if type(committed) is not bool:
            raise ValueError("invalid_commit_disposition")
        if self.pending is None:
            raise ValueError("no_pending_transaction")
        identity, proposed, receipt = self.pending
        if committed:
            self.durable = copy.deepcopy(proposed)
            self.receipts[identity] = copy.deepcopy(receipt)
        self.pending = None

    def recover(self) -> dict[str, Any]:
        if self.pending is not None:
            return self._response("retryable", "commit_pending", self.memory["revision"])
        self.memory = copy.deepcopy(self.durable)
        self.in_doubt = False
        return self._response("recovered", "recovered", self.memory["revision"])
