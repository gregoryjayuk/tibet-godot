#!/usr/bin/env python3
"""The slice's synthetic sounds, rendered offline to files (plan chapter 10, 11.6: "everything is rendered to files
first"; M1 sprint 8, step 1). Stand-ins for what recordings will replace: the valley wind at three strengths (SND-011),
a mountain torrent (SND-001, SND-003), juniper crackling on a burner (SND-024). (The murmur of voices it made, SND-501
and SND-502, was dropped at Greg's word, 27 Sep 2026.) Marked placeholders for sacred sound until it is recorded
with consent (chapter 10, 11.5): the dawn and dusk horns (SND-103, SND-104, the synthesis world/dusk.gd made at run
time), the conch (SND-101). And the great wheel's bell (SND-127's bell, the tone world/great_wheel.gd made), tea poured into a bowl (SND-604), a chough's call (SND-414), prayer flags in the wind (SND-013) a mastiff's bark (SND-408) and a wall wheel's squeak (SND-128) and a spring's spout (SND-009), a French clock's tick (SND-239) and the pieman's dice (SND-303), a water mill at work (SND-215), a water prayer wheel's small bell (SND-130), a woodcutter's axe (SND-216), the Parkhang's printers (SND-211), a pilgrim's rosary (SND-117), the gorge's flag spans (SND-015), the Gönkhang's drum (SND-111) and the walker's breath when winded (SND-603).

Masters go to audio_src/synth/ (48 kHz, 16-bit; never imported: audio_src/ has a .gdignore); tools/audio/process.py
levels them into audio/. Seeded, so a run makes the same files. A loop is rendered long and its tail crossfaded into
its head, so it joins without a click; its WAV carries the loop (tools/audio/wav.py).
Run: tools/py tools/audio/synth.py
"""
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from wav import write_wav  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "audio_src", "synth")
SR = 48000


# --- building blocks ---------------------------------------------------------------------------------------------

def white(n, rng):
    return rng.standard_normal(n)


def shaped(n, rng, gain):
    """Noise with a spectrum shaped by gain(f) (f in Hz, an array), done in one FFT."""
    spec = np.fft.rfft(rng.standard_normal(n))
    f = np.fft.rfftfreq(n, 1.0 / SR)
    out = np.fft.irfft(spec * gain(np.maximum(f, 1.0)), n)
    return out / (np.std(out) + 1e-12)


def pink(f):
    return 1.0 / np.sqrt(f)


def band(lo, hi, slope=4.0):
    """A soft band-pass: flat between lo and hi, falling `slope` orders a decade outside."""
    return lambda f: 1.0 / (1.0 + (lo / f) ** slope) / (1.0 + (f / hi) ** slope)


def smooth_random(n, rng, rates, seconds):
    """A slow random curve in 0..1: a few sines at the given rates (Hz) with random phases, normalised."""
    t = np.arange(n) / SR
    y = np.zeros(n)
    for r in rates:
        y += np.sin(2 * np.pi * r * t + rng.uniform(0, 2 * np.pi)) * rng.uniform(0.5, 1.0)
    y -= y.min()
    return y / (y.max() + 1e-12)


def loop_join(x, fade):
    """A loop: the last `fade` samples crossfaded (equal power) into the first, and dropped."""
    body, tail = x[:-fade].copy(), x[-fade:]
    k = np.linspace(0.0, 1.0, fade)
    head = body[:fade] if body.ndim == 1 else body[:fade, :]
    if body.ndim == 1:
        body[:fade] = head * np.sin(k * np.pi / 2) + tail * np.cos(k * np.pi / 2)
    else:
        body[:fade, :] = head * np.sin(k * np.pi / 2)[:, None] + tail * np.cos(k * np.pi / 2)[:, None]
    return body


def fade_ends(x, a=0.01, b=0.05):
    na, nb = int(a * SR), int(b * SR)
    x = x.copy()
    x[:na] *= np.linspace(0, 1, na) if x.ndim == 1 else np.linspace(0, 1, na)[:, None]
    x[-nb:] *= np.linspace(1, 0, nb) if x.ndim == 1 else np.linspace(1, 0, nb)[:, None]
    return x


def norm(x, peak=0.5):
    return x * (peak / (np.max(np.abs(x)) + 1e-12))


# --- the sounds --------------------------------------------------------------------------------------------------

def wind(strength, seconds=64.0, seed=11):
    """SND-011: the valley's wind, low with gusts: a rumble under a whoosh that swells with each gust; the strong one
    whistles as it gusts. Stereo: the two channels' noise is different, their gusts the same."""
    rng = np.random.default_rng(seed + {"low": 0, "mid": 1, "high": 2}[strength])
    n = int(seconds * SR)
    g = smooth_random(n, rng, [0.021, 0.047, 0.083, 0.13, 0.19], seconds)
    g = g ** (1.4 if strength == "low" else 1.8)
    s = {"low": 0.35, "mid": 0.7, "high": 1.0}[strength]
    chans = []
    for c in range(2):
        rumble = shaped(n, rng, lambda f: band(20, 180, 3)(f) / f ** 0.8)
        whoosh = shaped(n, rng, lambda f: band(250, 1400 + 900 * s, 2.5)(f) * pink(f))
        x = rumble * (0.55 + 0.45 * g) * (0.7 - 0.2 * s) + whoosh * (0.12 + 0.9 * g) * s
        if strength == "high":
            whistle = shaped(n, rng, band(820, 980, 8))
            x += whistle * 0.35 * g ** 3
        chans.append(x)
    x = np.stack(chans, axis=1)
    return norm(loop_join(x, int(4.0 * SR)))


def torrent(seconds=64.0, seed=21):
    """SND-001/SND-003 stand-in: a steep mountain stream over stones: a low rumble, broadband hiss, and a babble of
    small bubbles. Mono, for a 3D line emitter."""
    rng = np.random.default_rng(seed)
    n = int(seconds * SR)
    rumble = shaped(n, rng, lambda f: band(25, 160, 3)(f) / f ** 0.5)
    hiss = shaped(n, rng, lambda f: band(350, 7000, 2)(f) * pink(f) ** 0.6)
    babble = np.zeros(n)
    t_ev = np.cumsum(rng.exponential(1.0 / 70.0, int(seconds * 90)))
    t_ev = t_ev[t_ev < seconds - 0.1]
    for t0 in t_ev:
        f0 = rng.uniform(380, 1900)
        d = rng.uniform(0.008, 0.035)
        m = int(d * SR)
        tt = np.arange(m) / SR
        f = f0 * (1.0 + 0.9 * tt / d)  # a bubble's note rises as it closes
        seg = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-tt / (d * 0.35)) * rng.uniform(0.2, 1.0)
        i = int(t0 * SR)
        babble[i:i + m] += seg
    babble /= np.std(babble) + 1e-12
    swell = 0.85 + 0.15 * smooth_random(n, rng, [0.05, 0.11, 0.23], seconds)
    x = (rumble * 0.55 + hiss * 0.45 + babble * 0.22) * swell
    return norm(loop_join(x, int(3.0 * SR)))


