"""Synthesize original short combat cues. Standard library only; no sampled audio."""
import math
import random
import struct
import wave
from pathlib import Path

RATE = 22050
DEST = Path(__file__).resolve().parents[1] / "apps/nightfall-godot/assets/audio/combat"
CUES = {
    "pistol": (0.15, 140, 0.70, 0.20),
    "scattergun": (0.22, 85, 0.85, 0.12),
    "crossbow": (0.18, 280, 0.35, 0.55),
    "wand": (0.24, 760, 0.05, 0.78),
    "sabre": (0.24, 470, 0.55, 0.26),
    "ember": (0.32, 110, 0.80, 0.15),
    "frost": (0.28, 1250, 0.25, 0.50),
    "chain": (0.18, 150, 0.65, 0.45),
    "wisp": (0.30, 950, 0.03, 0.65),
    "lance": (0.28, 95, 0.75, 0.20),
    "ground": (0.40, 360, 0.08, 0.70),
    "blades": (0.24, 680, 0.40, 0.35),
    "gravity": (0.36, 160, 0.22, 0.70),
    "slam": (0.35, 65, 0.80, 0.25),
    "swipe": (0.19, 210, 0.65, 0.20),
    "spit": (0.18, 240, 0.35, 0.55),
    "summon": (0.38, 220, 0.15, 0.65),
    "impact": (0.09, 190, 0.60, 0.15),
}


def build():
    DEST.mkdir(parents=True, exist_ok=True)
    for index, (name, (duration, frequency, noise_mix, tone_mix)) in enumerate(CUES.items()):
        rng = random.Random(731 + index)
        filtered = 0.0
        phase = 0.0
        data = bytearray()
        for n in range(round(duration * RATE)):
            t = n / RATE
            p = t / duration
            rise = min(1.0, t / (0.018 if name in ["ground", "gravity", "summon"] else 0.003))
            envelope = rise * (1.0 - p) ** (2.8 if name in ["pistol", "impact"] else 1.7)
            filtered = filtered * 0.62 + rng.uniform(-1.0, 1.0) * 0.38
            pitch = frequency * (1.0 - p * 0.58)
            phase += math.tau * pitch / RATE
            tone = math.sin(phase) * 0.75 + math.sin(phase * 2.73) * 0.25
            if name == "chain":
                tone *= math.sin(math.tau * 74 * t)
            value = (filtered * noise_mix + tone * tone_mix) * envelope * 0.62
            data.extend(struct.pack("<h", round(max(-1, min(1, value)) * 32767)))
        with wave.open(str(DEST / (name + ".wav")), "wb") as output:
            output.setnchannels(1)
            output.setsampwidth(2)
            output.setframerate(RATE)
            output.writeframes(data)
    print(f"Generated {len(CUES)} original combat cues in {DEST}")


if __name__ == "__main__":
    build()
