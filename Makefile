BASE_PACKAGES = corelib coreutils fsdrv init login uberkernel uboot udev ush

all: clean prepare base

clean:
	rm -rf out

prepare:
	mkdir -p out

base: populatefs $(BASE_PACKAGES)

populatefs:
	mkdir -p out/{bin,boot,dev,etc/init.d,home,lib/{modules,drivers},root,sbin,sys/rom,tmp,var/{lib,lock}}

$(BASE_PACKAGES):
	$(MAKE) -C packages/$@ clean
	$(MAKE) -C packages/$@
	$(MAKE) -C packages/$@ install
	$(MAKE) -C packages/$@ clean
