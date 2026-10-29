#!/usr/bin/env python3
"""Renders the looping background music to assets/music/loop.wav. No dependencies.

A 16 bar, 118 BPM arcade-style loop in C major: bell melody over a plucky arpeggio, bouncy bass,
soft pad and a light beat. The progression is C G Am F twice, then F G Em Am, then C G F G, which
resolves back to the first chord so the loop is seamless. Notes that ring past the end wrap around
to the start, so there is no click at the seam.

Tweak BPM, the level constants (GAIN_*) or the note tables below, then re-run:
    python3 -I tools/make_music.py
"""
import array
import math
import random
import wave
from pathlib import Path

SR = 44100
BPM = 118
BARS = 16
BEAT = 60.0 / BPM
N = int(round(BARS * 4 * BEAT * SR))
TAU = 2.0 * math.pi
OUT = Path(__file__).resolve().parent.parent / "assets" / "music" / "loop.wav"

GAIN_KICK = 0.55
GAIN_SNARE = 0.26
GAIN_HAT = 0.07
GAIN_BASS = 0.30
GAIN_ARP = 0.17
GAIN_PAD = 0.07
GAIN_BELL = 0.17

rng = random.Random(7)
L = [0.0] * N
R = [0.0] * N


def hz(midi):
    return 440.0 * 2.0 ** ((midi - 69) / 12.0)


def put(samples, start, gain, pan=0.0):
    """Mixes a mono note into the stereo buffers (equal-power pan, wraps around the loop end)."""
    gl = gain * math.cos((pan + 1.0) * math.pi / 4.0)
    gr = gain * math.sin((pan + 1.0) * math.pi / 4.0)
    i = start % N
    for s in samples:
        L[i] += s * gl
        R[i] += s * gr
        i += 1
        if i == N:
            i = 0


# --- Voices: each returns a list of mono samples -----------------------------------------

def kick():
    out, ph = [], 0.0
    for i in range(int(SR * 0.30)):
        t = i / SR
        ph += TAU * (48.0 + 110.0 * math.exp(-t * 30.0)) / SR
        env = math.exp(-t * 8.5) * min(t / 0.002, 1.0)
        out.append(math.sin(ph) * env + rng.uniform(-1, 1) * math.exp(-t * 700.0) * 0.25)
    return out


def snare():
    out, prev = [], 0.0
    for i in range(int(SR * 0.18)):
        t = i / SR
        x = rng.uniform(-1, 1)
        hp = x - prev * 0.75
        prev = x
        tone = math.sin(TAU * 190.0 * t) * math.exp(-t * 30.0) * 0.6
        out.append((hp * math.exp(-t * 24.0) + tone) * min(t / 0.001, 1.0))
    return out


def hat(open_hat=False):
    length, decay = (0.12, 28.0) if open_hat else (0.05, 95.0)
    out, prev = [], 0.0
    for i in range(int(SR * length)):
        t = i / SR
        x = rng.uniform(-1, 1)
        out.append((x - prev * 0.9) * math.exp(-t * decay))
        prev = x
    return out


def bass(midi, beats):
    f, dur = hz(midi), beats * BEAT + 0.05
    out, ph = [], 0.0
    for i in range(int(SR * dur)):
        t = i / SR
        ph += TAU * f / SR
        wave_ = math.sin(ph) + 0.45 * math.sin(2 * ph) + 0.22 * math.sin(3 * ph)
        env = min(t / 0.006, 1.0) * math.exp(-t * 2.8)
        release = min(1.0, max(0.0, (dur - t) / 0.04))
        out.append(wave_ * env * release * 0.55)
    return out


def pluck(midi):
    f = hz(midi)
    out, ph = [], 0.0
    for i in range(int(SR * 0.26)):
        t = i / SR
        ph += TAU * f / SR
        wave_ = math.sin(ph) + 0.4 * math.sin(2 * ph) + 0.2 * math.sin(3 * ph)
        out.append(wave_ * min(t / 0.003, 1.0) * math.exp(-t * 15.0))
    return out


def pad(midi, beats):
    f, length = hz(midi), beats * BEAT + 0.35
    out, ph1, ph2 = [], 0.0, 0.0
    for i in range(int(SR * length)):
        t = i / SR
        ph1 += TAU * f * 1.003 / SR
        ph2 += TAU * f * 0.997 / SR
        wave_ = (math.sin(ph1) + math.sin(ph2)) * 0.5 + 0.15 * math.sin(2 * ph1)
        env = min(t / 0.22, 1.0) * min(1.0, max(0.0, (length - t) / 0.30))
        out.append(wave_ * env)
    return out


def bell(midi, beats):
    f = hz(midi)
    out, ph = [], 0.0
    for i in range(int(SR * min(beats * BEAT + 0.7, 1.4))):
        t = i / SR
        ph += TAU * f / SR
        wave_ = (math.sin(ph) + 0.35 * math.sin(2.0 * ph) * math.exp(-t * 6.0)
                 + 0.12 * math.sin(3.01 * ph) * math.exp(-t * 10.0))
        out.append(wave_ * min(t / 0.003, 1.0) * math.exp(-t * 3.4))
    return out


# --- Score ----------------------------------------------------------------------------------

# name: (bass root, bass fifth, arpeggio notes, pad notes)
CHORDS = {
    "C":  (48, 55, [60, 64, 67, 72], [55, 60, 64]),
    "G":  (43, 50, [59, 62, 67, 71], [55, 59, 62]),
    "Am": (45, 52, [57, 60, 64, 69], [57, 60, 64]),
    "F":  (41, 48, [57, 60, 65, 69], [53, 57, 60]),
    "Em": (40, 47, [59, 64, 67, 71], [55, 59, 64]),
}
PROG = ["C", "G", "Am", "F", "C", "G", "Am", "F",
        "F", "G", "Em", "Am", "C", "G", "F", "G"]
