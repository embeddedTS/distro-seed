#!/bin/bash -e

if [ -n "${CONFIG_DS_TIMEZONE:-}" ]; then
        if [ -e /etc/localtime ]; then
                rm /etc/localtime
        fi
        ln -s "/usr/share/zoneinfo/${CONFIG_DS_TIMEZONE}" /etc/localtime
fi
