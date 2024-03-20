#!/usr/bin/env python3

# Inspired from:
# https://ni4ai-blog.readthedocs.io/en/latest/blog/analysis/visualizing-phasor-timeseries.html

import numpy as np
import matplotlib.pyplot as plt

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

# * Plot polar 2D using color for time

def plot_polar(mag, ang, title=""):
    """Polar plot of complex-valued data using color for time (3rd dimension).
    
    Inputs are magnitude and angle because of the polar projection used in
    matplotlib. It is the same as plotting I/Q using the scatter in non-polar
    mode. In order to have I/Q as inputs ("iq.real" instead of "mag", and
    "iq.imag" instead of "ang"), unset the "projection" parameter.

    :param mag: Magnitude of the complex-valued data.

    :param ang: Angle of the complex-valued data.

    """
    assert mag.shape == ang.shape

    # Using Polar projection transforms radians into visual angles.
    fig = plt.figure(figsize=(9,6))
    ax = fig.add_subplot(projection='polar')

    # Plot time using colors. Yellow = Older points ; Blue = New points.
    times = np.linspace(0, len(mag) / SAMP_RATE, num=len(mag)) # Time vector.
    cm = plt.get_cmap('cividis_r')                             # Color map.

    # Create the scatter plot.
    marker_size = 5
    im = ax.scatter(ang, mag, c=times, cmap=cm, s=marker_size)

    # Create the right color bar.
    cbar = fig.colorbar(im, ticks=[times[0], times[len(times)//2], times[-1]])
    cbar.ax.set_yticklabels([times[0], times[len(times)//2], times[-1]])
    cbar.ax.set_title("Time [s]")

    plt.title(title)
    plt.savefig("plot_polar_{}.pdf".format(title))

# NOTE: Copy of the plot_polar without polar projection for comparison purpose.
def plot_rectangular(real, imag, title=""):
    # Using Polar projection transforms radians into visual angles.
    fig = plt.figure(figsize=(9,6))
    ax = fig.add_subplot()

    # Plot time using colors. Yellow = Older points ; Blue = New points.
    times = np.linspace(0, len(real) / SAMP_RATE, num=len(real)) # Time vector.
    cm = plt.get_cmap('cividis_r')                               # Color map.

    # Create the scatter plot.
    marker_size = 5
    im = ax.scatter(imag, real, c=times, cmap=cm, s=marker_size)

    # Create the right color bar.
    cbar = fig.colorbar(im, ticks=[times[0], times[len(times)//2], times[-1]])
    cbar.ax.set_yticklabels([times[0], times[len(times)//2], times[-1]])
    cbar.ax.set_title("Time [s]")

    plt.title(title)
    plt.savefig("plot_rectangular_{}.pdf".format(title))

# DONE:
# plot_polar(np.abs(iq), np.angle(iq), "abs(iq);angle(iq)")
# plot_polar(np.abs(iq_augmented), np.angle(iq_augmented), "abs(iq_augmented);angle(iq_augmented)")
# plot_polar(amp, phr, "amp;phr")
# plot_rectangular(iq.real, iq.imag, "iq.real;iq.imag")
# plot_rectangular(iq_augmented.real, iq_augmented.imag, "iq_augmented.real;iq_augmented.imag")
# plot_rectangular(amp, phr, "amp;phr")

# * Plot polar 3D using color for time

def plot_real_imaginary_3d(real, imag, title=""):
    fig = plt.figure(figsize=(9,6))
    ax = fig.add_subplot(projection='3d')

    # Plot time using colors.
    times = np.linspace(0, len(real) / SAMP_RATE, num=len(real)) # Time vector.

    COLOR_ENABLE = True

    # Plotting using single color:
    if not COLOR_ENABLE is True:
        ax.plot(times, real, imag)
    # Plotting using time for color: segment plot and color depending on "times".
    elif COLOR_ENABLE is True:
        s = 2                                   # Segment length
        r, g, b = 0, 0, 0                       # RGB color
        r_incr, g_incr, b_incr = 0.02, 0.1, 0.3 # Color increments
        for i in range(0, len(real) - s, s):
            r = (r + r_incr) % 1
            if r > 0.98:
                r = 0
                g = (g + g_incr) % 1
            if g > 0.80:
                g = 0
                b = (b + b_incr) % 1
            ax.plot(times[i : i+s+1], real[i : i+s+1], imag[i : i+s+1], c=(r, g, b))
    
    ax.set_ylabel("Real component")
    ax.set_zlabel("Imaginary component")

    plt.title(title)
    plt.savefig("plot_polar_3d_{}.pdf".format(title))

    INTERACTIVE_ENABLE = False
    if INTERACTIVE_ENABLE is True:
        fig.tight_layout()
        plt.show()

# DONE:
# plot_real_imaginary_3d(iq_augmented.real, iq_augmented.imag, title="iq_augmnented.real;iq_augmented.imag")
# plot_real_imaginary_3d(iq.real, iq.imag, title="iq.real;iq.imag")
# plot_real_imaginary_3d(amp, phr, title="amp;phr")
