"""WAV files for the game's sound (plan chapter 10, 11.7): 16-bit PCM, mono or stereo, and for a loop a `smpl` chunk
with its loop points, which Godot's WAV importer reads ("Detect From WAV"), so a bed loops from its first sample to its
last without an import setting per file. Used by tools/audio/synth.py and tools/audio/process.py."""
import struct
import wave

import numpy as np


def write_wav(path, x, rate, loop=False):
    """x: float samples in -1..1, shape (n,) or (n, channels)."""
    x = np.asarray(x, dtype=np.float64)
    ch = 1 if x.ndim == 1 else x.shape[1]
    pcm = (np.clip(x, -1.0, 1.0) * 32767.0).astype("<i2")
    with wave.open(path, "wb") as w:
        w.setnchannels(ch)
        w.setsampwidth(2)
        w.setframerate(rate)
        w.writeframes(pcm.tobytes())
    if loop:
        add_loop(path, 0, x.shape[0] - 1, rate)


def add_loop(path, start, end, rate):
    """Append a `smpl` chunk (one forward loop, start..end inclusive, in frames) and fix the RIFF size."""
    body = struct.pack("<9I", 0, 0, int(1e9 / rate), 60, 0, 0, 0, 1, 0) + struct.pack("<6I", 0, 0, start, end, 0, 0)
    chunk = b"smpl" + struct.pack("<I", len(body)) + body
    with open(path, "r+b") as f:
        data = f.read()
        riff_size = struct.unpack("<I", data[4:8])[0]
        f.seek(0, 2)
        f.write(chunk)
        f.seek(4)
        f.write(struct.pack("<I", riff_size + len(chunk)))


def read_wav(path):
    """Float samples (n,) or (n, channels), and the rate."""
    with wave.open(path, "rb") as w:
        ch, width, rate, n = w.getnchannels(), w.getsampwidth(), w.getframerate(), w.getnframes()
        raw = w.readframes(n)
    if width == 2:
        x = np.frombuffer(raw, "<i2").astype(np.float64) / 32768.0
    elif width == 3:
        b = np.frombuffer(raw, np.uint8).reshape(-1, 3)
        v = (b[:, 0].astype(np.int32) | (b[:, 1].astype(np.int32) << 8) | (b[:, 2].astype(np.int32) << 16))
        v = np.where(v & 0x800000, v - 0x1000000, v)
        x = v.astype(np.float64) / 8388608.0
    else:
        raise ValueError("%s: %d-byte samples" % (path, width))
    return (x.reshape(-1, ch) if ch > 1 else x), rate
