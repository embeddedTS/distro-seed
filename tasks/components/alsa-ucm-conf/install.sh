#!/bin/bash -e

# Create tsimx9.conf ucm configuration file.  This contains the default
# amixer settings to get audio working on the TI TAC5111 codec.
cat << EOF > /usr/share/alsa/ucm2/conf.d/simple-card/tsimx9.conf
# Use case configuration for TI tac5111 codec

Syntax 4

BootSequence [
        # Playback
        cset "name='OUT1x Config' 'Mono Single-ended at OUTxM only'"
        cset "name='ASI_RX_CH1_EN Switch' on"
        # Record
        cset "name='ADC1 Config' 'Single-ended mux INxM'"
        cset "name='ASI_TX_CH1_EN Switch' on"
        cset "name='ADC1 Digital Capture Volume' 255"
]
EOF

# For future codecs add more conf files, the name of the conf file should
# match the simple-audio-card,name in the device tree.
