#!/bin/bash -e

# Some releases require running update-command-not-found, newer
# releases do this when you run apt-get update.

if command -v update-command-not-found &> /dev/null; then
    update-command-not-found
else
    apt-get update
fi
