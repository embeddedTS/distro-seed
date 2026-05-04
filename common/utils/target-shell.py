#!/usr/bin/env python3

import os
import sys

current = os.path.dirname(os.path.realpath(__file__))
parent = os.path.dirname(current)
sys.path.append(parent)

from lib.kconfiglib import kconfiglib
from lib.vars import kconfig_export_vars
from lib import vm

kconf = kconfiglib.Kconfig("Kconfig")
kconf.load_config(".config")
kconfig_export_vars(kconf)

vm.ensure_vm_image()
vm.interactive_shell("target")
