SRC = romfs ufs devfs ccfs
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
	mkdir -p ../../out/lib/drivers/fs
	cp out/* ../../out/lib/drivers/fs
