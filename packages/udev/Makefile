SRC = udev udevd
PWD = $(shell pwd)
all	:	prepare $(SRC)
clean:
	rm -rf out
prepare:
	mkdir -p out
$(SRC) :
	cd ../../min && lua CommandLineMinify.lua $(PWD)/$@.lua
	mv $@_min.lua out/$@
install:
	cp out/udev ../../out/sbin
	cp out/udevd ../../out/etc/init.d
