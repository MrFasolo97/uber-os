SRC = udm udmd
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
	cp out/udm ../../out/usr/bin
	cp out/udmd ../../out/etc/init.d
