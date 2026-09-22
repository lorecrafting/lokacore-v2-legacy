"""Generate checked reader navigation without changing specification bodies.

No third-party dependencies. Only the marked navigation blocks are generated.
This is documentation hygiene, not a schema, semantic validator or release gate.
"""
from __future__ import annotations

import argparse
import re
from pathlib import Path
from urllib.parse import unquote, urlsplit

ROOT = Path(__file__).resolve().parents[1]
START = '<!-- packet-navigation:start -->'
END = '<!-- packet-navigation:end -->'
# Role and suggested focus are reading metadata, not a new authority hierarchy.
DOCUMENTS = {
    'README.md': ('Packet overview and authority map', 'Start with the review guide and milestone guide; section 8 defines the document authority/conflict rules.'),
    'INDEX.md': ('Routing summary, not a replacement contract', 'Use the vocabulary and invariant links to reach governing sections. Phase summaries are not completion evidence.'),
    '00-first-cartridge-design.md': ('Product scope: full campaign and chapter ladder', 'Read the pitch, then section 11. Full-campaign mechanics and goals are not all chapter-one dependencies.'),
    '00a-chapter-one-content.md': ('Product scope: chapter one', 'Review the 57-room content, manifest, quests and scenarios. YAML field shapes remain illustrative until their schema gate.'),
    '01-core-principles.md': ('Design contract', 'Read authority, determinism and content principles before individual capabilities. Deferred features stay deferred.'),
    '02-beam-runtime-architecture.md': ('Design contract: online host', 'Review ownership and recovery now; production online hosting arrives at R14 and shared-world work later.'),
    '03-domain-state-persistence.md': ('Design contract: state and durability', 'Start with identities and scope, then sections 14-18 on receipts, commits, outbox and snapshots. Online table sketches are not local-save requirements.'),
    '04-command-event-effect-protocol.md': ('Design contract: decisions and projections', 'Read sections 1-10 for semantic execution. Network protocol sections apply when Realm transport is introduced.'),
    '05-cartridges-content-capabilities.md': ('Design contract: content format and capability boundary', 'Follow definitions, compilation, versioning and immutable releases. Deployment/extension details have their own applicability.'),
    '06-quests-dialogue-actions-scripting.md': ('Design contract: narrative and interaction', 'Quests/actions: sections 1-22. Custom events/scenes: 30-38 and 41-42. LokaScript sections 23-27 and 29 remain deferred; multiplayer scenes are later.'),
    '07-offline-storypacks-to-mmo.md': ('Design contract: two authority modes and portability', 'Read sections 1-14 for the shared boundary, then continuity and Realm reuse. The experiment envelope remains proposed.'),
    '08-builder-api-ai-factory.md': ('Design contract: authoring plane', 'Tools and agent permissions are separate from gameplay authority. General Builder/factory work follows demonstrated authoring needs.'),
    '09-cartridge-lab-certification.md': ('Design contract: applicable assurance', 'Start with section 1a for chapter one. The wider catalog does not require every gate for every profile.'),
    '10-mobile-commerce-release.md': ('Design contract: app and release', 'Separate offline play, free release, paid entitlements and later Realm. Review save compatibility and downloaded-content gates explicitly.'),
    '11-security-observability-operations.md': ('Design contract: safety and operations', 'Distinguish always-needed integrity/recovery from later online operations. LokaScript security is retained deferred design.'),
    '12-evennia-lessons.md': ('Informative prior-art evidence', 'Read as dated reasoning behind decisions, not as instructions to import Evennia or implement every listed feature.'),
    '13-lokacore-feature-inventory.md': ('Informative legacy inventory', 'Use for feature archaeology and disposition, never as a module-by-module porting checklist.'),
    '14-implementation-plan.md': ('Governing milestone tasks and gates', 'Use the plain-English R guide first. Numbers are stable labels; R6P pulls selected early slices forward and Realm does not block offline content.'),
    '15-acceptance-scenarios.md': ('Governing acceptance scenarios', 'Locate the scenario family for a claim. A listed scenario is a requirement/example for implementation evidence, not proof it has run.'),
    '16-decision-register.md': ('Decision register: status varies by entry', 'Accepted design direction is not R0 approval or implementation completion. Provisional and deferred decisions have separate checkpoints.'),
    '17-research-baseline.md': ('Informative dated external research', 'Preserve source dates. Recheck policy/toolchain facts at the relevant implementation or release gate.'),
    '18-review-record.md': ('Informative cumulative review history', 'Historical findings may describe superseded drafts. Read current contracts for implementation; old closure conclusions are not current approval.'),
    '19-quest-sharing-instancing-capacity.md': ('Design contract: independent scope and capacity axes', 'Read the dimensions and selection table before details. The smithy is a composition example; queued service and spatial-instance gates depend on actual use.'),
    '20-classic-mud-lessons.md': ('Informative prior-art evidence', 'Study patterns and tradeoffs, not source code or a mandate to build every classic mechanic before the first release.'),
    '21-composable-world-primitives.md': ('Design boundaries plus capability catalog', 'Read sections 1-3 and 24-26 for composition/graduation. Check release scope before treating a catalog entry or candidate as current work.'),
    '22-ink-runtime-lessons.md': ('Informative pinned prior-art study', 'Read the conclusions alongside the current conformance corpus and R1 envelope; proposed adaptations here are not automatically accepted.'),
    'pre-release-proof.md': ('Proposed R6P work package', 'Four-place proof on the fresh engine before the full chapter; not a reduced release or completed build.'),
    'r1-acceptance-envelope.md': ('Proposed R1 experiment and thresholds', 'Read semantic versus synthetic workloads, measurement methods, fault classes and acceptance procedure. Numbers are not measured or accepted yet.'),
    'INDEX-cut-candidates.md': ('Informative pruning suggestions', 'Listing a section does not approve deleting it or dropping its invariants. Recheck suggestions against current contracts.'),
}


