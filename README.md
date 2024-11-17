# About

Main repository of the PhaseSCA project.

This repository contains the data and experiments of the project.

## Publication

This project led to the following [TCHES](https://tches.iacr.org/) publication: *Pierre Ayoub, Aurélien Hernandez, Romain Cayre, Aurélien Francillon, Clémentine Maurice (2025), PhaseSCA: Exploiting Phase-Modulated Emanations in Side Channels. IACR Transactions on Cryptographic Hardware and Embedded Systems (TCHES'25). https://hal.science/hal-04726109*

This project is also part of my Ph.D. Thesis, not yet published.

## How to cite

``` bibtex
@Article{ayoub25phasesca,
  title               = {{PhaseSCA: Exploiting Phase-Modulated Emanations in Side Channels}},
  author              = {Ayoub, Pierre and Hernandez, Aur{\'e}lien and Cayre, Romain and Francillon, Aur{\'e}lien and Maurice, Cl{\'e}mentine},
  journal             = {{IACR Transactions on Cryptographic Hardware and Embedded Systems}},
  hal_local_reference = {Rapport LAAS n{\textdegree} 25001},
  publisher           = {{IACR}},
  year                = {2025},
  keywords            = {Side-channel attacks ; Power/Electromagnetic analysis ; Unintended modulation ; Phase modulation ; Angle modulation ; Clock jitter},
  url                 = {https://hal.science/hal-04726109},
  pdf                 = {https://hal.science/hal-04726109v1/file/paper.pdf},
  hal_id              = {hal-04726109},
  hal_version         = {v1},
  affiliations        = {Eurecom, Univ Lille, CNRS, Inria},
}
```

# Requirements

## Software

- **[phase_fw](https://github.com/pierreay/phase_fw.git)**

Source code used to flash the firmware we used on our target devices during our attacks.
Required to perform the data collection.

- **[SoapyRX](https://github.com/pierreay/soapyrx.git)** 

Utility used to record I/Q signals from the target device emanations using a software-defined radio (SDR).
Required to perform the data collection.

- **[SCAFF](https://github.com/pierreay/scaff.git)**

Used to to process and analyze the datasets composed of I/Q signals.
Required to perform the data analysis and the attacks.

## Hardware

- **SDR**: Pick one supported by SoapyRX.
- **Near-field probes**: Can be a COTS one or a handmade for frequencies between 8 and 128 MHz.
- **Device Under Test (DUT)**: Pick one described in the paper.

# Storage

This repository is managed using [git-annex](https://git-annex.branchable.com/).
Around 400 GB of data is currently deduplicated and spread across 4 instances, including workstations and external mass storage devices.

# Files

- **[expe](./expe)**

Experiments of the project.

- **[sets](./sets)**

Datasets built during the project.

- **[src](./src)**

Scripts to work with the repository.
