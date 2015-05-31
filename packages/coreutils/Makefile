SRC = alias chown drive exit label lua modprobe ps cd clear edit id log mv chmod cp eject kill ls mkdir rm mount umount ln readlink passwd useradd usermod userdel su sync groupadd groupdel
SRC_SBIN = shutdown reboot halt
PWD = $(shell pwd)
all	:	prepare $(SRC) $(SRC_SBIN)
clean:
	rm -rf out
prepare:
	mkdir -p out/{bin,sbin}
$(SRC):
	cd ../../min && lua CommandLineMinify.lua $(PWD)/$@.lua
	mv $@_min.lua out/bin/$@
$(SRC_SBIN):
	cd ../../min && lua CommandLineMinify.lua $(PWD)/$@.lua
	mv $@_min.lua out/sbin/$@
install:
	cp out/bin/* ../../out/bin
	cp out/sbin/* ../../out/sbin