def spout(seconds=20.0, seed=410):
    """SND-009 stand-in: a spring's wooden spout falling a hand's breadth into a shallow stone basin (the Lukhang spring,
    SHL-14): a steady bright splash, the flutter of a thin stream, small bubbles bursting high, no rumble. Mono, for a
    point emitter at the spout's mouth."""
    rng = np.random.default_rng(seed)
    n = int(seconds * SR)
    splash = shaped(n, rng, lambda f: band(600, 9000, 2)(f) * pink(f) ** 0.4)
    flutter_ = 0.75 + 0.25 * smooth_random(n, rng, [3.1, 5.3, 8.7], seconds)  # the stream breaking up as it falls
    babble = np.zeros(n)
    t_ev = np.cumsum(rng.exponential(1.0 / 110.0, int(seconds * 140)))
    t_ev = t_ev[t_ev < seconds - 0.05]
    for t0 in t_ev:
        f0 = rng.uniform(1100, 3400)
        d = rng.uniform(0.004, 0.018)
        m = int(d * SR)
        tt = np.arange(m) / SR
        f = f0 * (1.0 + 1.2 * tt / d)
        seg = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-tt / (d * 0.3)) * rng.uniform(0.15, 1.0)
        i = int(t0 * SR)
        babble[i:i + m] += seg
    babble /= np.std(babble) + 1e-12
    x = splash * flutter_ * 0.6 + babble * 0.3
    return norm(loop_join(x, int(2.0 * SR)))


def juniper(seconds=24.0, seed=41):
    """SND-024: green juniper on a burner: a low breathing roar, a hiss of sap, and crackles in bursts. Mono."""
    rng = np.random.default_rng(seed)
    n = int(seconds * SR)
    roar = shaped(n, rng, lambda f: band(30, 320, 3)(f) / f ** 0.3) * (0.6 + 0.4 * smooth_random(n, rng, [0.3, 0.7, 1.3], seconds))
    hiss = shaped(n, rng, band(2500, 9000, 2)) * (0.3 + 0.7 * smooth_random(n, rng, [0.4, 0.9, 2.1], seconds))
    crack = np.zeros(n)
    t0 = 0.0
    while t0 < seconds - 0.1:
        t0 += rng.exponential(0.16)
        for _ in range(rng.integers(1, 5)):  # a pop and its echoes of sap
            m = int(rng.uniform(0.001, 0.006) * SR)
            k = rng.standard_normal(m) * np.exp(-np.arange(m) / (m * 0.3)) * rng.uniform(0.3, 1.0)
            i = int((t0 + rng.uniform(0, 0.03)) * SR)
            if i + m < n:
                crack[i:i + m] += k
    crack = np.fft.irfft(np.fft.rfft(crack) * band(700, 12000, 1.5)(np.maximum(np.fft.rfftfreq(n, 1.0 / SR), 1.0)), n)
    crack /= np.std(crack) + 1e-12
    x = roar * 0.35 + hiss * 0.12 + crack * 0.5
    return norm(loop_join(x, int(2.0 * SR)))


def hearth(seconds=30.0, seed=101):
    """SND-025 stand-in: a kitchen's clay stove (chapter 04, 6.2; chapter 10, SND-025: hearth, stove draw, pine
    splinters): the draw, a low steady breathing roar in the flue; dry wood crackling, sparser and sharper than the
    juniper's sap; a little hiss of pine splinters; now and then an ember settling, a soft knock. Mono."""
    rng = np.random.default_rng(seed)
    n = int(seconds * SR)
    draw = shaped(n, rng, lambda f: band(25, 220, 3)(f) / f ** 0.2) * (0.75 + 0.25 * smooth_random(n, rng, [0.15, 0.4, 0.9], seconds))
    hiss = shaped(n, rng, band(3000, 8000, 2)) * (0.15 + 0.85 * smooth_random(n, rng, [0.2, 0.5, 1.1], seconds) ** 2)
    crack = np.zeros(n)
    t0 = 0.0
    while t0 < seconds - 0.1:
        t0 += rng.exponential(0.55)  # dry wood: a crack every half second or so, now and then a few together
        for _ in range(1 if rng.random() < 0.7 else rng.integers(2, 4)):
            m = int(rng.uniform(0.0008, 0.004) * SR)
            k = rng.standard_normal(m) * np.exp(-np.arange(m) / (m * 0.25)) * rng.uniform(0.2, 1.0)
            i = int((t0 + rng.uniform(0, 0.05)) * SR)
            if i + m < n:
                crack[i:i + m] += k
    crack = np.fft.irfft(np.fft.rfft(crack) * band(900, 11000, 1.5)(np.maximum(np.fft.rfftfreq(n, 1.0 / SR), 1.0)), n)
    crack /= np.std(crack) + 1e-12
    settle = np.zeros(n)
    t0 = rng.uniform(2.0, 6.0)
    while t0 < seconds - 1.0:  # an ember settling: a soft low knock and a rustle of ash
        m = int(0.12 * SR)
        k = np.sin(2 * np.pi * rng.uniform(70, 110) * np.arange(m) / SR) * np.exp(-np.arange(m) / (0.03 * SR))
        k += 0.3 * rng.standard_normal(m) * np.exp(-np.arange(m) / (0.05 * SR))
        i = int(t0 * SR)
        settle[i:i + m] += k * rng.uniform(0.4, 0.9)
        t0 += rng.uniform(6.0, 12.0)
    x = draw * 0.5 + hiss * 0.05 + crack * 0.3 + settle * 0.35
    return norm(loop_join(x, int(2.0 * SR)))


