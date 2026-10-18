#!/usr/bin/python3
"""Whether the Mac's screen is locked (exit 0) or not (exit 1). A locked screen throttles a window's frames (a stall of
60-180 ms every seven or eight frames, whatever is drawn; found 28 Sep 2026, when four PT-slice runs failed alike with and
without the evening's changes), so a performance run then measures macOS, not the game: tools/perf/pt_slice.sh refuses.
The system Python, for ctypes and CoreGraphics' session dictionary."""
import ctypes
import ctypes.util
import sys

cf = ctypes.cdll.LoadLibrary(ctypes.util.find_library("CoreFoundation"))
cg = ctypes.cdll.LoadLibrary(ctypes.util.find_library("CoreGraphics"))
cg.CGSessionCopyCurrentDictionary.restype = ctypes.c_void_p
cf.CFDictionaryGetValue.restype = ctypes.c_void_p
cf.CFDictionaryGetValue.argtypes = [ctypes.c_void_p, ctypes.c_void_p]
cf.CFStringCreateWithCString.restype = ctypes.c_void_p
cf.CFStringCreateWithCString.argtypes = [ctypes.c_void_p, ctypes.c_char_p, ctypes.c_uint32]
cf.CFBooleanGetValue.argtypes = [ctypes.c_void_p]
session = cg.CGSessionCopyCurrentDictionary()
if not session:
    sys.exit(1)
value = cf.CFDictionaryGetValue(session, cf.CFStringCreateWithCString(None, b"CGSSessionScreenIsLocked", 0x08000100))
sys.exit(0 if value and cf.CFBooleanGetValue(value) else 1)
