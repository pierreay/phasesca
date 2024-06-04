#!/usr/bin/env python3

import numpy as np
import matplotlib.pyplot as plt
import sys

CUMULATIVE = True

if len(sys.argv) <= 4:
    print("Usage: {} PATH COMP BASE OFFSET".format(sys.argv[0]))
    exit(1)

path = str(sys.argv[1])
comp = str(sys.argv[2])
base = int(sys.argv[3])
offset = int(sys.argv[4])

for i in list(range(base, base + offset)):
    plt.plot(np.load("{}/{}__{}.npy".format(path, comp, i)))
    if CUMULATIVE is False:
        plt.show()

if CUMULATIVE is True:
    plt.show()