def hand_wheel(seconds=10.0, seed=111, rate=1.4):
    """SND-129 stand-in: a hand prayer wheel turning (chapter 10: hand wheel whirr and weight click): the drum's soft whirr
    in the air, swelling and easing once a turn, and the weight's chain ticking as it comes round; `rate` turns a second,
    as the game turns it (characters/hand_wheel.gd), and a whole number of turns, so the loop keeps the beat. Mono."""
    rng = np.random.default_rng(seed)
    turns = max(1, round(seconds * rate))
    n = int(turns / rate * SR)
    t = np.arange(n) / SR
    whirr = shaped(n, rng, band(250, 2200, 2)) * (0.45 + 0.55 * np.sin(np.pi * rate * t) ** 2)
    tick = np.zeros(n)
    for k in range(turns):
        i = int((k / rate + 0.31 / rate + rng.uniform(-0.008, 0.008)) * SR)
        m = int(0.003 * SR)
        if i + m < n:
            tick[i:i + m] += rng.standard_normal(m) * np.exp(-np.arange(m) / (m * 0.2)) * rng.uniform(0.6, 1.0)
    tick = np.fft.irfft(np.fft.rfft(tick) * band(2500, 9000, 1.5)(np.maximum(np.fft.rfftfreq(n, 1.0 / SR), 1.0)), n)
    tick /= np.std(tick) + 1e-12
    x = whirr * 0.6 + tick * 0.12
    return norm(fade_ends(x, 0.002, 0.002))


def pluck(freq, seconds, rng, bright=0.6, decay=0.9965):
    """A plucked string (Karplus-Strong): a burst of noise, soft or bright, through a delay a period long that averages
    each pass, so the high partials die first."""
    n = int(seconds * SR)
    N = max(2, int(round(SR / freq)))
    burst = rng.uniform(-1.0, 1.0, N)
    if bright < 1.0:  # a softer pick: the burst smoothed
        k = max(1, int((1.0 - bright) * 6))
        burst = np.convolve(burst, np.ones(k) / k, mode="same")
    out = np.zeros(n)
    out[:min(N, n)] = burst[:min(N, n)]
    i = N
    while i < n:
        seg = out[i - N:i]
        nxt = decay * 0.5 * (seg + np.concatenate((seg[1:], seg[:1])))
        m = min(N, n - i)
        out[i:i + m] = nxt[:m]
        i += m
    return out


def dranyen(seed=229, bars=8, eighth=0.2):
    """SND-229 stand-in (chapter 10: "a bright, plucked, strummed sound with drone strings"; to be played and recorded):
    the long-necked lute at the chang house from 19:00, a 6/8 figure of eight bars: on each bar's first and fourth
    eighth a strum of the three courses with the drone on D, between them the melody on the top course; the body's
    wooden resonance a soft band over 250-1800 Hz. A loop of a whole number of bars. Mono."""
    rng = np.random.default_rng(seed)
    n = int(bars * 6 * eighth * SR)
    x = np.zeros(n + int(2.0 * SR))
    D, A = 146.83, 220.0
    scale = [293.66, 329.63, 392.0, 440.0, 493.88, 587.33]  # D E G A B D', the top course's notes
    tune = [[0, 2, 3], [3, 2, 1], [0, 1, 2], [2, 1, 0], [3, 4, 3], [2, 3, 1], [0, 2, 1], [1, 0, 0]]  # per bar: on 1, 3 and 6
    for b in range(bars):
        t0 = b * 6 * eighth
        for beat, strum in ((0, True), (3, True)):
            at = t0 + beat * eighth + rng.uniform(-0.008, 0.008)
            for k, f in enumerate((D, A, D * 2)):  # the strum: the three courses a few milliseconds apart
                i = int((at + 0.012 * k) * SR)
                y = pluck(f * (1.0 + rng.uniform(-0.002, 0.002)), 1.6, rng, bright=0.7) * (0.5 if beat else 0.65)
                x[i:i + y.size] += y[:max(0, min(y.size, x.size - i))]
        for slot, beat in enumerate((1, 2, 5)):  # the melody between the strums
            at = t0 + beat * eighth + rng.uniform(-0.01, 0.01)
            f = scale[tune[b % len(tune)][slot]]
            i = int(at * SR)
            y = pluck(f, 1.1, rng, bright=0.85, decay=0.994) * rng.uniform(0.55, 0.75)
            x[i:i + y.size] += y[:max(0, min(y.size, x.size - i))]
    body = np.fft.irfft(np.fft.rfft(x) * band(250, 1800, 1.5)(np.maximum(np.fft.rfftfreq(x.size, 1.0 / SR), 1.0)), x.size)
    y = 0.6 * x + 0.8 * body / (np.std(body) + 1e-12) * np.std(x)
    head = y[:n].copy()
    head[:y.size - n] += y[n:]  # the last notes' ring carried round to the loop's head
    return norm(head)


def clock(seed=239, beats=16, beat=0.5):
    """SND-239 stand-in (chapter 04, 4.3: of Dolkar's five French clocks the one she winds at dusk "ticks for an hour"):
    a French drum movement's half-second beat, the tick and the tock a little apart in pitch and loudness, each a click
    of filtered noise and the case's brief ring (two partials, 25-40 ms), its escapement not quite even. A loop of
    whole beats. Mono."""
    rng = np.random.default_rng(seed)
    n = int(beats * beat * SR)
    x = np.zeros(n + SR)
    t = np.arange(int(0.08 * SR)) / SR
    for k in range(beats):
        at = k * beat + (0.006 if k % 2 else 0.0) + rng.uniform(0.0, 0.003)  # the tock a hair late: not in beat
        f0 = (3150.0, 2650.0)[k % 2] * rng.uniform(0.99, 1.01)
        ring = (np.sin(2 * np.pi * f0 * t) * np.exp(-t / 0.028) + 0.5 * np.sin(2 * np.pi * f0 * 1.71 * t) * np.exp(-t / 0.016)) * 0.6
        click = rng.standard_normal(t.size) * np.exp(-t / 0.0012)
        y = (ring + click) * (1.0 if k % 2 == 0 else 0.78) * rng.uniform(0.92, 1.0)
        i = int(at * SR)
        x[i:i + y.size] += y
    head = x[:n].copy()
    head[:x.size - n] += x[n:]
    return norm(head, 0.5)


