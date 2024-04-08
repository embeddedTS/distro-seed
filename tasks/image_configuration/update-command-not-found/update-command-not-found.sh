#!/bin/bash -e

if [ "$DS_DISTRO" == "ubuntu" ] && [ "$DS_RELEASE" == "lunar" ]; then
        apt-get update
else
        update-command-not-found
fi
