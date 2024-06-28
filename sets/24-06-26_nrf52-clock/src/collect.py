#!/usr/bin/python3

import click
import collections
import os
from os import path, system
import serial
import sys
import time
import logging
import signal
import tomllib
from functools import partial

import numpy as np
from matplotlib import pyplot as plt
from tqdm import tqdm
from tqdm.contrib.logging import logging_redirect_tqdm

import scaff.analyze
import scaff.log
import soapyrx.core
import soapyrx.logger

LOGGER = logging.getLogger('collect')
HANDLER = logging.StreamHandler()
CONFIG = None

# Time to sleep between two serial communications.
TIME_SLEEP_SER = 0.05

FirmwareMode = collections.namedtuple(
    "FirmwareMode",
    [
        "mode_command",         # command for entering the test mode
        "repetition_command",   # command for triggering repeated execution (or None)
        "action_command",       # command for starting (single or repeated) action
        "have_keys",            # whether the test mode works with keys
    ])

# These are the firmware modes we support; they can be selected with the "mode"
# key in the "firmware" section of the config file.
TINY_AES_MODE = FirmwareMode(
    have_keys=True, mode_command='n', repetition_command='n', action_command='r')
TINY_AES_MODE_SLOW = FirmwareMode(
    have_keys=True, mode_command='n', repetition_command=None, action_command='e')

# Global settings, for simplicity
DEVICE = None
BAUD = None
COMMUNICATE_SLOW = None
YKUSH_PORT = None
CONTINUE = None

@click.group()
@click.argument("config", type=str)
@click.option("-d", "--device", default="/dev/ttyACM0", show_default=True,
              help="The serial dev path of device tested for screaming channels")
@click.option("-b", "--baudrate", default=115200, show_default=True,
              help="The baudrate of the serial device")
@click.option("-y", "--ykush-port", default=0, show_default=True,
              help="If set, use given ykush-port to power-cycle the device")
@click.option("-s", "--slowmode", is_flag=True, show_default=True,
              help=("Enables slow communication mode for targets with a small"
                    "serial rx-buffer"))
@click.option("-l", "--loglevel", default="INFO", show_default=True,
              help="The loglevel to be used ([DEBUG|INFO|WARNING|ERROR|CRITICAL])")
@click.option("--continue/--no-continue", "continue_flag", default=False, show_default=True,
              help="Either to continue the main loop or quit on error.")
def cli(config, device, baudrate, ykush_port, slowmode, loglevel, continue_flag, **kwargs):
    """
    Reproduce screaming channel experiments with vulnerable devices.

    This script assumes that the device has just been plugged in (or is in an
    equivalent state), that it is running our modified firmware, and that an SDR
    is available. It will carry out the chosen experiment, producing a trace and
    possibly other artifacts. 

    Call any experiment with "--help" for details. You most likely want to use
    "collect".
    """
    global CONFIG, DEVICE, BAUD, COMMUNICATE_SLOW, YKUSH_PORT, CONTINUE, LOGGER, HANDLER
    with open(config, "rb") as f:
        CONFIG = tomllib.load(f)
    DEVICE = device
    BAUD = baudrate
    COMMUNICATE_SLOW = slowmode
    YKUSH_PORT = ykush_port
    CONTINUE = continue_flag
    HANDLER.setFormatter(logging.Formatter("[%(levelname)s] %(message)s"))
    LOGGER.addHandler(HANDLER)
    LOGGER.setLevel(loglevel)

def _open_serial_port():
    LOGGER.info("Opening serial port")
    return serial.Serial(DEVICE, BAUD, timeout=5)

def _close_serial_port(ser, signum = None, frame = None):
    LOGGER.info("Close serial port")
    ser.write(b'q')     # quit tiny_aes mode
    LOGGER.debug((ser.readline()))
    ser.write(b'e')     # turn off continuous wave (nop if not enabled)
    time.sleep(TIME_SLEEP_SER)
    ser.close()
    
