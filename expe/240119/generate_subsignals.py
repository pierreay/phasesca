import numpy as np
import matplotlib.pyplot as plt


sig = np.load("whiten_off/fc_2.528e9_sr_8e6_76db_coax-cable_leak-gio-firmware-fix-packet.npy")
#sig = np.load("whiten_off/fc_2.528e9_sr_10e6_76db_coax-cable_leak-gio-firmware-fix-packet.npy")

#sig1, sig2 = sig[2000000:4500000], sig[1000000 + 5000000:-1000000 ] # 8
sig1, sig2 = sig[2000000:4500000], sig[5000000:] # 8
#plt.specgram(np.abs(sig1))
#plt.show()
#exit()

factor = []
signals = []
signal = []

n = 100
sig = sig1

for i in range(0, len(sig) - n, n):
  factor += [1000]*n if np.mean(np.abs(sig[i:i+n]))>1000 else [0]*n
  if np.mean(np.abs(sig[i:i+n]))>1000:
    signal = sig[i:i+n] if signal == [] else np.concatenate((signal, sig[i:i+n]))
  else:
    if len(signal) > 0:
      signals.append(signal)
    signal = []

count = 1
for signal in signals:
  np.save("no_aes/" + str(count), np.array(signal))
  count += 1
'''
angles = []
for signal in signals:
  angle = np.unwrap(np.angle(signal))
  angle = [angle[i] - angle[0] for i in range(len(angle))]
  #if len(angle) >= 12500 and len(angle) <= 17500:
  angles.append(angle)
  plt.plot(angle, color="red")
  

meancopy = []
indmax = min([len(angle) for angle in angles])
vals = [0 for _ in range(indmax)]
for i in range(0, indmax):
  valsi = 0
  for angle in angles:
    vals[i] += angle[i]
  vals[i] /= len(angles)

import copy  
meancopy = copy.copy(vals)

'''
#sig = np.load("record.npy")[-100000*2:]

factor = []
signals = []
signal = []
sig = sig2
for i in range(0, len(sig) - n, n):
  factor += [1000]*n if np.mean(np.abs(sig[i:i+n]))>1000 else [0]*n
  if np.mean(np.abs(sig[i:i+n]))>1000:
    signal = sig[i:i+n] if signal == [] else np.concatenate((signal, sig[i:i+n]))
  else:
    if len(signal) > 0:
      signals.append(signal)
    signal = []
    

count = 1
for signal in signals:
  '''
  plt.specgram(np.abs(signal))
  plt.show()
  plt.plot(np.abs(signal))
  plt.show()
  '''
  np.save("aes/" + str(count), np.array(signal))
  count += 1
  
'''
angles = []
for signal in signals:
  angle = np.unwrap(np.angle(signal))
  angle = [angle[i] - angle[0] for i in range(len(angle))]
  #if len(angle) >= 12500 and len(angle) <= 17500:
  angles.append(angle)
  plt.plot(angle, color = "blue")
 
indmax = min([len(angle) for angle in angles])
vals = [0 for _ in range(indmax)]
for i in range(0, indmax):
  valsi = 0
  for angle in angles:
    vals[i] += angle[i]
  vals[i] /= len(angles)
  
plt.plot(meancopy, color="green")
plt.plot(vals, color="orange") 
#plt.specgram(sig)
  #plt.specgram(signal)
#plt.plot(np.abs(sig))
#plt.plot(factor)
plt.show()
'''
