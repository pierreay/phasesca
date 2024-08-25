import matplotlib.pyplot as plt
import scipy.signal as signal
from scipy.signal import butter, lfilter
import numpy as np
import os


def butter_lowpass(cutoff, fs, order=5):
    nyq = 0.5 * fs
    normal_cutoff = cutoff / nyq
    b, a = butter(order, normal_cutoff, btype="low", analog=False)
    return b, a


def butter_highpass(cutoff, fs, order=5):
    nyq = 0.5 * fs
    normal_cutoff = cutoff / nyq
    b, a = butter(order, normal_cutoff, btype="high", analog=False)
    return b, a


def butter_lowpass_filter(data, cutoff, fs, order=5):
    assert(cutoff < fs / 2) # Nyquist
    b, a = butter_lowpass(cutoff, fs, order=order)
    y = lfilter(b, a, data)
    return y


def butter_highpass_filter(data, cutoff, fs, order=5):
    assert(cutoff < fs / 2) # Nyquist
    b, a = butter_highpass(cutoff, fs, order=order)
    y = lfilter(b, a, data)
    return y
    
def fshift(sig, shift):
    """Shift a signal SIG from the SHIFT offset.

    Shift a signal SIG to left (positive SHIFT) or right (negative
    SHIFT). Empty parts of the signal are completed using np.zeros of same
    dtype as SIG.

    SHIFT can be the output of the signal.correlate() function.

    """
    if shift > 0:
        sig = sig[shift:]
        sig = np.append(sig, np.zeros(shift, dtype=sig.dtype))
    elif shift < 0:
        sig = sig[:shift]
        sig = np.insert(sig, 0, np.zeros(-shift, dtype=sig.dtype))
    return sig

def align(template, target, sr):
    """Align a signal against a template.

    Return the TARGET signal aligned (1D np.array) using cross-correlation
    along the TEMPLATE signal, where SR is the sampling rates of signals. The
    shift is filled with zeros shuch that shape is not modified.

    NOTE: The cross-correlation shift is computed based on amplitude
    (np.float64) of signals.

    """
    # +++===+++++++++
    # +++++++===+++++ -> shift > 0 -> shift left target -> shrink template from right or pad target to right
    # ===++++++++++++ -> shift < 0 -> shift right target -> shrink template from left or pad target to left
    assert template.shape == target.shape, "Traces to align should have the same length!"
    assert template.ndim == 1 and target.ndim == 1, "Traces to align should be 1D-ndarray!"
    print(template.dtype, target.dtype)
    # Compute the cross-correlation and find shift across amplitude.
    lpf_freq     = sr / 4
    template_lpf = butter_lowpass_filter(template, lpf_freq, sr)
    target_lpf   = butter_lowpass_filter(target, lpf_freq, sr)
    corr         = signal.correlate(target_lpf, template_lpf)
    shift        = np.argmax(corr) - (len(template) - 1)
    # Apply shift on the raw target signal.
    r = fshift(target, shift)
    
    return r
def align_nb(s, nb, sr, template):
    s_aligned = [0] * nb
    for idx in list(range(0, nb)):
        s_aligned[idx] = align(template, s[idx], sr)
    s_aligned = np.array(s_aligned, dtype=s.dtype)
    return s_aligned

def align_all(s, sr, template=None):
    """Align the signals contained in the S 2D np.array of sampling rate
    SR. Use TEMPLATE signal (1D np.array) as template/reference signal if
    specified, otherwise use the first signal of the S array.

    """
    return align_nb(s, len(s), sr, template if template is not None else s[0])


no_aes_signals = []
for signal_name in os.listdir("no_aes"):
  no_aes_signals.append(np.load("no_aes/" + signal_name))
  

aes_signals = []
for signal_name in os.listdir("aes"):
  aes_signals.append(np.load("aes/" + signal_name))
  


no_aes_angles = []

for no_aes_signal in no_aes_signals:
  angle = signal.detrend(np.unwrap(np.angle(no_aes_signal)))
  angle = [angle[i] - angle[0] for i in range(len(angle))]
  if len(angle) == 16800:
    no_aes_angles.append(np.array(angle)[1000:-1000])

no_aes_angles = np.array(no_aes_angles)
no_aes_angles2 = align_all(no_aes_angles, sr=8e6)


'''
for no_aes_angle in no_aes_angles:
  plt.plot(no_aes_angle, color="blue")
'''
  
indmax = min([len(angle) for angle in no_aes_angles2])
vals = [0 for _ in range(indmax)]
for i in range(0, indmax):
  valsi = 0
  for angle in no_aes_angles2:
    vals[i] += angle[i]
  vals[i] /= len(no_aes_angles2)

plt.plot(vals, color="red")
plt.show()
for aes_signal in aes_signals[1:]:
  angle = signal.detrend(np.unwrap(np.angle(aes_signal)))
  angle = np.array([angle[i] - angle[0] for i in range(len(angle))])

  #plt.specgram(
  samples = aes_signal #np.abs(aes_signal)
  samples = samples[:min(len(vals), len(angle))]
#  angle = angle[:min(len(samples), len(angle))]
  #)
  plt.subplot(211)
  plt.specgram(np.abs(samples))
  
  plt.subplot(212)
  
  #plt.plot(angle[:min(len(angle), len(vals))])
  #plt.plot(angle[:min(len(angle), len(vals))] - vals[:min(len(angle), len(vals))])
  plt.specgram(
    np.abs(
      butter_highpass_filter(
        angle[:min(len(angle), len(vals))] - vals[:min(len(angle), len(vals))], 
       cutoff=1e6, fs=8e6
    )
    )
  )
  plt.show()
  #out = align_all(np.array([angle[:min(len(angle), len(vals))], vals[:min(len(angle), len(vals))]]), sr=8e6)
  '''
  plt.plot(vals[:min(len(angle), len(vals))])
  plt.show()
  plt.plot(np.abs(#butter_lowpass_filter(
    butter_highpass_filter(
      angle[:min(len(angle), len(vals))] - vals[:min(len(angle), len(vals))]
    , cutoff=1e6, fs=8e6)
  #, cutoff=3e6, fs=8e6)
  )
  )#, color="green")
  '''
  plt.show()
  
plt.plot(vals, color="purple")

'''  

for signal in aes_signals:
  angle = np.unwrap(np.angle(signal))
  angle = [angle[i] - angle[0] for i in range(len(angle))]
  plt.plot(angle, color='red')
'''
plt.show()