def _encode_for_device(data):
    """
    Encode the given bytes in our special format.
    """
    return " ".join(str(data_byte) for data_byte in data)


def _send_parameter(ser, command, param):
    """
    Send a parameter (key or plaintext) to the target device.

    The function assumes that we've already entered tiny_aes mode.
    """
    command_line = '%s%s\r\n' % (command, _encode_for_device(param))
    LOGGER.debug('Sending command: %s' % command_line[:-1])
    if not COMMUNICATE_SLOW:
        ser.write(command_line.encode())
    else:
        for p in command_line.split(' '):
            ser.write((p+' ').encode())
            time.sleep(TIME_SLEEP_SER)

    LOGGER.debug('Waiting check....')
    x = ser.readline()
    LOGGER.debug ("Received: "+x.decode()[:-1])
    if len(x) == 0:
        LOGGER.debug("Nothing received on timeout, ignoring error")
        return 
    #check = ''.join(chr(int(word)) for word in x.split(' '))
    # -- create check like this instead for ESP32:
    #response = ser.readline()
    #response = [ a for a in x.decode().split(' ') if a.isdigit() ]
    #check = ''.join(chr(int(word)) for word in response)
    param2 = '%s' %  _encode_for_device(param)
    
    LOGGER.debug("Param: "+param2)
    LOGGER.debug("Check: "+x.decode()[:-1])
    if x.decode().strip() != param2.strip():
        LOGGER.error(("ERROR\n%s\n%s" % (_encode_for_device(param),
                                 _encode_for_device(x))))
        ser.write(b'q')
        sys.exit(1)
    LOGGER.debug('Check done!')

def _send_key(ser, key):
    _send_parameter(ser, 'k', key)

def _send_plaintext(ser, plaintext):
    _send_parameter(ser, 'p', plaintext)

def _send_init(ser, init):
    _send_parameter(ser, 'i', init)

# NOTE: Quick and dirty copy and modification of collect().
@cli.command()
@click.argument("file", type=click.File())
@click.argument("target-path", type=click.Path(exists=True, file_okay=False))
@click.option("--average-out", type=click.Path(dir_okay=False),
              help="File to write the average to (i.e. the template candidate).")
@click.option("--plot/--no-plot", default=False, show_default=True,
              help="Plot the results of trace collection.")
@click.option("--plot-out", type=click.Path(dir_okay=False),
              help="File to write the plot to (instead of showing it dynamically).")
@click.option("--saveplot/--no-saveplot", default=True, show_default=True,
              help="Save the plot of the results of trace collection.")
def extract(file, target_path, average_out, plot, plot_out, saveplot):
    """Analyze previous collect."""
    scaff.analyze.extract(np.load(file), CONFIG, average_out, plot, target_path, saveplot, index=0)

@cli.command()
@click.argument("target-path", type=click.Path(exists=True, file_okay=False))
@click.option("--average-out", type=click.Path(dir_okay=False),
              help="File to write the average to (i.e. the template candidate).")
@click.option("--plot/--no-plot", default=False, show_default=True,
              help="Plot the results of trace collection.")
@click.option("--plot-out", type=click.Path(dir_okay=False),
              help="File to write the plot to (instead of showing it dynamically).")
@click.option("--max-power/--no-max-power", default=False, show_default=True,
              help="Set the output power of the device to its maximum.")
@click.option("--raw/--no-raw", default=False, show_default=True,
              help="Save the raw IQ data.")
@click.option("--saveplot/--no-saveplot", default=True, show_default=True,
              help="Save the plot of the results of trace collection.")
@click.option("-p", "--set-power", default=0, show_default=True,
              help="If set, sets the device to a specific power level (overrides --max-power)")
@click.option("--num-points", "num_points_args", default=-1, show_default=True,
              help="If set, override the num_points TOML configuration variable.")
@click.option("--fixed-key/--no-fixed-key", "fixed_key_args", default=None, type=bool, show_default=True,
              help="If set, override the fixed_key TOML configuration variable.")
