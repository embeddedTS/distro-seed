all:
	@common/build.py

dry-run:
	@common/build.py --dry-run

%_defconfig:
	@common/lib/kconfiglib/defconfig.py --kconfig Kconfig $(shell pwd)/configs/$@

menuconfig:
	@common/lib/kconfiglib/menuconfig.py

savedefconfig:
	@common/lib/kconfiglib/savedefconfig.py

vm-shell:
	@common/utils/vm-shell.py

cross-shell:
	@common/utils/cross-shell.py

target-shell:
	@common/utils/target-shell.py

checkdeps:
	@common/utils/check.py

plotdeps:
	@common/build.py --plot-deps

clean:
	-@common/utils/clean-work.py

clean-cache:
	@common/utils/clean-cache.py

clean-all:
	-@rm -rf dl/
	-@common/utils/clean-cache.py
	-@common/utils/clean-work.py
