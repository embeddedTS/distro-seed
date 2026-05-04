#!/usr/bin/env python3

import os
import sys

sys.path.append(os.path.join(os.environ["DS_HOST_ROOT_PATH"], "common"))

from lib import vm

vm.start_vm()