def collect(target_path, average_out, plot, plot_out, max_power, raw, saveplot, set_power, num_points_args, fixed_key_args):
    """Collect traces for an attack.

    The config is a TOML file containing parameters for trace analysis.

    """
    if CONFIG["fw"]["mode"] == "tinyaes":
        firmware_mode = TINY_AES_MODE
    elif CONFIG["fw"]["mode"] == "tinyaes_slow":
        firmware_mode = TINY_AES_MODE_SLOW
    else:
        raise Exception("Unsupported mode %s; this is a bug!" % CONFIG["fw"]["mode"])

    # Signal post-processing will drop some traces when their quality is
    # insufficient, so let's collect more traces than requested to make sure
    # that we have enough in the end.
    num_traces_per_point = int(CONFIG["fw"]["num_traces_per_point"])

    # number of points
    if num_points_args != -1:
        num_points = num_points_args
    else:
        num_points = int(CONFIG["fw"]["num_points"])

    # fixed_key
    if fixed_key_args is not None:
        fixed_key = fixed_key_args
    else:
        fixed_key = CONFIG["fw"]["fixed_key"]

    # fixed vs fixed
    fixed_vs_fixed = CONFIG["fw"]["fixed_vs_fixed"]

    # Generate the plaintexts
    if fixed_vs_fixed:
        plaintexts = ['\x00'*16 for _trace in range(num_points)]
    else:
        plaintexts = [os.urandom(16)
                    for _trace in range(1 if CONFIG["fw"]["fixed_plaintext"] else num_points)]
    
    with open(path.join(target_path, 'pt.txt'), 'w') as f:
        f.write('\n'.join(p.hex() for p in plaintexts))

    # Generate the key(s)
    if firmware_mode.have_keys:
        if fixed_vs_fixed:
            keys = ['\x00'*16 if i%2==0 else '\x30'*16 for i in range(num_points)]
        else:
            keys = [os.urandom(16)
                    for _key in range(1 if fixed_key else num_points)]
        with open(path.join(target_path, 'key.txt'), 'w') as f:
            f.write('\n'.join(k.hex() for k in keys))

    # If requested, reset target
    if YKUSH_PORT != 0:
        LOGGER.debug('Resetting device using ykush port %d' % YKUSH_PORT)
        system("sudo ykushcmd -d %d" % YKUSH_PORT)
        time.sleep(1)
        system("sudo ykushcmd -u %d" % YKUSH_PORT)
        time.sleep(3)

    with _open_serial_port() as ser:
        # TODO: Is this useful?
        # if YKUSH_PORT != 0:
        #     LOGGER.info((ser.readline()))

        if set_power != 0:
            LOGGER.info('Setting power level to '+str(set_power))
            ser.write(('p'+str(set_power)).encode('UTF-8'))
            ser.readline()
            ser.readline()
        elif max_power:
            LOGGER.info('Setting power to the  maximum')
            ser.write(b'p0')
            ser.readline()
            ser.readline()

        if CONFIG["fw"]["conventional"]:
            LOGGER.debug('Starting conventional mode, the radio is off')
        else:
            LOGGER.info('Selecting channel')
            ser.write(b'a')
            LOGGER.debug((ser.readline()))
            ser.write(b'%02d\n' % CONFIG["fw"]["channel"])
            LOGGER.debug((ser.readline()))
            if CONFIG["fw"]["modulate"]:
                LOGGER.info('Starting modulated wave')
                ser.write(b'o')     # start modulated wave
                LOGGER.debug((ser.readline()))
            else:
                LOGGER.info('Starting continuous wave')
                ser.write(b'c')     # start continuous wave

        LOGGER.info('Entering test mode')
        ser.write(firmware_mode.mode_command.encode()) # enter test mode
        LOGGER.debug((ser.readline()))

        # Quit just entered mode on CTRL+C.
        signal.signal(signal.SIGINT, partial(_close_serial_port, ser))
        signal.signal(signal.SIGTERM, partial(_close_serial_port, ser))

        if firmware_mode.repetition_command:
            LOGGER.info('Setting trace repetitions')
            ser.write(('n%d\r\n' % num_traces_per_point).encode())
            LOGGER.debug((ser.readline()))

        if firmware_mode.have_keys and fixed_key:
            # The key never changes, so we can just set it once and for all.
            _send_key(ser, keys[0])

        if CONFIG["fw"]["fixed_plaintext"]:
            # The plaintext never changes, so we can just set it once and for all.
            _send_plaintext(ser, plaintexts[0])

        # Initialize the radio client.
        client = soapyrx.core.SoapyClient()
        # Ensure radio do not contains old recordings.
        client.reinit()
            
        index = 0
        with (logging_redirect_tqdm(loggers=[LOGGER, soapyrx.logger.LOGGER, scaff.log.LOGGER]),
              tqdm(initial=0, total=num_points, desc="Collecting") as bar,):
            while index < num_points:
                if firmware_mode.have_keys and not fixed_key:
                    _send_key(ser, keys[index])

                if not CONFIG["fw"]["fixed_plaintext"]:
                    _send_plaintext(ser, plaintexts[index])

                LOGGER.info("Start instrumentation #{}".format(index))

                # Start non-blocking recording for a pre-configured duration.
                try:
                    client.record_start()
                except Exception as e:
                    LOGGER.error("Cannot start recording from the server: {}".format(e))
                    if CONTINUE is True:
                        LOGGER.info("Restart current recording!")
                        continue
                    else:
                        raise e

                # May need to add sleep if radio is not fast enough.
                # time.sleep(0.08)

                if firmware_mode.repetition_command:
                    # The test mode supports repeated actions.
                    LOGGER.info('Start repetitions...')
                    ser.write(firmware_mode.action_command.encode())
                    ser.readline() # wait until done
                else:
                    for _iteration in range(num_traces_per_point):
                        time.sleep(CONFIG["fw"]["slow_mode_sleep_time"])
                        ser.write(firmware_mode.action_command.encode()) # single action

                # time.sleep(0.09)
                try:
                    # Wait the end of the recording.
                    client.record_stop()
                    # Accept recording.
                    client.accept()
                except Exception as e:
                    LOGGER.error("Cannot stop recording from the server: {}".format(e))
                    if CONTINUE is True:
                        LOGGER.info("Restart current recording!")
                        continue
                    else:
                        raise e

                try:
                    trace_amp, trace_phr, trace_i, trace_q, trace_i_augmented, trace_q_augmented = scaff.analyze.extract(client.get(), CONFIG, average_out, plot, target_path, saveplot, index, return_zero=False)
                except Exception as e:
                    LOGGER.error("Cannot extract traces: {}".format(e))
                    if CONTINUE is True:
                        LOGGER.info("Restart current recording!")
                        client.reinit()
                        continue
                    else:
                        raise e

                np.save(os.path.join(target_path,"amp_%d.npy"%(index)),trace_amp)
                np.save(os.path.join(target_path,"phr_%d.npy"%(index)),trace_phr)
                np.save(os.path.join(target_path,"i_%d.npy"%(index)),trace_i)
                np.save(os.path.join(target_path,"q_%d.npy"%(index)),trace_q)
                if index < 30:
                    plt.plot(trace_amp); figure = plt.gcf(); figure.set_size_inches(32, 18)
                    plt.savefig(os.path.join(target_path,"amp_%d.png"%(index))); plt.clf()
                # np.save(os.path.join(target_path,"i_augmented_%d.npy"%(index)),trace_i_augmented)
                # np.save(os.path.join(target_path,"q_augmented_%d.npy"%(index)),trace_q_augmented)
                # if raw:
                #     save_raw(OUTFILE, target_path, index)

                # Update index and tqdm progress bar.
                index += 1
                bar.update(1)
                client.reinit()

        # Quit the server.
        client.stop()
        # Reset board state before closing serial port.
        _close_serial_port(ser)

if __name__ == "__main__":
    cli()
