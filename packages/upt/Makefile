SRC = upt
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
	cp out/* ../../out/bin
	mkdir -p ../../out/var/lib/upt/db
	printf "repo https://raw.githubusercontent.com/TsarN/uber-os/master\n" > ../../out/var/lib/upt/db/general
