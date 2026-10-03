"""Author original synthesized loops and cues. No samples, downloads or player data."""
import array
import math
import random
import sys
import wave
from pathlib import Path

RATE = 22050
ROOT = Path(__file__).resolve().parents[1] / 'App/Resources/Audio'
ROOT.mkdir(parents=True, exist_ok=True)


def hz(note):
    return 440 * 2 ** ((note - 69) / 12)


def write(name, samples):
    peak = max(abs(x) for x in samples) or 1
    scale = min(1, .85 / peak)
    pcm = array.array('h', (int(max(-1, min(1, x * scale)) * 32767) for x in samples))
    if sys.byteorder != 'little':
        pcm.byteswap()
    with wave.open(str(ROOT / (name + '.wav')), 'wb') as output:
        output.setparams((1, 2, RATE, len(pcm), 'NONE', 'not compressed'))
        output.writeframes(pcm.tobytes())


def tone(samples, start, duration, note, gain, brightness=.2):
    begin = round(start * RATE)
    count = round(duration * RATE)
    frequency = hz(note)
    for n in range(count):
        t = n / RATE
        envelope = min(1, t / .012) * max(0, 1 - t / duration) ** 1.5
        value = (math.sin(math.tau * frequency * t) + brightness * math.sin(math.tau * frequency * 2 * t)) * envelope * gain
        samples[(begin + n) % len(samples)] += value


def loop(name, bpm, root, intensity):
    beat = 60 / bpm
    length = beat * 32
    samples = [0.] * round(length * RATE)
    randomizer = random.Random(5351 + intensity)
    progression = [0, 5, 3, 7]
    melody = [0, 7, 12, 10, 3, 7, 14, 12]
    for step in range(64):
        offset = progression[step // 16]
        start = step * beat / 2
        tone(samples, start, beat * .75, root + 24 + offset + melody[step % 8], .07 + intensity * .015)
        if step % 2 == 0:
            tone(samples, start, beat * .8, root + offset, .14)
        if step % 8 == 0:
            for interval in [0, 3, 7]:
                tone(samples, start, beat * 3.8, root + 12 + offset + interval, .035, .08)
        for n in range(round(.085 * RATE)):
            t = n / RATE
            kick = math.sin(math.tau * (60 * t + 7 * (1 - math.exp(-t * 35)))) * math.exp(-t * 50) * .18 if step % 4 == 0 else 0
            hat = randomizer.uniform(-1, 1) * math.exp(-t * 100) * (.025 + .008 * intensity)
            samples[(round(start * RATE) + n) % len(samples)] += kick + hat
    write(name, samples)


for args in [('city', 96, 45, 0), ('battle', 120, 40, 1), ('boss', 144, 38, 2)]:
    loop(*args)
for name, notes in {
    'ui': [72], 'weapon': [48, 43], 'explosion': [38, 33, 28],
    'fusion': [60, 64, 67, 72], 'victory': [60, 64, 67, 72, 79],
    'ability': [48, 60, 72], 'combo': [72, 79], 'overdrive': [48, 60, 67, 72, 84]
}.items():
    samples = [0.] * round((len(notes) * .065 + .18) * RATE)
    for index, note in enumerate(notes):
        tone(samples, index * .065, .17, note, .25, .35)
    write(name, samples)
print('Authored 3 original music loops and 9 sound cues.')
