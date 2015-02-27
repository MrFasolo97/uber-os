SRC = lua fsd users acpi
PWD = $(shell pwd)
all	:	clean prepare $(SRC)
clean: $(addsuffix .clean, $(SRC))
	rm -rf out

$(addsuffix .clean, $(SRC)):
	$(MAKE) -C $(basename $@) clean

prepare:
	mkdir -p out
.PHONY: $(SRC) $(addsuffix .install, $(SRC))
$(SRC):
	$(MAKE) -C $@ 
	$(MAKE) -C $(basename $@) install

install: prepare-install $(addsuffix .install, $(SRC))

$(addsuffix .install, $(SRC)):
	cp out/* ../out/modules 

prepare-install:
	mkdir -p ../out/modules
