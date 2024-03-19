#!/usr/bin/env python3

import numpy as np
import matplotlib.pyplot as plt

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

# * Plot polar

# PROG:

def plot_polar(mag, ang, title=""):
    fig = plt.figure(figsize=(9,6))
    ax = fig.add_subplot(projection='polar')

    # Plot color by time
    times = mag.astype(np.int64)

    cm = plt.get_cmap('cividis_r')
    im = ax.scatter(ang, mag, c=times, cmap=cm, s=10)

    cbar = fig.colorbar(im, ticks=[times[0], times[len(times)//2], times[-1]])
    cbar.ax.set_yticklabels([mag[0], mag[len(times)//2], mag[-1]])

    #fig.tight_layout()
    plt.title(title)
    plt.savefig("plot_{}.pdf".format(title))

plot_polar(np.abs(iq), np.angle(iq), "abs(iq);angle(iq)")
plot_polar(np.abs(iq_augmented), np.angle(iq_augmented), "abs(iq_augmented);angle(iq_augmented)")
plot_polar(amp, phr, "amp;phr")