def dice(seed):
    """SND-303 stand-in (chapter 04, 4.3: "all day long the rattle of the dice could be heard without ceasing", Gill at
    Dartsedo; chapter 10's pieman's dice in a cup): three bone dice shaken in a wooden cup, a quick run of knocks against
    its wall, then the cup slapped down on the board and a die or two clattering out. A one-shot. Mono."""
    rng = np.random.default_rng(seed)
    n = int(1.6 * SR)
    x = np.zeros(n)
    t = np.arange(int(0.03 * SR)) / SR
    def knock(at, f, amp, decay):
        y = (np.sin(2 * np.pi * f * t) * np.exp(-t / decay) + rng.standard_normal(t.size) * np.exp(-t / 0.0008) * 0.6) * amp
        i = int(at * SR)
        x[i:i + y.size] += y[:max(0, min(y.size, n - i))]
    shake = rng.uniform(0.45, 0.7)
    k = rng.integers(14, 24)
    for j in range(k):  # the shake: the dice against the cup's wall, faster as it goes
        at = shake * (j / k) ** 0.9 + rng.uniform(-0.01, 0.01)
        knock(max(0.0, at), rng.uniform(1600.0, 2600.0), rng.uniform(0.25, 0.55), 0.004)
    slap = shake + rng.uniform(0.08, 0.16)
    tt = np.arange(int(0.12 * SR)) / SR  # the cup down on the board: a dull wooden thump
    thump = (np.sin(2 * np.pi * 180.0 * tt) * np.exp(-tt / 0.03) + rng.standard_normal(tt.size) * np.exp(-tt / 0.004) * 0.5)
    i = int(slap * SR)
    x[i:i + thump.size] += thump[:n - i]
    for j in range(rng.integers(1, 4)):  # the dice that roll out, bouncing to rest
        at = slap + 0.03 + j * 0.05 + rng.uniform(0.0, 0.03)
        for b in range(rng.integers(2, 4)):
            knock(at + b * rng.uniform(0.035, 0.06) * (0.8 ** b), rng.uniform(2200.0, 3400.0), 0.35 * 0.6 ** b, 0.003)
    return norm(fade_ends(x, 0.002, 0.05), 0.6)


def bells(seed=230, seconds=9.6, stride=1.15):
    """SND-402 stand-in (chapter 06, 7.4: the lead yak's big iron bell; chapter 10's caravan bells; ISS-083, until they
    are recorded): the lead's iron bell, a dull clank of inharmonic partials struck once each stride as its neck swings,
    a little early or late, its clapper sometimes catching twice; under it the file's small bells, brighter and quieter,
    out of step with it and each other. A loop of whole strides. Mono."""
    rng = np.random.default_rng(seed)
    n = int(seconds * SR)
    x = np.zeros(n + int(2.0 * SR))
    t = np.arange(int(1.4 * SR)) / SR

    def clank(f0, partials, decay, amp):
        y = np.zeros_like(t)
        for k, (ratio, a, d) in enumerate(partials):
            f = f0 * ratio * (1.0 + rng.uniform(-0.004, 0.004))
            y += a * np.sin(2 * np.pi * f * t + rng.uniform(0, 6.28)) * np.exp(-t * decay * d)
        y[:int(0.002 * SR)] *= np.linspace(0.0, 1.0, int(0.002 * SR))
        return amp * y

    iron = [(1.0, 1.0, 1.0), (2.32, 0.55, 1.4), (3.86, 0.35, 2.0), (5.41, 0.2, 2.8), (6.95, 0.12, 3.5)]
    small = [(1.0, 1.0, 1.0), (2.76, 0.4, 1.6), (5.4, 0.18, 2.4)]
    n_strides = int(round(seconds / stride))
    for k in range(n_strides):
        at = max(0.0, k * (seconds / n_strides) + rng.uniform(-0.05, 0.05))  # (a stroke before the loop's head would slice from its end)
        i = int(at * SR)
        y = clank(rng.uniform(395.0, 410.0), iron, 5.5, rng.uniform(0.7, 1.0))
        x[i:i + y.size] += y[:max(0, min(y.size, x.size - i))]
        if rng.random() < 0.3:  # the clapper catching twice
            j = i + int(rng.uniform(0.07, 0.12) * SR)
            y = clank(402.0, iron, 7.0, 0.35)
            x[j:j + y.size] += y[:max(0, min(y.size, x.size - j))]
    for b in range(4):  # the small bells further down the file, out of step
        period = rng.uniform(1.05, 1.35)
        f0 = rng.uniform(980.0, 1480.0)
        at = rng.uniform(0.0, period)
        while at < seconds:
            i = int(at * SR)
            y = clank(f0, small, 9.0, rng.uniform(0.12, 0.22))
            x[i:i + y.size] += y[:max(0, min(y.size, x.size - i))]
            at += period + rng.uniform(-0.1, 0.1)
    head = x[:n].copy()
    head[:x.size - n] += x[n:]  # the last clanks' ring carried round to the loop's head
    return norm(head)


def horns(calls, seed=51):
    """SND-103/SND-104 PLACEHOLDER (chapter 10, 11.6: marked temporary until a consented recording): two long horns a
    little apart in pitch on a low C, calls that swell, hold with a slow beat and a growl, and die, the note rising at
    each call's end: world/dusk.gd's synthesis, at 48 kHz."""
    table_n = 2048
    ph = 2 * np.pi * np.arange(table_n) / table_n
    table = sum(np.sin(ph * k) / k ** 0.75 * (1.0 if k % 2 == 1 else 0.8) for k in range(1, 13)) / 3.2
    total = max(s + l for s, l in calls) + 2.0
    n = int(total * SR)
    t = np.arange(n) / SR
    env = np.zeros(n)
    bend = np.zeros(n)
    for c0, cl in calls:
        s = t - c0
        on = (s >= 0) & (s < cl + 1.2)
        e = np.clip(s / 0.9, 0, 1) ** 2 * (3 - 2 * np.clip(s / 0.9, 0, 1)) * (1.0 - np.clip((s - cl) / 1.2, 0, 1) ** 2 * (3 - 2 * np.clip((s - cl) / 1.2, 0, 1)))
        env = np.where(on, np.maximum(env, e), env)
        b = 0.03 * np.clip((s - (cl - 1.5)) / 1.5, 0, 1)
        bend = np.where(on, b, bend)
    f0 = 65.4 * (1.0 + bend)
    p1 = np.cumsum(f0) / SR
    p2 = np.cumsum(f0 * 1.014) / SR
    y = (table[(p1 % 1.0 * table_n).astype(int)] + table[(p2 % 1.0 * table_n).astype(int)]) * 0.5
    y *= env * (1.0 + 0.18 * np.sin(2 * np.pi * 11.0 * t)) * 0.6
    return norm(y, 0.7)


def conch(notes, seed=61):
    """SND-101 PLACEHOLDER: a conch blown: a buzzing note of odd-heavy partials near 300 Hz that swells, rises a little
    and falls away, with breath in it. `notes`: (start, length) of each blast."""
    rng = np.random.default_rng(seed)
    total = max(s + l for s, l in notes) + 1.5
    n = int(total * SR)
    t = np.arange(n) / SR
    y = np.zeros(n)
    for s0, ln in notes:
        s = t - s0
        on = (s >= 0) & (s < ln + 0.8)
        a = np.clip(s / 0.6, 0, 1)
        r = np.clip((s - ln) / 0.8, 0, 1)
        env = np.where(on, a * a * (3 - 2 * a) * (1 - r * r * (3 - 2 * r)), 0.0)
        f = 292.0 * (1.0 + 0.025 * np.sin(np.pi * np.clip(s / max(ln, 0.1), 0, 1)) - 0.04 * r)
        ph = np.cumsum(np.where(on, f, 0.0)) / SR
        tone = sum(np.sin(2 * np.pi * ph * k) / k ** (0.9 if k % 2 else 1.4) for k in range(1, 10))
        y += tone * env
    breath = shaped(n, rng, band(1200, 6000, 2)) * 0.06
    y = y / (np.max(np.abs(y)) + 1e-12) + breath * (np.abs(y) > 0.01)
    return norm(fade_ends(y), 0.7)


