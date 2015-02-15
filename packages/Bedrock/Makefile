SRC = Bedrock libbedrock
PWD = $(shell pwd)
all	:	prepare $(SRC)
clean:
	rm -rf out
prepare:
	mkdir -p out
$(SRC) :
	cd ../../min && lua CommandLineMinify.lua $(PWD)/$@.lua
	mv $@_min.lua out/$@.lua
install:
	cp out/libbedrock.lua ../../out/lib/
	mkdir -p ../../out/usr/include/bedrock
	cp out/Bedrock.lua ../../out/usr/include/bedrock/Bedrock
