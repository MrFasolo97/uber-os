SRC = alias chown drive exit label lua modprobe ps shutdown cd clear edit id log mv reboot chmod cp eject kill ls mkdir rm mount umount ln readlink
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
