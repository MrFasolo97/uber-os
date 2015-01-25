BASE_PACKAGES = corelib coreutils fsdrv init login uberkernel uboot udev ush
PACKAGES = $(BASE_PACKAGES) libjson luamin 

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
	mkdir -p out/{bin,boot,dev,etc/init.d,home,lib/{modules,drivers},root,sbin,sys/rom,tmp,var/{lib,lock,log}}

$(PACKAGES):
	$(MAKE) -C packages/$@ clean
	$(MAKE) -C packages/$@
	$(MAKE) -C packages/$@ install
	$(MAKE) -C packages/$@ clean

configure: configure-prepare configure-passwd configure-fstab configure-rc
configure-prepare:
	touch out/etc/{motd,issue}
	mkdir out/etc/rc.d
configure-passwd:
	printf "root::0:::/root:/bin/ush\n" > out/etc/passwd
configure-fstab:
	printf "/ / ufs defaults 0 0\n/dev/ram /dev devfs defaults 0 0\n/rom /sys/rom romfs defaults 0 0\n" > out/etc/fstab
configure-rc: configure-rc0 configure-rc1 configure-rc2 configure-rc3 configure-rc4 configure-rc5 configure-rc6 
configure-rc0:
	printf "S99kerneld\n" > out/etc/rc.d/rc0
configure-rc1:
	printf "R10udevd\nR99logind\n" > out/etc/rc.d/rc1
configure-rc2:
	printf "R10udevd\nR99logind\n" > out/etc/rc.d/rc2
configure-rc3:
	printf "R10udevd\nR99logind\n" > out/etc/rc.d/rc3
configure-rc4:
	printf "R10udevd\nR99logind\n" > out/etc/rc.d/rc4
configure-rc5:
	printf "R10udevd\nR99logind\n" > out/etc/rc.d/rc5
configure-rc6:
	printf "K99kerneld\n" > out/etc/rc.d/rc6

