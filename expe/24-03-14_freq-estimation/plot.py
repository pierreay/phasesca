#!/usr/bin/env python3

import numpy as np
import matplotlib.pyplot as plt
import lib.plot as libplot
import lib.complex as complex

a = np.load("FC_128e6_SR_30e6_76db.npy")
b = complex.get_phase_rot(a)

# Cut around soft AES
b = b[int(2.4e6):int(3.8e6)]
# NOTE: Equivalent of above but visual only, need to modify the signal for the
# PSD computation later.
#plt.xlim(left=0.08, right=0.125)

# Trad. specgram
plt.specgram(b, Fs=30e6, NFFT=2048, sides="onesided", mode="magnitude")
plt.show()

# New PSD:
plt.psd(b, Fs=30e6, NFFT=None)
plt.show()
