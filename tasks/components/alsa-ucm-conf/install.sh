#!/bin/bash -e

# Create tsimx9.conf ucm configuration file.  This contains the default
# amixer settings to get audio working on the TI TAC5111 codec.

install -d "$DS_OVERLAY/usr/share/alsa/ucm2/conf.d/simple-card"
install -m 644 "$DS_TASK_PATH"/files/simple-card/* "$DS_OVERLAY/usr/share/alsa/ucm2/conf.d/simple-card/"

# For future codecs add more conf files, the name of the conf file should
# match the simple-audio-card,name in the device tree.
