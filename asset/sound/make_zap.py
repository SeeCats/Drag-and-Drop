"""Generates zap.wav next to this script. Run: python make_zap.py"""
import numpy as np
import wave
import struct
import os

SR = 44100
DUR = 0.45  # seconds

t = np.linspace(0, DUR, int(SR * DUR), endpoint=False)

# Pitch sweeps down fast — that's the "zap"
freq = 1800 * np.exp(-8 * t) + 120
phase = 2 * np.pi * np.cumsum(freq) / SR
tone = np.sign(np.sin(phase))                    # square wave for harshness
tone += 0.5 * np.sin(phase * 2.01)               # detuned overtone

# Crackle: high-pass-ish noise that decays
noise = np.random.uniform(-1, 1, len(t))
noise = np.diff(noise, prepend=0)                # crude high-pass
crackle = noise * np.exp(-6 * t) * 0.9

# A few sharp tick transients early on
ticks = np.zeros_like(t)
for tick_time in [0.0, 0.04, 0.09, 0.14]:
    idx = int(tick_time * SR)
    if idx < len(ticks):
        env = np.exp(-300 * (t[idx:] - tick_time))
        ticks[idx:] += env * (np.random.uniform(-1, 1, len(env)))

# Mix + envelope
sig = 0.55 * tone + 0.7 * crackle + 0.4 * ticks
attack = np.clip(t / 0.003, 0, 1)                 # 3ms attack
decay = np.exp(-5.5 * t)
sig *= attack * decay

# Normalize
sig = sig / np.max(np.abs(sig)) * 0.9
samples = (sig * 32767).astype(np.int16)

out_path = os.path.join(os.path.dirname(__file__), "zap.wav")
with wave.open(out_path, "wb") as w:
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(SR)
    w.writeframes(samples.tobytes())

print(f"Wrote {out_path}")
