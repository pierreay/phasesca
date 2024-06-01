#!/usr/bin/env python3

import numpy as np
import matplotlib.pyplot as plt

import lib.log as l
import lib.plot as libplot
import lib.complex as complex

# * Trace parameters

# Trace sample rate [Msps].
SAMP_RATE=8e6

# * Import traces

amp = np.load("./amp__0.npy")
phr = np.load("./phr__0.npy")

i = np.load("./i__0.npy")
q = np.load("./q__0.npy")

i_augmented = np.load("./i_augmented__0.npy")
q_augmented = np.load("./q_augmented__0.npy")

# DONE:
# plt.plot(i_augmented)
# plt.show()

# * Convert to complex I/Q

iq = np.empty_like(i, dtype=np.complex64)
iq_augmented = np.empty_like(i_augmented, dtype=np.complex64)

for ii, iv in enumerate(i):
    iq[ii] = i[ii] + 1j * q[ii]
for ii, iv in enumerate(i_augmented):
    iq_augmented[ii] = i_augmented[ii] + 1j * q_augmented[ii]

# DONE:
# plt.specgram(iq_augmented, sides="twosided", mode="magnitude")
# plt.show()
# plt.plot(iq_augmented, sides="twosided", mode="magnitude")
# plt.show()

# * Experimenting with phase rotation

def get_phase_rot2(iq):
    """Digital signal of phase rotation?"""
    assert iq.dtype == np.complex64
    phr2 = np.empty_like(iq, dtype=np.int32)
    phr2[0] = 1
    for i in range(len(iq[1:])):
        rot = np.angle(iq[i]) - np.angle(iq[i - 1])
        if rot > 0:
            phr2[i] = 1
        elif rot < 0:
            phr2[i] = -1
        elif rot == 0:
            phr2[i] = 0
    return phr2[:-1]

# * XXX: Found a problem in number storage or conversion

# Amplitude and phase rototation from those IQ:
amp3 = np.abs(iq)
phr3 = complex.get_phase_rot(iq)
# ... Should be equal this amplide and this phase rotation:
plt.plot(amp)
plt.plot(amp3)
plt.show()
plt.plot(phr)
plt.plot(phr3)
plt.show()
# Which is not the case!
