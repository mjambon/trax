.PHONY: all
all:
	dune build @install

.PHONY: test
test:
	dune build src/test/Test.exe
	./_build/default/src/test/Test.exe

.PHONY: install
install:
	dune install

.PHONY: clean
clean:
	dune clean