def pour(seed, seconds=1.1):
    """SND-604's tea (stand-in): butter tea poured from a spouted pot into a wooden bowl: a first splash, the thin
    stream's hiss, and a shower of small bubbles whose pitch rises as the bowl fills (the air over the tea shortens),
    each bubble's note rising as it closes; a tail as the spout lifts. Mono."""
    rng = np.random.default_rng(seed)
    n = int(seconds * SR)
    t = np.arange(n) / SR
    fill = np.clip(t / (seconds - 0.2), 0.0, 1.0)
    env = np.minimum(1.0, t / 0.03) * np.clip((seconds - t) / 0.15, 0.0, 1.0)
    y = shaped(n, rng, band(500, 3500, 2)) * 0.06 * env
    base = 650.0 * (1.0 + 1.3 * fill)
    t0 = 0.0
    while t0 < seconds - 0.18:
        t0 += rng.exponential(1.0 / 220.0)
        i = int(t0 * SR)
        f = base[min(i, n - 1)] * np.exp(rng.normal(0.0, 0.35))
        d = rng.uniform(0.004, 0.014)
        m = int(d * SR)
        tt = np.arange(m) / SR
        b = np.sin(2 * np.pi * f * (tt + 0.8 * tt * tt / d)) * np.exp(-tt / (d * 0.35)) * rng.uniform(0.15, 1.0)
        if i + m < n:
            y[i:i + m] += b * env[i]
    k = int(0.08 * SR)
    y[:k] += shaped(k, rng, band(300, 3000, 2)) * np.exp(-np.arange(k) / (0.02 * SR)) * 0.4
    return norm(fade_ends(y, 0.003, 0.1), 0.5)


def chough(seed):
    """SND-414 (stand-in): a red-billed chough's ringing "chee-ow" (chapter 06, 6.1): a call rich in harmonics that
    climbs for a moment and falls away, bright at its start and darker as it falls, a little harsh. Mono."""
    rng = np.random.default_rng(seed)
    dur = rng.uniform(0.28, 0.4)
    n = int(dur * SR)
    t = np.arange(n) / SR
    top = rng.uniform(0.05, 0.08)
    f_a, f_b, f_c = rng.uniform(1100, 1300), rng.uniform(1700, 2100), rng.uniform(800, 1000)
    f0 = np.where(t < top, f_a + (f_b - f_a) * (t / top) ** 0.7, f_c + (f_b - f_c) * np.exp(-(t - top) / (dur * 0.35)))
    ph = 2 * np.pi * np.cumsum(f0) / SR
    bright = np.clip(1.0 - (t - top) / (dur - top), 0.0, 1.0)
    y = np.zeros(n)
    for k in range(1, 9):
        y += (1.0 / k ** (1.4 - 0.8 * bright)) * (f0 * k < 9000) * np.sin(k * ph + rng.uniform(0, 2 * np.pi))
    y *= 1.0 + 0.35 * np.sin(2 * np.pi * rng.uniform(70, 110) * t)
    y += shaped(n, rng, band(1500, 6000, 2)) * 0.05
    env = np.minimum(1.0, t / 0.012) * np.clip((dur - t) / 0.09, 0.0, 1.0) ** 1.5
    return norm(fade_ends(y * env, 0.002, 0.03), 0.5)


def mastiff(seed):
    """SND-408 (stand-in, until a mastiff is recorded): a big dog's deep bark, "woof": a rough voice that jumps up to its
    peak in 30 ms and falls away, its pitch jittering, through a dog's low formants, breath in it. Mono."""
    rng = np.random.default_rng(seed)
    dur = rng.uniform(0.24, 0.36)
    n = int(dur * SR)
    t = np.arange(n) / SR
    lo, peak, end = rng.uniform(150, 190), rng.uniform(260, 330), rng.uniform(120, 160)
    top = rng.uniform(0.025, 0.04)
    f0 = np.where(t < top, lo + (peak - lo) * (t / top), end + (peak - end) * np.exp(-(t - top) / (dur * 0.3)))
    f0 = f0 * (1.0 + 0.03 * smooth_random(n, rng, [37.0, 61.0], dur))  # the roughness of the voice
    ph = 2 * np.pi * np.cumsum(f0) / SR
    y = np.zeros(n)
    for k in range(1, 30):
        y += (1.0 / k) * (f0 * k < 8000) * np.sin(k * ph + rng.uniform(0, 2 * np.pi))
    y += shaped(n, rng, band(400, 3500, 2)) * 0.35  # breath
    f = np.maximum(np.fft.rfftfreq(n, 1.0 / SR), 1.0)
    form = sum(a * np.exp(-0.5 * ((f - fc) / bw) ** 2) for fc, bw, a in
               ((rng.uniform(520, 640), 160.0, 1.0), (rng.uniform(1150, 1400), 260.0, 0.6), (rng.uniform(2300, 2700), 420.0, 0.25)))
    y = np.fft.irfft(np.fft.rfft(y) * (form + 0.04), n)
    env = np.minimum(1.0, t / 0.008) * np.clip((dur - t) / (dur * 0.55), 0.0, 1.0) ** 1.3
    return norm(fade_ends(y * env, 0.002, 0.03), 0.6)


