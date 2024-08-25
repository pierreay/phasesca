import numpy as np
import matplotlib.pyplot as plt
from scipy import signal


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
'''
sos = signal.butter(1, 5000, 'high', fs=56e6, output='sos')
normal = signal.sosfilt(sos, normal)
swaes = signal.sosfilt(sos, swaes)
hwaesecb = signal.sosfilt(sos, hwaesecb)
hwaesccm = signal.sosfilt(sos, hwaesccm)
'''
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
rotna = [na[i] - na[i-1] for i in range(1, len(na),1)][:100000 * 5]
rotsaa = [saa[i] - saa[i-1] for i in range(1, len(saa),1)][:100000 * 5]
rothaae = [haae[i] - haae[i-1] for i in range(1, len(haae),1)][:100000 * 5]
rothaac = [haac[i] - haac[i-1] for i in range(1, len(haac),1)][:100000 * 5]


# Display stuffs

fig, (ax1,ax2, ax3,ax4, ax5, ax6, ax7, ax8) = plt.subplots(8, sharex=True, constrained_layout=True)
ax1.plot((rotna)[:100000 * 5 // 2])
ax2.specgram(rotna)

ax3.plot((rotsaa)[:100000 * 5 // 2])
ax4.specgram(rotsaa)


ax5.plot((rothaae)[:100000 * 5 // 2])
ax6.specgram(rothaae)


ax7.plot((rothaac)[:100000 * 5 // 2])
ax8.specgram(rothaac)

plt.show()

