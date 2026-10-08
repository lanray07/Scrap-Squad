"""Generate oracle traces from ORIGINAL, actor-isolated iOS gameplay sources.

Fixtures are QA only: some explicitly raise robot levels to reach later bosses.
No production content, balances or player defaults are altered.
"""
import hashlib
import json
import math
import os
from pathlib import Path
import subprocess

A = Path(__file__).resolve().parents[1]
ROOT = A.parent
out = A / 'app/src/androidTest/assets/parity.json'
out.parent.mkdir(parents=True, exist_ok=True)
oracle = A / 'native/build' / ('oracle.exe' if os.name == 'nt' else 'oracle')
process = subprocess.Popen([str(oracle)], stdin=subprocess.PIPE, stdout=subprocess.PIPE, text=True, encoding='utf-8', bufsize=1)


def send(q):
    process.stdin.write(json.dumps(q, ensure_ascii=True) + '\n'); process.stdin.flush()
    line = process.stdout.readline()
    if not line:
        raise RuntimeError('Oracle exited unexpectedly')
    result = json.loads(line)
    if 'error' in result:
        raise RuntimeError((q, result))
    return result


content_text = (ROOT / 'Sources/ScrapCore/Resources/content.json').read_text(encoding='utf-8')
content = json.loads(content_text)
cases = []
specs = [(f'weapon-{w["id"]}', 'survival', w['id'], 0, 100 + i, 240) for i, w in enumerate(content['weapons'])]
specs += [(f'boss-{b["id"]}', 'bossRush', 'singularity', i, 420 + i, 2600) for i, b in enumerate(content['biomes'])]
specs += [(f'mode-{mode}', mode, 'blaster', 0, 18446744073709551600 + i, 2600) for i, mode in enumerate(['campaign', 'survival', 'arena', 'scrapRun', 'fusionLab', 'dailyAnomaly'])]
for name, mode, weapon, zone, seed, ticks in specs:
    default = json.loads(send({'op': 'init', 'content': content_text, 'now': 1700000000})['profile'])
    default['zone'] = zone
    default['robotLevels'] = {'bolt': 50, 'patch': 50}
    default['weapons'][weapon] = 1
    default['equippedWeapon'] = weapon
    commands = []; checkpoints = []

    def command(q, checkpoint=False):
        q['now'] = 1700000000
        result = send(q); commands.append(q)
        if checkpoint:
            expected = {'battle': result.get('battle')}
            profile = json.loads(result['profile'])
            expected['profile'] = {key: profile[key] for key in ['scrap', 'credits', 'cores', 'completedRuns', 'kills', 'bosses', 'zone', 'weapons', 'components', 'buildingLevels', 'robotLevels', 'weaponLevels', 'squad', 'equippedWeapon']}
            checkpoints.append({'index': len(commands) - 1, 'expected': expected})
        return result

    command({'op': 'init', 'content': content_text, 'profile': json.dumps(default)}, True)
    state = command({'op': 'deploy', 'mode': mode, 'seed': str(seed), 'zone': zone}, True)
    for tick in range(ticks):
        battle = state['battle']
        if battle['state'] == 'choosing':
            state = command({'op': 'choose', 'id': battle['choices'][tick % len(battle['choices'])]}, True)
        elif battle['state'] != 'fighting':
            break
        if tick % 240 == 150:
            command({'op': 'dash', 'x': math.cos(tick / 300), 'y': math.sin(tick / 300)})
        if tick % 480 == 220:
            command({'op': 'ability'})
        if tick % 120 == 80:
            command({'op': 'overdrive'})
        state = command({'op': 'step', 'dt': .05, 'x': math.cos(tick / 120), 'y': math.sin(tick / 120)}, tick % 120 == 0)
    command({'op': 'retreat'}, True)
    command({'op': 'claim'}, True)
    command({'op': 'claim'}, True)  # duplicate reward suppression
    cases.append({'name': name, 'commands': commands, 'checkpoints': checkpoints})
    print(name, len(commands), 'commands', flush=True)
out.write_text(json.dumps({'source': {str(p.relative_to(ROOT)): hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted((ROOT/'Sources/ScrapCore').glob('*.swift'))}, 'cases': cases}, separators=(',', ':')), encoding='utf-8')
print('Wrote', len(cases), 'original Swift oracle traces:', out)
process.stdin.close()
try:
    process.wait(timeout=2)
except subprocess.TimeoutExpired:
    process.terminate()  # All replies received; Windows Swift shutdown can linger.
