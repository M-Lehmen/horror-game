#!/usr/bin/env python3
"""Deterministische, selbst synthetisierte Audio-Platzhalter, Python 3 + numpy."""
import pathlib, wave
import numpy as np
ROOT = pathlib.Path(__file__).resolve().parents[1] / "assets" / "audio" / "generated"
ROOT.mkdir(parents=True, exist_ok=True)
RATE = 22050
rng = np.random.default_rng(1225)

def save(name, x):
    x = np.asarray(x, dtype=float)
    fade = min(int(RATE * .04), len(x) // 4)
    if fade:
        x[:fade] *= np.linspace(0, 1, fade)
        x[-fade:] *= np.linspace(1, 0, fade)
    pcm = (np.clip(np.tanh(x * 1.3), -1, 1) * 24000).astype("<i2")
    with wave.open(str(ROOT / name), "wb") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(RATE)
        wav.writeframes(pcm.tobytes())

def lp(samples, alpha=.01):
    out = np.empty_like(samples)
    previous = 0.0
    for i, value in enumerate(samples):
        previous = (1 - alpha) * previous + alpha * value
        out[i] = previous
    return out

def time(seconds):
    return np.arange(int(seconds * RATE)) / RATE

t = time(8)
save("wind_ambient.wav", lp(rng.standard_normal(t.size), .013) * 2 * (.65 + .35 * np.sin(t * .7)))
t = time(5)
save("mower_idle.wav", .18 * np.sin(2*np.pi*73*t) + .11*np.sin(2*np.pi*146*t) + .07*np.sin(2*np.pi*219*t) + lp(rng.standard_normal(t.size), .035) * .3)
t = time(4)
phase = 2*np.pi*np.cumsum(38 + 30*np.clip(t/2, 0, 1))/RATE
save("car_engine_start.wav", (.22*np.sin(phase) + .09*np.sin(2*phase) + .04*rng.standard_normal(t.size))*np.clip(t/.75,0,1))
t = time(1)
save("footstep_wood.wav", np.exp(-t*23)*(.24*np.sin(2*np.pi*90*t)+.11*rng.standard_normal(t.size)))
save("footstep_gravel.wav", np.exp(-t*13)*(.13*rng.standard_normal(t.size)+.09*np.sin(2*np.pi*112*t)))
t = time(2)
save("door_creak.wav", np.sin(2*np.pi*(170+65*t+9*np.sin(t*8))*t)*(.16*np.sin(np.pi*np.clip(t/1.7,0,1))**2))
t = time(1)
save("mailbox_clack.wav", np.exp(-t*28)*(.27*rng.standard_normal(t.size)+.15*np.sin(2*np.pi*360*t)))
print("7 WAV-Dateien unter", ROOT)