ARP_PATTERN = [0, 1, 2, 3, 2, 1, 2, 3, 0, 1, 2, 3, 2, 3, 2, 1]
# bar: [(beat, midi note, length in beats)]
MELODY = {
    4: [(0, 76, 1.0), (1.0, 79, 0.5), (1.5, 76, 0.5), (2.0, 74, 1.0), (3.0, 72, 1.0)],
    5: [(0, 74, 1.0), (1.0, 79, 0.5), (1.5, 77, 0.5), (2.0, 74, 1.0), (3.0, 71, 1.0)],
    6: [(0, 72, 1.0), (1.0, 76, 0.5), (1.5, 81, 0.5), (2.0, 79, 1.0), (3.0, 76, 1.0)],
    7: [(0, 77, 1.0), (1.0, 81, 0.5), (1.5, 79, 0.5), (2.0, 77, 1.0), (3.0, 76, 1.0)],
    8: [(0, 81, 1.5), (1.5, 79, 0.5), (2.0, 77, 1.0), (3.0, 81, 1.0)],
    9: [(0, 83, 1.5), (1.5, 81, 0.5), (2.0, 79, 1.0), (3.0, 74, 1.0)],
    10: [(0, 79, 1.0), (1.0, 83, 1.0), (2.0, 88, 1.5), (3.5, 86, 0.5)],
    11: [(0, 84, 1.0), (1.0, 83, 0.5), (1.5, 81, 0.5), (2.0, 76, 2.0)],
    12: [(0, 76, 1.0), (1.0, 79, 0.5), (1.5, 76, 0.5), (2.0, 74, 1.0), (3.0, 72, 1.0)],
    13: [(0, 74, 1.0), (1.0, 79, 0.5), (1.5, 77, 0.5), (2.0, 74, 1.0), (3.0, 71, 1.0)],
    14: [(0, 77, 1.0), (1.0, 81, 0.5), (1.5, 84, 0.5), (2.0, 81, 1.0), (3.0, 77, 1.0)],
    15: [(0, 74, 0.5), (0.5, 77, 0.5), (1.0, 79, 1.0), (2.0, 83, 1.0), (3.0, 86, 1.0)],
}


def render():
    kick_s, snare_s = kick(), snare()
    hat_s, open_hat_s = hat(), hat(True)
    for bar, name in enumerate(PROG):
        root, fifth, arp, pad_notes = CHORDS[name]
        t0 = bar * 4 * BEAT

        def at(beat):
            return int(round((t0 + beat * BEAT) * SR))

        # Drums build up: nothing for 2 bars, half-time kick, then the full beat.
        if bar >= 4:
            for b in range(4):
                put(kick_s, at(b), GAIN_KICK)
            for b in (1, 3):
                put(snare_s, at(b), GAIN_SNARE)
        elif bar >= 2:
            for b in (0, 2):
                put(kick_s, at(b), GAIN_KICK * 0.9)
        if bar >= 2:
            for b in range(4):
                put(hat_s, at(b + 0.5), GAIN_HAT, 0.25 if b % 2 else -0.25)
            if bar >= 4:
                put(open_hat_s, at(3.5), GAIN_HAT * 0.8, 0.25)
        if 8 <= bar < 12:
            for s in range(16):
                if s % 2:
                    put(hat_s, at(s * 0.25), GAIN_HAT * 0.5, -0.25 if (s // 2) % 2 else 0.25)

        # Bass: bouncy root, octave, fifth.
        for beat, midi, beats in ((0.0, root, 1.4), (1.5, root, 0.4), (2.0, root + 12, 0.4), (3.0, fifth, 0.9)):
            put(bass(midi, beats), at(beat), GAIN_BASS)

        # Arpeggio, quieter in the intro bars.
        arp_gain = GAIN_ARP * (0.65 if bar < 2 else 1.0)
        for s, idx in enumerate(ARP_PATTERN):
            put(pluck(arp[idx]), at(s * 0.25), arp_gain, -0.35 if s % 2 else 0.35)

        # Pad: the whole chord, spread across the stereo field.
        for midi, pan in zip(pad_notes, (-0.3, 0.0, 0.3)):
            put(pad(midi, 4), at(0), GAIN_PAD, pan)

        for beat, midi, beats in MELODY.get(bar, []):
            put(bell(midi, beats), at(beat), GAIN_BELL, 0.1)


def write():
    peak = max(max(abs(x) for x in L), max(abs(x) for x in R))
    # Soft-clip the loudest hits, then normalise to a safe peak.
    drive = 1.2 / max(peak, 1e-9)
    out = array.array("h")
    soft_peak = math.tanh(1.2)
    for l, r in zip(L, R):
        out.append(int(math.tanh(l * drive) / soft_peak * 0.9 * 32767))
        out.append(int(math.tanh(r * drive) / soft_peak * 0.9 * 32767))
    OUT.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(OUT), "wb") as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(out.tobytes())
    rms = math.sqrt(sum(s * s for s in out) / len(out)) / 32767
    print("wrote %s: %.1f s, peak %.2f, rms %.3f (%.1f dBFS)" % (
        OUT, N / SR, max(abs(s) for s in out) / 32767, rms, 20 * math.log10(rms)))


if __name__ == "__main__":
    render()
    write()