def kora_squeak(seed):
    """SND-128 (stand-in, until Pema Ö's wheels are recorded): a big wall wheel set turning by a hand: its dry iron pin
    squeaking in its wooden socket, a stick-slip train that rises in pitch as the drum takes speed and settles into a
    creak, over the drum's soft rumble and the tick of its bell-striker passing. Mono."""
    rng = np.random.default_rng(seed)
    dur = rng.uniform(0.9, 1.3)
    n = int(dur * SR)
    t = np.arange(n) / SR
    # the stick-slip: pulses at a rate that climbs as the drum takes speed, each a short ring at the pin's pitch
    rate = rng.uniform(28, 40) + rng.uniform(25, 45) * (1.0 - np.exp(-t / 0.25))
    ph = np.cumsum(rate) / SR
    pulse = np.zeros(n)
    k = np.where(np.diff(np.floor(ph)) > 0)[0]
    ring_f = rng.uniform(900, 1400)
    m = int(0.012 * SR)
    shape = np.sin(2 * np.pi * ring_f * np.arange(m) / SR) * np.exp(-np.arange(m) / (m * 0.3))
    for i in k:
        if i + m < n:
            pulse[i:i + m] += shape * rng.uniform(0.5, 1.0)
    squeak = pulse * np.clip(1.0 - (t - 0.15) / (dur * 0.9), 0.15, 1.0)
    rumble = shaped(n, rng, band(80, 600, 2)) * 0.25 * np.minimum(1.0, t / 0.2)
    tick = np.zeros(n)
    i = int(rng.uniform(0.45, 0.7) * SR)
    mm = int(0.004 * SR)
    if i + mm < n:
        tick[i:i + mm] = rng.standard_normal(mm) * np.exp(-np.arange(mm) / (mm * 0.25))
    y = squeak * 0.7 + rumble + tick * 0.4
    env = np.minimum(1.0, t / 0.01) * np.clip((dur - t) / (dur * 0.35), 0.0, 1.0)
    return norm(fade_ends(y * env, 0.002, 0.05), 0.5)


def flutter(seed, seconds=20.0):
    """SND-013 (stand-in): prayer flags in the wind: cloth flapping in a quick, irregular train of soft snaps, faster and
    louder in the gusts, over a hiss of cloth and cord; now and then a sharper crack. A loop. Mono."""
    rng = np.random.default_rng(seed)
    n = int(seconds * SR)
    gust = 0.35 + 0.65 * smooth_random(n, rng, [0.07, 0.15, 0.31], seconds)
    y = shaped(n, rng, band(300, 3000, 2)) * 0.08 * gust
    t0 = 0.0
    while t0 < seconds - 0.1:
        g = gust[min(int(t0 * SR), n - 1)]
        t0 += rng.uniform(0.05, 0.13) / (0.5 + g)
        m = int(rng.uniform(0.015, 0.05) * SR)
        env = np.exp(-np.arange(m) / (m * 0.25))
        a = int(0.002 * SR)
        env[:a] *= np.linspace(0.0, 1.0, a)
        i = int(t0 * SR)
        if i + m < n:
            y[i:i + m] += rng.standard_normal(m) * env * rng.uniform(0.2, 0.7) * g * (1.8 if rng.random() < 0.06 else 1.0)
    f = np.maximum(np.fft.rfftfreq(n, 1.0 / SR), 1.0)
    y = np.fft.irfft(np.fft.rfft(y) * (band(250, 5000, 2)(f) + 0.3 * band(90, 300, 3)(f)), n)
    return norm(loop_join(y, int(1.5 * SR)), 0.5)


def mill(seconds=12.0, seed=411, rate=2.0):
    """SND-215 stand-in: a horizontal water mill at work (the Serchu's four, SER-05 to 08; research 08, 2): the chute's
    jet striking the paddles under the floor, a steady rushing splash with a flutter at each paddle; the runner stone's
    low grinding rumble, swelling a little once a turn (`rate` turns a second, as world/mills.gd turns it); and the
    clapper on the shoe under the hopper knocking quick and uneven, a dry wooden tick, which is what a mill sounds like
    from its door. A whole number of turns, so the loop keeps the beat. Mono, for a point emitter at the mill."""
    rng = np.random.default_rng(seed)
    turns = max(1, round(seconds * rate))
    n = int(turns / rate * SR)
    t = np.arange(n) / SR
    rush = shaped(n, rng, lambda f: band(250, 6000, 2)(f) * pink(f) ** 0.3)
    rush *= 0.8 + 0.2 * smooth_random(n, rng, [4.3, 7.9, 13.1], n / SR)
    grind = shaped(n, rng, band(45, 260, 3)) * (0.75 + 0.25 * np.sin(2 * np.pi * rate * t) ** 2)
    knock = np.zeros(n)
    t0 = 0.05
    while t0 < n / SR - 0.05:
        i = int(t0 * SR)
        m = int(0.004 * SR)
        knock[i:i + m] += rng.standard_normal(m) * np.exp(-np.arange(m) / (m * 0.25)) * rng.uniform(0.5, 1.0)
        t0 += rng.uniform(0.13, 0.24)  # the shoe shaken by the runner's eye: five or six knocks a second, never even
    knock = np.fft.irfft(np.fft.rfft(knock) * band(700, 3800, 1.5)(np.maximum(np.fft.rfftfreq(n, 1.0 / SR), 1.0)), n)
    knock /= np.std(knock) + 1e-12
    x = rush * 0.5 + grind * 0.45 + knock * 0.16
    return norm(loop_join(x, int(1.0 * SR)))


def chop(seed):
    """SND-216 stand-in: an axe biting into a larch's trunk (the Shade Wood's woodcutters, M2 sprint 12, step 6): the
    steel's sharp tick, the wood's hollow knock with its low body, and a little splintering after; dry, no ring. Mono, a
    one-shot at the woodcutter."""
    rng = np.random.default_rng(seed)
    n = int(0.55 * SR)
    t = np.arange(n) / SR
    tick = rng.standard_normal(n) * np.exp(-t / 0.0025)
    tick = np.fft.irfft(np.fft.rfft(tick) * band(2500, 9000, 1.5)(np.maximum(np.fft.rfftfreq(n, 1.0 / SR), 1.0)), n)
    f0 = rng.uniform(150.0, 210.0)
    knock = (np.sin(2 * np.pi * f0 * t) * 0.8 + np.sin(2 * np.pi * f0 * 2.31 * t) * 0.35) * np.exp(-t / 0.045)
    thud = shaped(n, rng, band(80, 900, 3)) * np.exp(-t / 0.03)
    splint = shaped(n, rng, band(1200, 6000, 2)) * np.exp(-np.maximum(t - 0.02, 0.0) / 0.06) * (t > 0.02) * 0.25
    x = tick * 0.5 + knock * 0.9 + thud * 0.6 + splint
    return norm(fade_ends(x, 0.0005, 0.05), 0.7)


