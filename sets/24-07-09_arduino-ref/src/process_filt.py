#!/usr/bin/env python3

import sys
import os
from os import path
from functools import partial

import numpy as np

from scaff import legacy
from scaff import processors
from scaff import dsp
from scaff import config
from scaff import io
from scaff import logger as l
from scaff import helpers

if __name__ == "__main__":
    load_path = path.abspath(sys.argv[1])
    save_path = path.abspath(sys.argv[2])
    config_path = path.abspath(sys.argv[3])
    config.AppConf(config_path)
    # Loader.
    loader = io.IO(io.IOConf(config.APPCONF))
    loader.conf.data_path = load_path
    # Processing configuration.
    processing = processors.ProcessingExtract(load_path=load_path, save_path=save_path)
    processing.config = legacy.ExtractConf().load(config.APPCONF)
    processing.config.num_traces_per_point_min = 10
    processing.config.num_traces_per_point = 25
    processing.config.min_correlation = 0
    # Filter configuration.
    if sys.argv[4] == "lh1e6":
        processing.filter_amp = dsp.LHPFilter("high", 1e6, order=6, enabled=True)
        processing.filter_phr = dsp.LHPFilter("low",  1e6, order=6, enabled=True)
    elif sys.argv[4] == "l1e6":
        processing.filter_amp = dsp.LHPFilter("high", 1e6, order=6, enabled=False)
        processing.filter_phr = dsp.LHPFilter("low",  1e6, order=6, enabled=True)
    elif sys.argv[4] == "l2e6":
        processing.filter_amp = dsp.LHPFilter("high", 2e6, order=6, enabled=False)
        processing.filter_phr = dsp.LHPFilter("low",  2e6, order=6, enabled=True)
    elif sys.argv[4] == "lh500e3":
        processing.filter_amp = dsp.LHPFilter("high", 500e3, order=6, enabled=True)
        processing.filter_phr = dsp.LHPFilter("low",  500e3, order=6, enabled=True)
    elif sys.argv[4] == "lh50e3":
        processing.filter_amp = dsp.LHPFilter("high", 50e3, order=6, enabled=True)
        processing.filter_phr = dsp.LHPFilter("low",  50e3, order=6, enabled=True)
    elif sys.argv[4] == "hl50e3":
        processing.filter_amp = dsp.LHPFilter("low",  50e3, order=6, enabled=True)
        processing.filter_phr = dsp.LHPFilter("high", 50e3, order=6, enabled=True)
    else:
        assert False, "Bad filter!"
    # Processing execution.
    try:
        processor = processors.Processor(processing, helpers.ExecOnce(), stop=partial(loader.count), ncpu=0).start()
    except Exception as e:
        l.LOGGER.critical("Error during extraction processing: {}".format(e))
        raise e
    # Save bad list.
    l.LOGGER.info("Save bad processing indexes to: {}".format(path.join(save_path, "bad_list.npy")))
    np.save(path.join(save_path, "bad_list.npy"), processor.bad_list)
