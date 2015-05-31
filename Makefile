SHELL = /bin/bash

BASE_PACKAGES = coreutils init login uberkernel uboot udev ush upt luamin
PACKAGES = $(BASE_PACKAGES) libjson utar devutils Bedrock libbase64 libargparse libarchive

all: clean prepare base configure

clean:
	rm -rf out

prepare:
	mkdir -p out

packages: prepare
groups: prepare

base: populatefs $(BASE_PACKAGES)
complete: populatefs $(PACKAGES)

populatefs:
	mkdir -p out/{bin,boot,dev,etc/init.d,home,lib,root,sbin,sys/rom,tmp,var/{lib,lock,log,cache},usr/{bin,lib,local,share,pkg,src,include},mnt}

$(PACKAGES):
	$(MAKE) -C packages/$@ clean
	$(MAKE) -C packages/$@
	$(MAKE) -C packages/$@ install
	$(MAKE) -C packages/$@ clean

source:
	cp -r packages/* out/usr/src/
	rm -rf out/usr/src/Build.lua
	rm -rf out/usr/src/CONFIG

configure: configure-prepare configure-passwd configure-group configure-fstab configure-inittab
configure-prepare:
	touch out/etc/{motd,issue}
	mkdir out/etc/rc.d
configure-passwd:
	printf "root::0:0::/root:/bin/ush\n" > out/etc/passwd
configure-group:
	printf "root:x:0:root\nnetwork:x:1:\nusers:x:100:\n" > out/etc/group
configure-fstab:
	printf "__ROOT_DEV__ / ufs defaults 0 0\n/dev/ram /dev devfs defaults 0 0\n/rom /sys/rom romfs defaults 0 0\ntmpfs /tmp tmpfs" > out/etc/fstab
configure-inittab:
	printf "1:1:once:/bin/ush\n" > out/etc/inittab
	printf "2:234:once:/etc/init.d/logind start\n" >> out/etc/inittab
	printf "3:234:once:/etc/init.d/udevd start\n" >> out/etc/inittab
