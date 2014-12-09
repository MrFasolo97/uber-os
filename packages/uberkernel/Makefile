SRC = kerneld uberkernel thread
PWD = $(shell pwd)
SRC_MODULES = fsd lua users
all	:	prepare $(SRC) $(SRC_MODULES)
clean:
	rm -rf out
prepare:
	mkdir -p out/modules
$(SRC) :
	cd ../../min && lua CommandLineMinify.lua $(PWD)/$@.lua
	mv $@_min.lua out/$@
$(SRC_MODULES) :
	cd ../../min && lua CommandLineMinify.lua $(PWD)/modules/$@.lua
	mv modules/$@_min.lua out/modules/$@
install:
	cp out/modules/* ../../out/lib/modules
	cp out/kerneld ../../out/etc/init.d
	cp out/uberkernel ../../out/boot/uberkernel
	cp out/thread ../../out/sbin