def strip_navigation(text: str) -> str:
    if START not in text and END not in text:
        return text
    if text.count(START) != 1 or text.count(END) != 1:
        raise ValueError('missing/duplicate navigation marker')
    if text.index(START) > text.index(END):
        raise ValueError('reversed navigation markers')
    pattern = re.escape(START) + r'.*?' + re.escape(END) + r'\n\n'
    if not re.search(pattern, text, flags=re.S):
        raise ValueError('navigation must end with a blank line')
    return re.sub(pattern, '', text, count=1, flags=re.S)


def prose_lines(text: str):
    """Ignore fenced code and raw generated navigation while extracting Markdown."""
    fence = None
    for line in strip_navigation(text).splitlines():
        match = re.match(r'^\s{0,3}(`{3,}|~{3,})(.*)$', line)
        if match:
            marker, tail = match.groups()
            if fence is None:
                fence = marker
            elif marker[0] == fence[0] and len(marker) >= len(fence) and not tail.strip():
                fence = None
            continue
        if fence is None:
            yield line
    if fence is not None:
        raise ValueError('unclosed Markdown code fence')


def slug(text: str) -> str:
    # Covers the packet's ATX headings (inline code, punctuation, Unicode words).
    text = re.sub(r'<[^>]*>', '', text).lower()
    text = re.sub(r'\[([^]]+)\]\([^)]*\)', r'\1', text)
    return re.sub(r'[^\w\- ]', '', text).replace(' ', '-')


def headings(text: str):
    used = set()
    for line in prose_lines(text):
        match = re.match(r'^(#{1,6})\s+(.+?)\s*#*$', line)
        if not match:
            continue
        level, label = len(match[1]), match[2]
        base = slug(label)
        anchor, count = base, 0
        while anchor in used:
            count += 1
            anchor = f'{base}-{count}'
        used.add(anchor)
        yield level, label, anchor


