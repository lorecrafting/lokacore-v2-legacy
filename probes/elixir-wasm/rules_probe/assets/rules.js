// JavaScript mirror of RulesProbe.decide/2, used as the baseline and parity check.
function xorshift(x) {
  x = (x ^ (x << 13)) >>> 0;
  x = (x ^ (x >>> 17)) >>> 0;
  return (x ^ (x << 5)) >>> 0;
}
const clamp = (v) => Math.min(Math.max(v, 0), 56);

export function decide(s, action) {
  const r = xorshift(s.rng);
  if (action[0] === "move") {
    return { ...s, x: clamp(s.x + action[1]), y: clamp(s.y + action[2]), rng: r };
  }
  const dmg = Math.trunc((action[1] * (50 + (r % 51))) / 100);
  const loot = r % 7 === 0 ? 3 : 0;
  return { ...s, hp: Math.max(s.hp - Math.trunc(dmg / 4), 0), gold: s.gold + loot, rng: r };
}
