#!/bin/bash -e

export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true
export LC_ALL=C LANGUAGE=C LANG=C
(
    # This configure is expected to have a few commands that fail configuring. These
    # will be fixed by apt-get install -f
    set +e
    dpkg --configure -a
    true
)

if [ "$DS_DISTRO" == "ubuntu" ] && [ "$DS_RELEASE" == "lunar" ]; then
    # Workaround for:
    # Setting up sgml-base (1.31) ...
    # cannot open catalog directory /etc/sgml: No such file or directory at /usr/sbin/update-catalog line 299.
    mkdir /etc/sgml/
fi

if [ "$DS_DISTRO" == "ubuntu" ] && [ "$DS_RELEASE" == "noble" ]; then
    # Workaround for:
    #Errors were encountered while processing:
    # bash
    #Reading package lists... Done
    #Building dependency tree... Done
    #Correcting dependencies... failed.
    #The following packages have unmet dependencies:
    # bash : Depends: base-files (>= 2.1.12) but it is not installable
    #        Recommends: bash-completion but it is not installable
    #E: Error, pkgProblemResolver::Resolve generated breaks, this may be caused by held packages.
    #E: Unable to correct dependencies
    set +e
    apt-get install -f
    # Set up a temporary resolv.conf, we need this early here
    if [ -L "/etc/resolv.conf" ]; then
        install -d $(dirname $(readlink /etc/resolv.conf))
        echo "nameserver 1.1.1.1" > /etc/resolv.conf
    fi

    set -e
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y -o Dpkg::Options::="--force-confold" base-files bash-completion
fi

apt-get install -f
apt-get clean
chmod 755 /

# Set up a temporary resolv.conf.
if [ -L "/etc/resolv.conf" ]; then
    install -d $(dirname $(readlink /etc/resolv.conf))
    echo "nameserver 1.1.1.1" > /etc/resolv.conf
fi