def printing(seconds=12.0, seed=415):
    """SND-211 stand-in: the Parkhang's printers at work (chapter 03, 6.10; the game's M3 sprint 1, step 4), heard through
    its windows: three pairs at their boards out of step, each a soft wooden knock as the block is laid on the inked sheet
    and a long rub of the felt roller over the paper, a pause, the sheet lifted with a papery flick; muffled, a loop."""
    rng = np.random.default_rng(seed)
    n = int(seconds * SR)
    t = np.arange(n) / SR
    x = np.zeros(n)
    for v in range(3):
        period = rng.uniform(2.6, 3.4)
        at = rng.uniform(0.0, period)
        while at < seconds - 1.5:
            i0 = int(at * SR)
            m = int(0.25 * SR)
            tt = np.arange(m) / SR
            f0 = rng.uniform(170.0, 230.0)
            knock = (np.sin(2 * np.pi * f0 * tt) * 0.6 + shaped(m, rng, band(90, 700, 3)) * 0.5) * np.exp(-tt / 0.03)
            x[i0:i0 + m] += knock[:max(0, min(m, n - i0))]
            r0 = i0 + int(rng.uniform(0.25, 0.4) * SR)
            rl = int(rng.uniform(0.8, 1.2) * SR)
            env = np.sin(np.linspace(0.0, np.pi, rl)) ** 1.5
            rub = shaped(rl, rng, band(300, 2500, 2)) * env * 0.22
            x[r0:r0 + rl] += rub[:max(0, min(rl, n - r0))]
            f_ = r0 + rl + int(rng.uniform(0.2, 0.5) * SR)
            fl = int(0.12 * SR)
            flick = shaped(fl, rng, band(1500, 7000, 2)) * np.exp(-np.arange(fl) / SR / 0.025) * 0.18
            x[f_:f_ + fl] += flick[:max(0, min(fl, n - f_))]
            at += period * rng.uniform(0.9, 1.1)
    muff = np.fft.irfft(np.fft.rfft(x) * band(60, 3500, 3)(np.maximum(np.fft.rfftfreq(n, 1.0 / SR), 1.0)), n)  # (through the walls)
    return norm(loop_join(muff, int(0.6 * SR)), 0.5)


def rosary(seed, seconds=3.6, every=0.7):
    """SND-117 stand-in: a pilgrim's rosary on the 1,080 steps (the game's M3 sprint 1, step 5; chapter 10, SND-117,
    "rosaries clicking"), a bead slipped under the thumb at each step: a small dry click of bone or wood against the next
    bead, now and then doubled as it meets the one behind, a faint rub of the cord between. No voice: the counting murmur
    waits for recordings (Greg, 27 Sep 2026: no synthetic murmur). Mono, a one-shot at the climber."""
    rng = np.random.default_rng(seed)
    n = int(seconds * SR)
    x = np.zeros(n)
    at = rng.uniform(0.05, 0.25)
    while at < seconds - 0.2:
        for k in range(2 if rng.random() < 0.3 else 1):
            i0 = int((at + k * rng.uniform(0.025, 0.05)) * SR)
            m = int(0.04 * SR)
            tt = np.arange(m) / SR
            f0 = rng.uniform(2600.0, 4200.0)
            click = (np.sin(2 * np.pi * f0 * tt) * 0.7 + np.sin(2 * np.pi * f0 * 1.63 * tt) * 0.3) * np.exp(-tt / 0.0028)
            click += shaped(m, rng, band(1500, 9000, 2)) * np.exp(-tt / 0.0015) * 0.5
            x[i0:i0 + m] += click[:max(0, min(m, n - i0))] * (1.0 if k == 0 else 0.55) * rng.uniform(0.75, 1.0)
        at += every * rng.uniform(0.85, 1.15)
    rub = shaped(n, rng, band(800, 4000, 2)) * smooth_random(n, rng, (0.7, 1.3, 2.1), seconds) * 0.025
    return norm(fade_ends(x + rub, 0.002, 0.08), 0.5)


def flag_mass(seed, seconds=24.0):
    """SND-015 stand-in (chapter 10: "Flag mass, gorge spans", RNG-06, V-17; chapter 08: "hundreds of flags snapping as
    one sound that swells with each gust"; the game's M3 sprint 2, step 5): several of SND-013's trains of snaps laid over
    each other out of step, the cloth's hiss heavier and lower, the gusts slow and deep so the whole mass swells and falls
    together. A loop. Mono."""
    rng = np.random.default_rng(seed)
    n = int(seconds * SR)
    gust = 0.25 + 0.75 * smooth_random(n, rng, [0.04, 0.09, 0.17], seconds)
    y = shaped(n, rng, band(150, 2500, 2)) * 0.12 * gust
    for layer in range(5):
        t0 = rng.uniform(0.0, 0.2)
        while t0 < seconds - 0.1:
            g = gust[min(int(t0 * SR), n - 1)]
            t0 += rng.uniform(0.03, 0.09) / (0.4 + g)
            m = int(rng.uniform(0.02, 0.07) * SR)
            env = np.exp(-np.arange(m) / (m * 0.3))
            a = int(0.003 * SR)
            env[:a] *= np.linspace(0.0, 1.0, a)
            i = int(t0 * SR)
            if i + m < n:
                y[i:i + m] += rng.standard_normal(m) * env * rng.uniform(0.15, 0.5) * g * (1.6 if rng.random() < 0.04 else 1.0)
    f = np.maximum(np.fft.rfftfreq(n, 1.0 / SR), 1.0)
    y = np.fft.irfft(np.fft.rfft(y) * (band(180, 4000, 2)(f) + 0.45 * band(60, 220, 3)(f)), n)
    return norm(loop_join(y, int(2.0 * SR)), 0.55)


def protector_drum(seed=111, seconds=24.0):
    """SND-111 stand-in: the Gönkhang's protector rite heard through its door (chapter 03, 6.4: "a single drum at night";
    chapter 10, 16:00-17:00, "heard from the courtyard as a low pulse through the door"; the game's M3 sprint 3, step 3):
    the big drum (rnga) struck slowly with its curved stick, a deep thump whose pitch sinks as the head settles, the stick's
    slap on the skin, now and then a doubled stroke; muffled by the curtain and the walls. The drum alone: the keepers'
    deep chant and the rolmo wait for recordings and consent (Greg, 27 Sep 2026: no synthetic murmur of voices). A loop."""
    rng = np.random.default_rng(seed)
    n = int(seconds * SR)
    x = np.zeros(n)
    at = rng.uniform(0.2, 0.6)
    while at < seconds - 2.0:
        for k in range(2 if rng.random() < 0.18 else 1):
            i0 = int((at + k * rng.uniform(0.28, 0.36)) * SR)
            m = int(1.6 * SR)
            tt = np.arange(m) / SR
            f = 58.0 + 34.0 * np.exp(-tt / 0.045) + rng.uniform(-2.0, 2.0)  # the head's pitch sinking as it settles
            body = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-tt / rng.uniform(0.45, 0.6))
            body += 0.35 * np.sin(2 * np.pi * np.cumsum(f * 1.52) / SR) * np.exp(-tt / 0.18)
            slap = shaped(m, rng, band(180, 1400, 2)) * np.exp(-tt / 0.018) * 0.45
            x[i0:i0 + m] += ((body + slap) * (1.0 if k == 0 else 0.6) * rng.uniform(0.85, 1.0))[:max(0, min(m, n - i0))]
        at += rng.uniform(2.2, 2.7)
    muff = np.fft.irfft(np.fft.rfft(x) * band(30, 900, 3)(np.maximum(np.fft.rfftfreq(n, 1.0 / SR), 1.0)), n)
    return norm(loop_join(muff, int(1.0 * SR)), 0.6)


