#!/usr/bin/env python3
"""Regenerates data/levels.json.

Levels 0 to 11 are hand-made and are kept exactly as they are in the file. Everything after
them is generated with a difficulty ramp: more targets and boards, faster blinking and sliding.
Progress is never time-gated, so a hard level only costs the player time, not access.

Usage: python3 -I tools/gen_levels.py [total_levels]   (default 200)
"""
import json
import sys
from pathlib import Path

PATH = Path(__file__).resolve().parent.parent / "data" / "levels.json"
HAND_MADE = 12

# Card names are one line at 20 px, so every "<adjective> <noun>" stays within 12 characters.
ADJECTIVES = ["Easy", "Quick", "Sharp", "Bold", "Wild", "Swift", "Slick", "Tough", "Crazy", "Turbo",
              "Epic", "Fast", "Hot", "Mad", "Fiery", "Brave", "Grand", "Super", "Ultra", "Mega"]
NOUNS = {
    "static": ["Pop", "Burst", "Rush", "Sprint"],
    "flash": ["Blink", "Flash", "Strobe", "Pulse"],
    "move": ["Slide", "Chase", "Drift", "Dash"],
    "flash_move": ["Mix", "Frenzy", "Storm", "Chaos"],
}
# Repeating pattern of (mode, multi_board). Multi-board levels come later in each cycle.
CYCLE = [("static", False), ("flash", False), ("move", False),
         ("flash_move", False), ("static", True), ("flash_move", True)]


def lerp(a, b, t):
    return a + (b - a) * t


def tens(x):
    return int(round(x / 10.0)) * 10


def make_level(level_id, k, span):
    p = min(k / span, 1.0)
    mode, multi = CYCLE[k % len(CYCLE)]
    if multi:
        boards = 2 if p < 0.3 else 3 if p < 0.65 else 4
        targets = round(lerp(4, 8, p))
    else:
        boards = 1
        targets = round(lerp(5, 10, p))
    level = {
        "id": level_id,
        "name": "%s %s" % (ADJECTIVES[(k * 7) % len(ADJECTIVES)], NOUNS[mode][(k // len(CYCLE)) % 4]),
        "detail": detail(mode, boards, targets),
        "subtitle": subtitle(mode, boards),
        "targets": targets,
        "boards": boards,
        "mode": mode,
    }
    if mode in ("flash", "flash_move"):
        level["flash_ms"] = tens(lerp(850, 500, p))
    if mode in ("move", "flash_move"):
        level["move_ms"] = tens(lerp(1200, 650, p))
    assert len(level["name"]) <= 12, level["name"]
    assert len(level["detail"]) <= 19, level["detail"]
    return level


def detail(mode, boards, targets):
    if mode == "static":
        return "%d targets" % targets if boards == 1 else "%d boards, %d each" % (boards, targets)
    word = {"flash": "Blink", "move": "Slide", "flash_move": "Mixed"}[mode]
    if boards == 1:
        return {"flash": "Blinking targets", "move": "Sliding targets", "flash_move": "Blink and slide"}[mode]
    return "%s, %d boards" % (word, boards)


def subtitle(mode, boards):
    if mode == "static":
        return "Pop the ringed bubbles" if boards == 1 else "Clear %d boards, one timer" % boards
    if boards == 1:
        return {"flash": "Targets blink on and off", "move": "Targets slide around",
                "flash_move": "Targets blink and slide"}[mode]
    word = {"flash": "Blinking", "move": "Sliding", "flash_move": "Blink and slide"}[mode]
    return "%s, %d boards" % (word, boards)


def main():
    total = int(sys.argv[1]) if len(sys.argv) > 1 else 200
    levels = json.loads(PATH.read_text())[:HAND_MADE]
    assert len(levels) == HAND_MADE, "levels.json must keep its %d hand-made levels" % HAND_MADE
    span = max(total - HAND_MADE - 1, 1)
    for level_id in range(HAND_MADE, total):
        levels.append(make_level(level_id, level_id - HAND_MADE, span))
    lines = ",\n".join("  " + json.dumps(l) for l in levels)
    PATH.write_text("[\n%s\n]\n" % lines)
    print("wrote %d levels to %s" % (len(levels), PATH))


if __name__ == "__main__":
    main()
