import numpy as np
import matplotlib.pyplot as plt
from scipy import signal

# Crop signal to keep carrier only + carrier & AES sw + carrier & AES hw
'''
sig = np.load("with_aes_ecb_hard/fc_2.528e9_sr_8e6_76db_coax-cable_tx-off_tx-carrier_aes-ecb-soft_aes-ecb-hard_aes-ccm-hard.npy")[485895*2:1075872*2]
normal = sig[250000*2:350000*2]
swaes = sig[:100000*2]
hwaes = sig[400000*2:500000*2]

sig = np.load("with_aes_ecb_hard/fc_2.528e9_sr_56e6_76db_coax-cable_tx-off_tx-carrier_aes-ecb-soft_aes-ecb-hard_aes-ccm-hard.npy")[int(1.5e6)*2:]

normal = sig[:int(1e6)*2]
swaes = sig[int(1e6)*2*2:int(1e6)*3*2]
hwaesecb = sig[int(int(1e6)*3.3*2):int(int(1e6)*4.3*2)]
hwaesccm = sig[-int(1e6)*2:]
'''

sig = np.load("with_aes_ecb_hard/fc_2.528e9_sr_20e6_76db_coax-cable_tx-off_tx-carrier_aes-ecb-soft_aes-ecb-hard_aes-ccm-hard.npy")[int(0.6e6)*2:]#[561614*2 : 2093856*2]
#plt.specgram(np.abs(sig))
#plt.show()
normal = sig[:int(0.4e6)*2]
swaes = sig[int(0.6e6)*2:int(1e6)*2]
hwaesecb = sig[int(1.1e6)*2:int(1.5e6)*2]
hwaesccm = sig[int(1.7e6)*2:int(2.1e6)*2]

sos = signal.butter(1, 2000000, 'low', fs=20e6, output='sos')
normal = signal.sosfilt(sos, normal)
swaes = signal.sosfilt(sos, swaes)
hwaesecb = signal.sosfilt(sos, hwaesecb)
hwaesccm = signal.sosfilt(sos, hwaesccm)

# Split into three different signals, one for each case
'''
sig = np.load("with_aes_ecb_hard/fc_2.528e9_sr_20e6_76db_coax-cable_tx-off_tx-carrier_aes-ecb-soft_aes-ecb-hard_aes-ccm-hard.npy")[561614*2 : 2093856*2]
normal = sig[:int(0.4e6)*2]
swaes = sig[int(0.4e6)*3:int(0.4e6)*3 + int(0.4e6)*2]
hwaes = sig[-int(0.4e6)*2:]
'''

# Compute signal angle for each case, unwrap the result
na = (np.unwrap(np.angle(normal)))
saa =  (np.unwrap(np.angle(swaes)))
haae =   (np.unwrap(np.angle(hwaesecb)))
haac =   (np.unwrap(np.angle(hwaesccm)))

# set to relative to zero
na = [na[i] - na[0] for i in range(len(na))]
saa = [saa[i] - saa[0] for i in range(len(saa))]
haae = [haae[i] - haae[0] for i in range(len(haae))]
haac = [haac[i] - haac[0] for i in range(len(haac))]

# compute angle rotation
rotna = [na[i] - na[i-1] for i in range(1, len(na),1)][:1000000]
rotsaa = [saa[i] - saa[i-1] for i in range(1, len(saa),1)][:1000000]
rothaae = [haae[i] - haae[i-1] for i in range(1, len(haae),1)][:1000000]
rothaac = [haac[i] - haac[i-1] for i in range(1, len(haac),1)][:1000000]


# Display stuffs

fig, (ax1,ax2, ax3,ax4, ax5, ax6, ax7, ax8) = plt.subplots(8)
ax1.plot((rotna))
ax2.specgram(rotna)

ax3.plot((rotsaa))
ax4.specgram(rotsaa)


ax5.plot((rothaae))
ax6.specgram(rothaae)


ax7.plot((rothaac))
ax8.specgram(rothaac)

plt.show()

