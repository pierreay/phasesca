import matplotlib.pyplot as plt
import numpy as np
from scipy import signal
'''
full_signal = np.load('carrier_or_mod_soft_or_hard/fc_2.528e9_sr_8e6_76db_coax-cable_tx-off_tx-carrier_tx-carrier-soft-aes_tx-carrier-hard-aes.npy')[849487*2:4661285*2]

# carrier 8msps
carrier = full_signal[:400000*2]
swaes = full_signal[-1600000*2:-1600000*2 + 400000*2]
hwaes = full_signal[-400000*2:]
'''
full_signal = np.load('carrier_or_mod_soft_or_hard/fc_2.528e9_sr_20e6_76db_coax-cable_tx-off_tx-carrier_tx-carrier-soft-aes_tx-carrier-hard-aes.npy')[8051081*2:16142453*2]

carrier = full_signal[:int(1e6)]
swaes = full_signal[-int(1e6)*9:-int(1e6)*9 + int(1e6)]
hwaes = full_signal[-int(1e6):]


'''
full_signal = np.load('carrier_or_mod_soft_or_hard/fc_2.528e9_sr_20e6_76db_coax-cable_tx-off_tx-carrier_tx-carrier-soft-aes_tx-carrier-hard-aes.npy')[8051081*2:16142453*2]

carrier = full_signal[:int(1e6)]
swaes = full_signal[-int(1e6)*9:-int(1e6)*9 + int(1e6)]
hwaes = full_signal[-int(1e6):]
full_signal = np.load('carrier_or_mod_soft_or_hard/fc_2.528e9_sr_8e6_76db_coax-cable_tx-off_tx-mod_tx-mod-soft-aes_tx-mod-hard-aes.npy')[833358*2:4376341*2]

# carrier 8msps
carrier = full_signal[:int(0.4e6)*2]

swaes = full_signal[-int(1e6)*2:-int(1e6)*2 + int(0.4e6)*2]
hwaes = full_signal[-int(0.4e6)*2:]
'''


ca = np.unwrap(np.angle(carrier))
sa = np.unwrap(np.angle(swaes))
ha = np.unwrap(np.angle(hwaes))

ca = [(ca[i] - ca[0]) for i in range(len(ca))]
sa = [(sa[i] - sa[0]) - ca[i] for i in range(len(sa))]
ha =[(ha[i] - ha[0]) - ca[i] for i in range(len(ha))]



ca2 = [ca[i+1] - ca[i] for i in range(len(ca)-1)]
sa2 = [sa[i+1] - sa[i] for i in range(len(sa)-1)]
ha2 = [ha[i+1] - ha[i] for i in range(len(ha)-1)]

'''
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
'''
#plt.plot(ca2)
plt.plot(sa2)
#plt.plot(ha2)

#plt.specgram(ha)
plt.show()

