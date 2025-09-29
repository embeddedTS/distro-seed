#!/bin/bash
set -e

## Workaround for:
# Couldn't create temporary file /tmp/apt.conf.Mm1aVa for passing config to apt-key
chmod 1777 /tmp

apt-get update
