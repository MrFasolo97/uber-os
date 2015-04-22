PWD = $(shell pwd)
SRC = tmpfs
all: clean prepare $(SRC)
clean:
	rm -rf out
prepare:
	mkdir out
$(SRC):
	cd ../../../../../min && lua CommandLineMinify.lua $(PWD)/$@.lua
	mv $@_min.lua out/$@
install:
	cp out/* ../out/