def small_bell(seconds=1.8, f0=1310.0):
    """SND-130 stand-in: a water prayer wheel's small bell, struck once a turn by a peg on its drum (research 08, 2): a
    small cast bell's partials, higher and shorter than the great wheel's."""
    t = np.arange(int(seconds * SR)) / SR
    partials = [(0.5, 0.35, 0.9), (1.0, 1.0, 0.6), (1.21, 0.45, 0.45), (1.52, 0.3, 0.35), (2.02, 0.3, 0.25), (2.83, 0.12, 0.15)]
    y = sum(a * np.sin(2 * np.pi * f0 * r * t) * np.exp(-t / d) for r, a, d in partials)
    y *= np.minimum(1.0, t / 0.0015)
    return norm(fade_ends(y, 0.0005, 0.15), 0.6)


def bell(seconds=3.0):
    """The great wheel's bell (world/great_wheel.gd's tone, at 48 kHz): partials after a cast bell's hum, prime,
    tierce and nominal, each dying at its own rate, over a 2 ms strike."""
    t = np.arange(int(seconds * SR)) / SR
    f0 = 520.0
    partials = [(0.5, 0.55, 2.4), (1.0, 1.0, 1.6), (1.19, 0.4, 1.1), (1.5, 0.3, 0.9), (2.0, 0.35, 0.7), (2.74, 0.15, 0.4)]
    y = sum(a * np.sin(2 * np.pi * f0 * r * t) * np.exp(-t / d) for r, a, d in partials)
    y *= np.minimum(1.0, t / 0.002)
    return norm(fade_ends(y, 0.0005, 0.2), 0.7)


def breath(seed=603, seconds=9.0, rate=1.3):
    """SND-603 stand-in (chapter 10: "Breath: climbing", the player's, a loop; IMP-043: the sprint run out at the town's
    2,700 m): quick, deep breaths through the open mouth, a little over one a second; the breath drawn in a higher,
    rougher hiss, rising and cut short, the breath let out lower and longer, falling away; never voiced. Each a little
    unlike the last in its length and force. The tail folded into the head: a loop. Mono."""
    rng = np.random.default_rng(seed)
    n = int(seconds * SR)
    x = np.zeros(n + 2 * SR)
    air_in = shaped(x.size, rng, band(1100.0, 5200.0, 2.2))
    air_out = shaped(x.size, rng, band(380.0, 2400.0, 2.2)) + 0.35 * shaped(x.size, rng, band(900.0, 1300.0, 6.0))
    t0 = 0.05
    while t0 < seconds:
        p = rng.uniform(0.88, 1.12) / rate
        a = rng.uniform(0.75, 1.0)
        i0, ni = int(t0 * SR), int(p * rng.uniform(0.34, 0.4) * SR)
        k = np.linspace(0.0, 1.0, ni)
        x[i0:i0 + ni] += air_in[i0:i0 + ni] * np.sin(np.pi * np.minimum(k * 0.62, 0.5)) ** 2 * (1.0 - np.exp(-(1.0 - k) * 30.0)) * 0.42 * a
        j0, no = i0 + ni + int(rng.uniform(0.02, 0.05) * SR), int(p * rng.uniform(0.46, 0.54) * SR)
        k = np.linspace(0.0, 1.0, no)
        x[j0:j0 + no] += air_out[j0:j0 + no] * (1.0 - np.exp(-k * 28.0)) * np.exp(-k * 2.6) * 0.8 * a
        t0 += p
    head = x[:n].copy()
    head[:x.size - n] += x[n:]
    return norm(head, 0.5)


def main():
    os.makedirs(OUT, exist_ok=True)
    made = []

    def save(name, x, loop):
        path = os.path.join(OUT, name + ".wav")
        write_wav(path, x, SR, loop=loop)
        made.append((name, x.shape[0] / SR, "loop" if loop else "one"))

    for s in ("low", "mid", "high"):
        save("snd_011_wind_%s" % s, wind(s), True)
    save("snd_003_torrent", torrent(), True)
    save("snd_024_juniper", juniper(), True)
    save("snd_025_hearth", hearth(), True)
    save("snd_009_spout", spout(), True)
    save("snd_129_hand_wheel", hand_wheel(), True)
    save("snd_229_dranyen", dranyen(), True)
    save("snd_402_bells", bells(), True)
    save("snd_239_clock", clock(), True)
    save("snd_111_protector_drum", protector_drum(), True)
    save("snd_603_breath", breath(), True)
    for k in range(4):
        save("snd_303_dice_%d" % k, dice(303 + k), False)
    save("snd_104_horns_dusk_placeholder", horns([(0.5, 6.5), (8.0, 6.0), (15.5, 6.0)]), False)
    save("snd_103_horns_dawn_placeholder", horns([(0.5, 9.0), (11.5, 10.0), (23.5, 11.0)]), False)
    save("snd_101_conch_one_placeholder", conch([(0.2, 5.5)]), False)
    save("snd_101_conch_two_placeholder", conch([(0.2, 1.6), (2.6, 1.8)]), False)
    save("snd_127_wheel_bell", bell(), False)
    save("snd_215_mill", mill(), True)
    save("snd_130_wheel_bell", small_bell(), False)
    save("snd_211_printing", printing(), True)
    for k in range(3):
        save("snd_216_chop_%d" % k, chop(413 + k), False)
    for k in range(4):
        save("snd_117_rosary_%d" % k, rosary(117 + k), False)
    for k in range(3):
        save("snd_604_tea_pour_%d" % k, pour(71 + k), False)
    for k in range(5):
        save("snd_414_chough_%d" % k, chough(81 + k), False)
    for k in range(6):
        save("snd_408_mastiff_%d" % k, mastiff(408 + k), False)
    for k in range(4):
        save("snd_128_wheel_squeak_%d" % k, kora_squeak(409 + k), False)
    for k in range(2):
        save("snd_013_flags_%d" % k, flutter(91 + k), True)
    for k in range(2):
        save("snd_015_flag_mass_%d" % k, flag_mass(15 + k), True)
    for name, secs, kind in made:
        print("synth: %s  %.1f s  %s" % (name, secs, kind))
    print("synth: %d masters -> %s" % (len(made), os.path.relpath(OUT, ROOT)))


if __name__ == "__main__":
    main()
