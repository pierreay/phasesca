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
    #assert template.shape == target.shape, "Traces to align should have the same length!"
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



aes_extracted = []
for i in os.listdir("aes_extracted"):
  signal2 = np.load("aes_extracted/" +i)
  if len(signal2) == 7000:
    aes_extracted.append(signal2[1000:-1000])
    

aes_signal_aligned = align_all(np.array(aes_extracted), sr=8e6)

angles = []
for aes_signal in aes_signal_aligned:
  angle = np.unwrap(np.angle(aes_signal))
  angle = [angle[i] - angle[0] for i in range(len(angle))]
  angles.append(angle)
  
  
indmax = min([len(angle) for angle in angles])
vals = [0 for _ in range(indmax)]
for i in range(0, indmax):
  valsi = 0
  for angle in angles:
    vals[i] += angle[i]
  vals[i] /= len(angles)

m = np.load("noaesmean.npy")
t = align_all(np.array([m[:5000] , signal.detrend(vals)]), sr=8e6)
plt.specgram(np.abs(
#butter_highpass_filter(
    
      t[1] - t[0]
 #   , cutoff=2e6, fs=8e6)
  
))
#plt.plot(t[1] - t[0])
plt.show()

  
for aes_signal in aes_signal_aligned:
  plt.subplot(211)
  plt.subplot(212)
  plt.specgram(np.abs(aes_signal_aligned[0]))
  plt.show()


