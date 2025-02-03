# Abstract

This artifact consists of software and data to reproduce the main results of section 7.2 of our paper.
The software is a research project (not production ready) and is composed of Python and C source code.
Everything is automated inside a Docker container, and dependencies and manual installation are referenced under the main project web page.
The data mainly consists of Numpy arrays containing complex numbers representing I/Q data.

# Introduction

This guide will help you reproduce the main results of our paper.
Note that this is a small part of our project.
The full project can be found on GitHub at [`pierreay/phase_data`](https://github.com/pierreay/phase_data/).

To fully reproduce this attack, in the first stage, one would have to first acquire a dataset using hardware by:
1. Flashing a firmware on the evaluated SoC (DUT) and installing the radio tooling.
2. Setup the experimental hardware, including the attacker host computer, the radio, the antenna and amplifiers, the DUT.
3. Performing a dataset collection (up to several hours) in a stable environment.

In a second stage, without any hardware:
4. Post-processing the dataset to extract amplitude and phase traces from the large raw I/Q signal.

As you imagine, this is fairly complex and long without prior experience.
Hence, in this guide, we provides representative datasets on which we can complete the step 4 of the entire attack, which do not require any hardware.
As such, we uploaded datasets on [Zenodo](https://zenodo.org/), an open platform for hosting research data:
> Ayoub (2025) PhaseSCA: XXX Dataset, Zenodo. DOI:
> XX.XXXX/zenodo.XXXXXXXX. URL: <https://zenodo.org/records/XXXXXXXX>

For every datasets, we will execute the following automatized steps:
- Performing an non-profiled side-channel attack (close to a Correlation Power Attack *a.k.a* CPA).
- Performing a profiled side-channel attack (close to a Template Attack *a.k.a* TA), composed of two steps:
    1. Creating a profile (*i.e.*, a template) from a training subset to learn the leakage model.
    2. Leveraging the profile, attack on an attack subset.

# Setup

First, we will setup necessary tools, downloading the code and the data.

## Download

Clone our repository (~ 100 MB) in the directory of your choice:

    git clone https://github.com/pierreay/phase_data/

Moreover, manually download the two aforementioned datasets located at [`zenodo.org/records/XXXXXXXX`](https://zenodo.org/records/XXXXXXXX) which have been publicly uploaded on Zenodo (~ XXX GB).

## Installation

We will setup a temporary Docker container for reproducing the attacks, in order to not clutter the host system.

First, ensure that both [Docker](https://www.docker.com/) and its [buildx](https://docs.docker.com/build/concepts/overview/) builder are installed on the host machine, following the host distribution documentation (for example on [Ubuntu](https://docs.docker.com/engine/install/ubuntu/) or [Arch Linux](https://wiki.archlinux.org/title/Docker)).

Second, move the downloaded datasets inside the Docker folder:

    cd phase_data/docs/2025-01-23_tches-artifact
    mv -t . /PATH/TO/DOWNLOADED/XXX.tar.bz2

Third, download and initialize the Docker image leveraging the `Dockerfile`:

    make build

It will download around XXX GB and decompress the datasets that have been downloaded previously inside the container.
The image and containers will be cleaned up at the end, no files will be left or modified on the host system.

The Docker should now be ready to be used.
In the following, we assume that the reader is connected to the Docker container through SSH by running:

    make shell

Note that you can use the `DOCKER_LMOUNT` variable to mount the directory from the host containing the datasets:

    make shell DOCKER_LMOUNT=/PATH/TO/phase_data/sets

The X11 display should be shared between the container and the host.
To test this, one may run:

    xclock

If the clock is displayed, good to go.
If an error of the type `Authorization required, but no authorization protocol specified` arise, run the following on the host system:

    sudo xhost +local:docker=

Exit and restart the Docker container, and the X11 display sharing should work.


# Reproducing the attacks

## Step-by-step guide for attacking nRF52

For our first attacks, we propose to attack the nRF52, a wide-spread SoC in the IoT ecosystem.

> [!NOTE]
> Reproducing this step-by-step guide should take less than half an hour.

### Attacking nRF52 with non-profiled attack

We will first perform a non-profiled attack (easier compared to a profiled attack) to reproduce one point of our Figure 12.a of the paper.

First, move to the dataset directory and extract the I/Q signals:

```bash
cd /home/rootless/host_sets/24-07-04_nrf52-ref
tar xvf attack.tar
```

> [!TIP]
> For future reference, here are the meanings of all the directories:
> - `attack`    : Original collected raw attack set.
> - `attack_*`  : Post-processed and filtered attack set(s).
> - `train`     : Original collected raw train set.
> - `train_*`   : Post-processed and filtered train set(s).
> - `bin`       : Binaries (e.g., firmware flashed on DUT).
> - `csv_*`     : CSVs containing attack results (used for plotting paper figures).
> - `logs_*`    : Text files containing attack logging.
> - `plots_*`   : Plots of attack results based on CSVs.
> - `profile_*` : Template used for profiled attacks based on a specific post-processing train set.
> - `src`       : Scripts used to build, process and attack the dataset.

Since our tools were improved during the research process, sometimes without backward compatibility, we will sometimes have to checkout the correct versions of our tools for this dataset.
Let's do this for the post-processing:

```bash
./src/git-checkout.sh process
```

One may visually inspect a single trace in complex numbers format (storing IQ data, *i.e.*, a complex-valued signal) by running the following command:

```bash
soapyrx plot ./attack/0_iq.npy
```

This will plot you different components of the trace at index 0:

![img](gfx/24-07-04_nrf52-ref_attack_0.png)

In this plot, you can see:
1. The first row showing the amplitude on the left and the phase on the right, both in time domain.
1. The second row showing the spectrogram for the I/Q on the left, and the spectrogram (*i.e.*, frequency domain representation) for the phase component on the right.
Note the symmetry (amplitude/phase) in the first row that is not true in the second row (IQ/phase).

This IQ recording is the direct output of our SDR during signal acquisition, without any further post-processing.
Hence, it contains both the amplitude and phase information that are exploited separately in the paper.

As explained in the Section 7.2 from our paper, we will use filters to isolate the amplitude-modulated and phase-modulated signals.
During our experiments, this was automated by the `src/process.sh` script with different filters, but to use the one of the paper, one may run the following commands:

```bash
mkdir -p attack_filt_lh1e6
cp -t attack_filt_lh1e6 attack/pt.txt attack/key.txt
./src/process_filt.py attack attack_filt_lh1e6 src/collect.toml lh1e6
```

The following plots may vary depending on the version (*i.e.*, commit) of `scaff` that have been checkout by the `git-checkout.sh` script.
For the latest version, this is an example plot that show you a preview of what will be extracted:

![img](gfx/24-07-04_nrf52-ref_attack_filt_lh1e6_template.png)

In this plot, you can see the amplitude extraction on the left side, and the phase extraction on the right side.
All signals (for both time-domain and frequency-domain) are shown after the filtering stage and the amplitude / phase conversion, so no IQ data is shown on this plot.
1. On the first row, you can see the signal acquired with our SDR in the time-domain, where each green and red dashed lines represent the boundaries (beginning and the end) of the final extracted traces.
2. On the second row, you can see the same signal as the first row but in the frequency domain in function of time (spectrogram).
3. On the third row, you can see how each extracted traces align themselves.
4. On the fourth and final row, you can see the resulting extracted trace, averaged from the aligned traces of the third row.

You can quit the plot by hitting `q`, and the post-processing will begin.
This will post-process our I/Q data from the `attack` directory and storing the result into the `attack_filt_lh1e6` directory, extracting traces for the side-channel attack, using a high-pass filter of 1 MHz for the amplitude traces and a low-pass filter of 1 MHz for the phase traces.
The filters width have been determined experimentally by trial and error and is specific to each DUT model.
A visual inspection of the leakage in the frequency domain give the attacker a first approximation of the correct width to use.
By default, it will process 2000 for this dataset, but you can stop it manually at 800/2000 processed traces by hitting CTRL+C (because we already know from our paper that 800 traces is sufficient to perform a full key recovery).

One may visually inspect a single or multiples post-processed trace(s) in float numbers format (real-valued trace) by running the following command:

```bash
scaff show --base 0 --offset 3 --cumulative attack_filt_lh1e6 phr
```

![img](gfx/24-07-04_nrf52-ref_attack_filt_lh1e6_0_phr.png)

On this plot, you can see the 3 first phase shift traces of the dataset plotted on the same plot.
Those traces are obtained by the post-processing, which perform signal alignment, averaging, and demodulation, *i.e.*, going from a complex-valued signal to a real-valued trace representing the amplitude or the phase.
One may notice that they are perfectly aligned, which is required to have a successful attack.
You can use `amp` instead of `phr` to visualize amplitude traces instead of phase shift traces.
Moreover, you can use `scaff show --help` to display the help.

Now, we want to start attacking using a Correlation Radio Analysis (CRA), let's checkout the version of our tools needed to do this:

```bash
./src/git-checkout.sh attack_cra
```

We can now proceed to a single attack using 150 amplitude traces, by running the following:

```bash
scaff --log --loglevel INFO cra --no-plot --norm --data-path attack_filt_lh1e6 --start-point 0 --end-point 0 --num-traces 150 --no-bruteforce --comp amp
```

It will display a first plot of all traces to ensure that they are correctly aligned, as well as a second plot with the resulting average.
The attack will then start by attacking each subkey (*i.e.*, key bytes) individually, which can take from 10 seconds for a hundred of traces to several minutes for thousands of traces.
At the end, you should see the following result:

```txt
Best Key Guess:   2c   36   5e   69   6d   7e   aa   de   6a   cd   3f   4f   a2   c0   94   3a
Known Key:        2c   36   dd   69   6d   85   76   de   96   cd   3f   4f   89   76   94   6a
PGE:             000  000  109  000  000  001  055  000  007  000  000  000  030  001  000  094
HD:              000  000  003  000  000  007  005  000  006  000  000  000  004  005  000  002
SUCCESS:           1    1    0    1    1    0    0    1    0    1    1    1    0    0    1    0
NUMBER OF CORRECT BYTES: 9
HD SUM:                  32

Starting key ranking using HEL
results rank estimation
nb_bins = 512
merge = 2
Starting preprocessing
Clearing memory
min: 2^49.09905512
actual rounded: 2^49.55726301
max: 2^49.92155851
time enum: 0.257056 seconds
```

> [!TIP]
> This shows the guessed key using the side-channel, the actual known key, and different metrics from the attack (Correct bytes, Hamming Distance (HD), Partial Guess Entropy (PGE), Key Rank).

In this example, we have an estimated key rank of $2^{49}$, which means that after our attack, we still have to test $2^{49}$ keys before finding the correct key.
In other words, we reduced the AES key space from 128 bits to 49 bits.
This result corresponds to the point of 150 traces in Figure 12.a for amplitude traces.

You can now try with other traces instead of amplitude traces, like in the core contribution of our paper, the `phr` parameter for the phase traces and the `recombined` parameter for the Multi-Channel Fusion Attack (MCFA), which recombines the amplitude and phase traces to improve the results compared to traditional attacks.

```bash
scaff --log --loglevel INFO cra --no-plot --norm --data-path attack_filt_lh1e6 --start-point 0 --end-point 0 --num-traces 150 --no-bruteforce --comp phr
```

```text
Best Key Guess:   2c   fc   dd   69   c2   85   76   de   96   cd   3f   4f   89   86   70   6a
Known Key:        2c   36   dd   69   6d   85   76   de   96   cd   3f   4f   89   76   94   6a
PGE:             000  001  000  000  006  000  000  000  000  000  000  000  000  009  001  000
HD:              000  004  000  000  006  000  000  000  000  000  000  000  000  004  004  000
SUCCESS:           1    0    1    1    0    1    1    1    1    1    1    1    1    0    0    1
NUMBER OF CORRECT BYTES: 12
HD SUM:                  18

Starting key ranking using HEL
results rank estimation
nb_bins = 512
merge = 2
Starting preprocessing
Clearing memory
min: 2^19.44428495
actual rounded: 2^19.95336239
max: 2^20.35668945
time enum: 0.353109 seconds
```

As you can see, we have in this attack a key rank of $2^{19}$ using phase traces.

One may use the `--bruteforce` flag to bruteforce the key in a few seconds at the end of the attack, and perform a full key recovery:

```bash
scaff --log --loglevel INFO cra --no-plot --norm --data-path attack_filt_lh1e6 --start-point 0 --end-point 0 --num-traces 150 --bruteforce --comp phr
```

```text
Starting preprocessing
current rank : 2^1
current rank : 2^1.584962501
current rank : 2^2.584962501
current rank : 2^3.321928095
current rank : 2^4.169925001
current rank : 2^5.129283017
current rank : 2^6.022367813
current rank : 2^7.139551352
current rank : 2^8.124121312
current rank : 2^9.103287808
current rank : 2^10.09671515
current rank : 2^11.01611184
current rank : 2^12.03204573
current rank : 2^13.01941698
current rank : 2^14.08870544
current rank : 2^15.01902598
current rank : 2^16.03206726
current rank : 2^17.01976445
current rank : 2^18.09110476
current rank : 2^19.03235519

KEY FOUND!!!
2c 36 dd 69 6d 85 76 de 96 cd 3f 4f 89 76 94 6a
```

But we can do even better using MCFA, which recombines the information from the amplitude traces and from the phase traces inside a single attack:

```bash
scaff --log --loglevel INFO cra --no-plot --norm --data-path attack_filt_lh1e6 --start-point 0 --end-point 0 --num-traces 150 --no-bruteforce --comp recombined
```

```text
[scaff] [INFO] Perform recombination...
Best Key Guess:   2c   36   dd   69   6d   85   76   de   96   cd   3f   4f   89   c0   94   6a
Known Key:        2c   36   dd   69   6d   85   76   de   96   cd   3f   4f   89   76   94   6a
PGE:             000  000  000  000  000  000  000  000  000  000  000  000  000  001  000  000
HD:              000  000  000  000  000  000  000  000  000  000  000  000  000  005  000  000
SUCCESS:           1    1    1    1    1    1    1    1    1    1    1    1    1    0    1    1
NUMBER OF CORRECT BYTES: 15
HD SUM:                  5

Starting key ranking using HEL
results rank estimation
nb_bins = 512
merge = 2
Starting preprocessing
Clearing memory
min: 2^2
actual rounded: 2^3.321928095
max: 2^4.087462841
time enum: 0.310211 seconds
```

The key rank is of $2^{3}$, which means that we have 8 keys to test before finding the correct one after our side-channel attack, which attacked a 128 bits AES key.

### Attacking nRF52 with profiled attack

We will now perform a profiled attack to reproduce one point of our Figure 11.a of the paper.
This attack requires first to compute a profile of the leakage using a training dataset.
We will be able to perform the actual attack using the profile and an attack dataset in a second time.

> [!IMPORTANT]  
> Ensure that you completed the attack from the previous section, ensuring that everything is working and well understood.

Ensure that you are in the dataset directory, and extract I/Q signals for both datasets:

```bash
cd /home/rootless/host_sets/24-07-04_nrf52-ref
tar xvf train.tar
tar xvf attack.tar
```

Checkout the correct versions of our tools for this dataset for post-processing:

```bash
./src/git-checkout.sh process
```

As explained in previous section, perform the filtering post-processing step, for both the training set and the attack set:

```bash
mkdir -p train_filt_lh1e6
cp -t train_filt_lh1e6 train/pt.txt train/key.txt
./src/process_filt.py train train_filt_lh1e6 src/collect.toml lh1e6
````

You can stop the process after 4000 traces, because this is the number of traces that we used for our profile in our paper.

```bash
mkdir -p attack_filt_lh1e6
cp -t attack_filt_lh1e6 attack/pt.txt attack/key.txt
./src/process_filt.py attack attack_filt_lh1e6 src/collect.toml lh1e6
```

You can stop the process after 100 traces, since we will reproduce the result of attacking using 100 traces of our Figure 11.a.

#### Profiling

Now that we want to start attacking using a profiled attack instead of a non-profiled attack, let's checkout the version of our tools needed to do this:

```bash
./src/git-checkout.sh attack_ta
```

Let us create the first requirement of this attack, a profile for the amplitude:

```bash
mkdir -p profile_filt_lh1e6/amp_4000_r_1
scaff profile --plot --norm --data-path train_filt_lh1e6 --start-point 0 --end-point 0 --num-traces 4000 --comp amp profile_filt_lh1e6/amp_4000_r_1 --pois-algo r --num-pois 1 --poi-spacing 1 --variable p_xor_k --align --fs 10e6
```

> [!TIP]
> Those non-obvious options means:
> - **norm:** Normalize the traces after loading.
> - **start-point / end-point:** Truncate the traces between those points.
> - **pois-algo:** Use the $k-\text{fold}$ $\rho-\text{test}$ to find informative point of interests (PoIs).
> - **num-pois:** Use only 1 PoI per subbytes.
> - **variable p_xor_k:** Use the $l = p \oplus k$ leakage variable, with $p$ the plaintext and $k$ the key.

You should see two plots as the following ones:
![profile_corr](./gfx/24-07-04_nrf52-ref_attack_ta_filt_lh1e6_profile_corr.png) 
![profile_pois](./gfx/24-07-04_nrf52-ref_attack_ta_filt_lh1e6_profile_pois.png) 

The first one shows the correlation between the traces and the input for each points.
The second one shows the computed profile, plotting each expected trace value for every possible input value.

We must do the same for the phase traces:

```bash
mkdir -p profile_filt_lh1e6/phr_4000_r_1
scaff profile --plot --norm --data-path train_filt_lh1e6 --start-point 0 --end-point 0 --num-traces 4000 --comp phr profile_filt_lh1e6/phr_4000_r_1 --pois-algo r --num-pois 1 --poi-spacing 1 --variable p_xor_k --align --fs 10e6
```

#### Attacking

We can now proceed to a single attack using 100 amplitude traces, by running the following:

```bash
scaff attack --plot --norm --data-path attack_filt_lh1e6 --start-point 0 --end-point 0 --num-traces 100 --no-bruteforce --comp amp profile_filt_lh1e6/amp_4000_r_1 --attack-algo pcc --variable p_xor_k --align --fs 10e6
```

It will show a first plot to ensure that traces are correctly aligned, then, you should see this output:

```txt
Best Key Guess:   2e   32   dc   6a   6d   87   73   de   97   c7   3b   4d   89   75   97   6a
Known Key:        2c   36   dd   69   6d   85   76   de   96   cd   3f   4f   89   76   94   6a
PGE:             001  005  007  001  000  002  004  000  002  001  015  005  000  003  003  000
HD:              001  001  001  002  000  001  002  000  001  002  001  001  000  002  002  000
SUCCESS:           0    0    0    0    1    0    0    1    0    0    0    0    1    0    0    1
NUMBER OF CORRECT BYTES: 4
HD SUM:                  17

Starting key ranking using HEL
results rank estimation
nb_bins = 512
merge = 2
Starting preprocessing
Clearing memory
min: 2^41.68879949
actual rounded: 2^42.59268258
max: 2^43.29063472
time enum: 0.280022 seconds
```

In this attack, we have an estimated key rank of $2^{42}$, which means that after our attack, we still have to test $2^{42}$ keys before finding the correct key.
This result corresponds to the point of 100 traces in Figure 11.a for the amplitude traces.

You can now try with other traces instead of amplitude traces, like in the core contribution of our paper, the `phr` parameter for the phase traces and the `recombined` parameter for the Multi-Channel Fusion Attack (MCFA), which recombines the amplitude and phase traces to improve the results compared to traditional attacks.

```bash
scaff attack --no-plot --norm --data-path attack_filt_lh1e6 --start-point 0 --end-point 0 --num-traces 100 --no-bruteforce --comp phr profile_filt_lh1e6/phr_4000_r_1 --attack-algo pcc --variable p_xor_k --align --fs 10e6
```

```text
Best Key Guess:   2e   36   dd   69   2d   8d   75   f7   97   c9   3e   7e   85   76   94   6a
Known Key:        2c   36   dd   69   6d   85   76   de   96   cd   3f   4f   89   76   94   6a
PGE:             003  000  000  000  001  001  001  016  001  002  002  004  006  000  000  000
HD:              001  000  000  000  001  001  002  003  001  001  001  003  002  000  000  000
SUCCESS:           0    1    1    1    0    0    0    0    0    0    0    0    0    1    1    1
NUMBER OF CORRECT BYTES: 6
HD SUM:                  16

Starting key ranking using HEL
results rank estimation
nb_bins = 512
merge = 2
Starting preprocessing
Clearing memory
min: 2^37.28676196
actual rounded: 2^38.10622567
max: 2^38.75254885
time enum: 0.263763 seconds
```

As you can see, we have in this attack a key rank of $2^{38}$ using phase traces, which is 4 bits better than with amplitude here.

Finally, we can do even better using MCFA, which recombines the information from the amplitude traces and from the phase traces inside a single attack:

```bash
scaff attack-recombined --no-plot --norm --data-path attack_filt_lh1e6 --start-point 0 --end-point 0 --num-traces 100 --comp amp profile_filt_lh1e6/{}_4000_r_1 --attack-algo pcc --variable p_xor_k --align --fs 10e6 --corr-method add
```

```text
comp=recombined_corr ; corr_method=add
Best Key Guess:   2e   32   dd   69   6d   85   73   d6   97   cd   3e   4f   89   76   94   6a
Known Key:        2c   36   dd   69   6d   85   76   de   96   cd   3f   4f   89   76   94   6a
PGE:             002  001  000  000  000  000  001  003  001  000  002  000  000  000  000  000
HD:              001  001  000  000  000  000  002  001  001  000  001  000  000  000  000  000
SUCCESS:           0    0    1    1    1    1    0    0    0    1    0    1    1    1    1    1
NUMBER OF CORRECT BYTES: 10
HD SUM:                  7

Starting key ranking using HEL
results rank estimation
nb_bins = 512
merge = 2
Starting preprocessing
Clearing memory
min: 2^15.86665109
actual rounded: 2^17.31663509
max: 2^18.40980111
time enum: 0.258705 seconds
```

We just went from a key rank of $2^{42}$ using amplitude traces to $2^{17}$ using multi-channel fusion attack, recombining amplitude and phase attack results.
This result correspond to the point at trace index 100 of purple curve of the Figure 11.a of the paper.

## Automated scripts for reproducing figures and attacking others targets

The four datasets used in the paper are the following, from the repository root:
- [sets/24-07-04_nrf52-ref](../../sets/24-07-04_nrf52-ref) : For the nRF52.
- [sets/24-10-10_nrf51-ref](../../sets/24-10-10_nrf51-ref) : For the nRF51.
- [sets/24-07-09_stm32l1-ref](../../sets/24-07-09_stm32l1-ref) : For the STM31-L1.
- [sets/24-07-09_arduino-ref](../../sets/24-07-09_arduino-ref) : For the ATmega328 (on the Arduino).

> [!WARNING]
> Reproducing all plots of the paper may requires up to 24 hours of computation from a standard desktop computer.

From every one of them, we can reproduce all the attacks and plots using the following steps:

1. Extract the `attack.tar` and `train.tar` archives containing the I/Q signals in the dataset directory:

```bash
cd $DATASET
tar xvf train.tar
tar xvf attack.tar
```

> [!CAUTION]
> Do not `cd` into the `src` directory, always execute scripts from the dataset directory like the following.

2. Post process the signals by filtering them and extract the traces:

```bash
./src/process.sh
```

3. Create the profiles for the profiled attacks:

```bash
./src/profile.sh
```

4. Plot the attacks performance for the profiled attacks:

```bash
./src/attack_plot.sh
```

5. Plot the attacks performance for the non-profiled attacks:

```bash
./src/attack_plot_cra.sh
```

The final plots will be located in `plots_filt_lh1e6` for the nRF52, the nRF51 and the STM32, but in `plots` for the ATmega (on the Arduino).

# Clean

Finally, once the Docker container is exited, one may run the following to clean the image:

    make clean

# Conclusion

In this demonstration, we reproduced the most important results of the paper regarding attack performance improvement leveraging unattended phase traces.
All other claims can also be reproduced by leveraging our full dataset repository, including scripts and data.
