"""Run composition.evaluate plans through the Python model and tally result codes.

Usage: composition_tally.py CHECKS_DIR PROFILE_JSON PLANS_NDJSON
Prints {"vocabulary": [...], "tally": {code: n}, "deep_accepted": n}. The fault
vocabulary is read from the model source, so it follows the model.
"""
import json
import re
import sys

checks, profile, plans = sys.argv[1:4]
sys.path.insert(0, checks)
from composition_model import CompositionModel  # noqa: E402

source = open(f"{checks}/composition_model.py").read()
vocabulary = set(re.findall(r"RuleFault\('([a-z_]+)'\)", source))
vocabulary |= {"budget_" + k for k in re.findall(r"spend\('([a-z_]+)'", source)}
vocabulary.add("invalid_plan")  # the model's catch-all for ValueError/KeyError/TypeError

defaults = json.load(open(profile))["limits"]
tally, deep = {}, 0
for line in open(plans, encoding="utf-8"):
    req = json.loads(line)
    result = CompositionModel({**defaults, **req["limits"]}).evaluate(
        req["initial"], req["root"], req["rules"], advance_target=req.get("advance_target"))
    tally[result["code"]] = tally.get(result["code"], 0) + 1
    if result["kind"] == "accepted" and len(result["deliveries"]) >= 3:
        deep += 1
print(json.dumps({"vocabulary": sorted(vocabulary), "tally": tally, "deep_accepted": deep}))
