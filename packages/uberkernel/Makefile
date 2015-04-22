PWD = $(shell pwd)
SRC_MODULES = fsd lua users acpi
SRC_DRIVERS_FS = ccfs devfs romfs ufs tmpfs
all	:	prepare modules drivers-fs main
clean: clean-drivers-fs clean-modules
	rm -rf out
prepare:
	mkdir -p out/modules
drivers-fs: prepare-drivers-fs $(SRC_DRIVERS_FS) install-drivers-fs
prepare-drivers-fs:
	$(MAKE) -C drivers/fs clean prepare
$(SRC_DRIVERS_FS):
	$(MAKE) -C drivers/fs $@
install-drivers-fs:
	$(MAKE) -C drivers/fs install
clean-drivers-fs:
	$(MAKE) -C drivers/fs clean

modules: prepare-modules $(SRC_MODULES) install-modules
prepare-modules:
	$(MAKE) -C modules clean prepare
$(SRC_MODULES):
	$(MAKE) -C modules $@
install-modules:
	$(MAKE) -C modules install
clean-modules:
	$(MAKE) -C modules clean

main:
	cd ../../min && lua CommandLineMinify.lua $(PWD)/uberkernel.lua
	mv uberkernel_min.lua out/uberkernel

$(addsuffix .genimg, $(SRC_MODULES)):
	printf "_G['loadmodule_" >> out/uberkernel_img
	printf $(basename $@) >> out/uberkernel_img
	printf "']=function()\n" >> out/uberkernel_img
	cat out/modules/$(basename $@) >> out/uberkernel_img
	printf "\nend\n" >> out/uberkernel_img

$(addsuffix .genimg, $(SRC_DRIVERS_FS)):
	printf "_G['loadfsdriver_" >> out/uberkernel_img
	printf $(basename $@) >> out/uberkernel_img
	printf "']=function(oldfs,drivers)\n" >> out/uberkernel_img
	cat out/drivers/fs/$(basename $@) >> out/uberkernel_img
	printf "\nend\n" >> out/uberkernel_img

genimg-prepare:
	touch out/uberkernel_img

genimg-finish:
	cat out/uberkernel >> out/uberkernel_img

genimg: genimg-prepare $(addsuffix .genimg, $(SRC_MODULES)) $(addsuffix .genimg, $(SRC_DRIVERS_FS)) genimg-finish

install: genimg
	cp out/uberkernel_img ../../out/boot/uberkernel

install-legacy:
	cp out/modules/* ../../out/lib/modules
	cp out/uberkernel ../../out/boot/uberkernel
