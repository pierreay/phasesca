#!/usr/bin/env python3

import matplotlib.pyplot as plt
import numpy as np
from scipy import signal

# * Signal importation and processing

# signal at 20 msps:
'''
full_signal = np.load('carrier_or_mod_soft_or_hard/fc_2.528e9_sr_20e6_76db_coax-cable_tx-off_tx-carrier_tx-carrier-soft-aes_tx-carrier-hard-aes.npy')[8051081*2:16142453*2]

carrier = full_signal[:int(1e6)]
swaes = full_signal[-int(1e6)*9:-int(1e6)*9 + int(1e6)]
hwaes = full_signal[-int(1e6):]
'''

# signal at 8msps:
full_signal = np.load('/home/drac/mnt/storage_nvme/dataset/240130_carrier_or_mod_soft_or_hard/fc_2.528e9_sr_8e6_76db_coax-cable_tx-off_tx-carrier_tx-carrier-soft-aes_tx-carrier-hard-aes.npy')[849487*2:4661285*2]

# carrier 8msps
carrier = full_signal[:400000*2]
swaes = full_signal[-1600000*2:-1600000*2 + 400000*2]
hwaes = full_signal[-400000*2:]

# Continuous instantaneous phase using unwrapping for...
# carrier
ca = np.unwrap(np.angle(carrier))
# software aes
sa = np.unwrap(np.angle(swaes))
# hardware aes
ha = np.unwrap(np.angle(hwaes))

# set relative signal to 0...
ca = [(ca[i] - ca[0]) for i in range(len(ca))]
# without detrending:
sa = [(sa[i] - sa[0]) for i in range(len(sa))]
ha =[(ha[i] - ha[0]) for i in range(len(ha))]
# with manual detrending using carrier as reference:
'''
sa = [(sa[i] - sa[0]) - ca[i] for i in range(len(sa))]
ha =[(ha[i] - ha[0]) - ca[i] for i in range(len(ha))]
'''

# * Plotting

def setup_good_paper_plot():
  import lib.plot as libplot
  libplot.enable_latex_fonts()
  plt.xlim(left=0, right=6e3)
  plt.ylim(top=100, bottom=-200)
  plt.ylabel("Continuous instantaneous phase [rad]")
  plt.xlabel("Sample [\#]")

setup_good_paper_plot()

lw=0.4
plt.plot(ca, label="Carrier", lw=lw)
plt.plot(sa, label="Software AES", lw=lw)
plt.plot(ha, label="Hardware AES", color="red", lw=lw)

plt.legend()
# plt.show()
plt.savefig("instant_phase_viz.pdf")

# plt.specgram(ha)
# plt.show()

exit(0)

# * Experiment about signal averaging

n = 30
sigfilt = []
for i in range(0, len(ha), n):
  sigfilt += [1000*np.var(ha[i:i+n])] * n

n = 75
s = []
factor = []
sig = sigfilt
for i in range(0, len(sig) - n, n):
  factor += [1000]*n if np.mean(np.abs(sig[i:i+n]))>1000 else [0]*n


extracted_signals = []
extracted_signal = []

for i in range(len(factor)):
  if factor[i] > 0:
    extracted_signal.append(ha[i])
  else:
    if len(extracted_signal) > 0:
      if len(extracted_signal) == 1200:
        print(len(extracted_signal))
        extracted_signals.append(np.array(extracted_signal))
      extracted_signal = []

plt.plot(np.average(np.array(extracted_signals), axis=0))
plt.show()

for t in range(0, 10000, 30):
  for s in extracted_signals[t:t+30]:
    if len(s) < 1000:
      continue
    s = [s[i] - s[0] for i in range(len(s))]
    plt.plot(s)      
  plt.show()