def navigation(name: str, text: str) -> str:
    role, focus = DOCUMENTS[name]
    section_list = list(headings(text))
    menu = [f'- [{label}](#{anchor})' for i, (level, label, anchor) in enumerate(section_list)
            if level == 2 or (name == '14-implementation-plan.md' and level == 1 and i > 0)]
    return '\n'.join([
        START,
        '[Review guide](REVIEW-GUIDE.md) · [R milestones](R-MILESTONES.md) · [Packet home](README.md)',
        '', f'**Reader context:** {role}.', '', focus,
        '', '<details>', '<summary>Sections in this document</summary>', '',
        *menu, '', '</details>', END, '', '',
    ])


def render(name: str, text: str) -> str:
    body = strip_navigation(text)
    if not body.startswith('# ') or '\n\n' not in body:
        raise ValueError(f'{name}: expected title and blank line')
    split = body.index('\n\n') + 2
    return body[:split] + navigation(name, body) + body[split:]


def validate_links(root: Path = ROOT) -> None:
    """Check Markdown file/heading links inside this packet, not external URLs."""
    root = root.resolve()
    for path in sorted(root.rglob('*.md')):
        text = path.read_text()
        # Strip fences, but include generated navigation links in this pass.
        nav = text[text.index(START):text.index(END)] if START in text and END in text else ''
        prose = '\n'.join(prose_lines(text)) + '\n' + nav
        for target in re.findall(r'(?<!!)\[[^\]\n]+\]\(([^\s)]+)\)', prose):
            parts = urlsplit(target)
            if parts.scheme or parts.netloc:
                continue
            dest = (path.parent / unquote(parts.path)).resolve() if parts.path else path
            if not dest.is_relative_to(root):
                continue  # Historic links to the rest of the repo are outside this check.
            if not dest.exists():
                raise ValueError(f'{path.name}: missing local link {target}')
            if parts.fragment and dest.suffix == '.md':
                anchors = {a for _, _, a in headings(dest.read_text())}
                if unquote(parts.fragment) not in anchors:
                    raise ValueError(f'{path.name}: missing local heading {target}')


def validate(root: Path = ROOT) -> None:
    numbered = {p.name for p in root.glob('*.md') if re.match(r'^\d\d[a-z]?-', p.name)}
    known = {n for n in DOCUMENTS if re.match(r'^\d\d[a-z]?-', n)}
    if numbered != known:
        raise ValueError('numbered document inventory changed; update reader routing')
    for name in DOCUMENTS:
        path = root / name
        if path.read_text() != render(name, path.read_text()):
            raise ValueError(f'{name}: stale navigation; run packet_navigation.py --write')
    plan = (root / '14-implementation-plan.md').read_text()
    ids = re.findall(r'^## (R\d+[A-Z]?) — ', plan, re.M)
    guide = (root / 'R-MILESTONES.md').read_text()
    guide_ids = re.findall(r'^\| \[(R\d+[A-Z]?)\]', guide, re.M)
    if len(ids) != len(set(ids)) or sorted(ids) != sorted(guide_ids):
        raise ValueError('milestone guide does not cover each top-level R exactly once')
    for sub in re.findall(r'^### (R\d+[A-Z]) — ', plan, re.M):
        if f'**[{sub}](' not in guide:
            raise ValueError(f'missing subphase explanation: {sub}')
    validate_links(root)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write', action='store_true', help='replace marked navigation only')
    parser.add_argument('--check', action='store_true', help='validate navigation, links and milestone coverage')
    args = parser.parse_args()
    if args.write:
        for name in DOCUMENTS:
            path = ROOT / name
            path.write_text(render(name, path.read_text()))
    validate()
    print(f'PASS: {len(DOCUMENTS)} reader menus, local packet links and R milestone coverage')


if __name__ == '__main__':
    main()
