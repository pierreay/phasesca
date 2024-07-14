#!/usr/bin/env python3

# iq.npy -> /home/drac/pro_storage/phase_data/sets/24-07-04_nrf52-ref/train/1_iq.npy

import numpy as np
import matplotlib.pyplot as plt

from scaff import dsp
from scaff import plotters



if __name__ == "__main__":
    iq = np.load("./iq.npy")
    fs = 10e6
    drop_start = 100
    # plt.specgram(iq, NFFT=256, sides="twosided", mode="magnitude")
    # plt.show()

    filter = dsp.LHPFilter("low", 90e3, order=9)
    iq = filter.apply(iq, fs=fs)
    filter1 = dsp.LHPFilter("high", 50e3, order=6, enabled=True)
    filter2 = dsp.LHPFilter("low", 30e3, order=6, enabled=True)
    iq_12 = filter2.apply(filter1.apply(iq, fs=fs), fs=fs)
    wrapped = np.angle(iq_12[drop_start:])
    unwrapped = np.unwrap(np.angle(iq[drop_start:]))
    unwrapped_0 = [unwrapped[i] - unwrapped[0] for i in range(len(unwrapped))]
    shift = [0] + [unwrapped_0[i] - unwrapped_0[i - 1] for i in range(1, len(unwrapped_0), 1)]

    plotters.enable_latex_fonts()

    plt.subplot(1, 3, 1)
    plt.plot(wrapped)
    plt.title("Instantaneous phase (Wrapped) ($\\phi$)")
    plt.xlabel("Samples [\\#]")
    plt.ylabel("Radian [rad]")
    plt.subplot(1, 3, 2)
    plt.plot(unwrapped)
    plt.title("Continuous instantaneous phase (Unwrapped) ($\\Phi$)")
    plt.xlabel("Samples [\\#]")
    plt.ylabel("Radian [rad]")
    plt.subplot(1, 3, 3)
    plt.plot(shift)
    plt.title("Phase shift ($\\Phi_{shift}$)")
    plt.xlabel("Samples [\\#]")
    plt.ylabel("Radian [rad]")

    figure = plt.gcf() # Get current figure
    figure.set_size_inches(24, 6) # Set figure's size manually to your full screen (32x18).
    plt.savefig("plot.pdf", bbox_inches='tight', dpi=100)
