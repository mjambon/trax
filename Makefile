VERSION = 0.0.1
export VERSION

NATDYNLINK := $(shell if [ -f `ocamlfind ocamlc -where`/dynlink.cmxa ]; then \
                         echo YES; else echo NO; \
                      fi)

ifeq "${NATDYNLINK}" "YES"
CMXS=trax.cmxs
endif

.PHONY: default all opt clean
default: all opt
all: trax.cmo

trax.cmo: trax.ml
	ocamlfind ocamlc -c trax.mli
	ocamlfind ocamlc -c -dtypes trax.ml
	touch bytecode

opt: trax.cmx $(CMXS)

trax.cmx:
	ocamlfind ocamlc -c trax.mli
	ocamlfind ocamlopt -c -dtypes trax.ml
	touch nativecode

trax.cmxs: trax.cmx
	ocamlfind ocamlopt -I . -shared -linkall -o trax.cmxs trax.cmx

clean:
	rm -f *.cm[iox] *.cmxs *.o *.annot bytecode nativecode

COMMON_INSTALL_FILES = META trax.cmi trax.mli
BC_INSTALL_FILES = trax.cmo
NC_INSTALL_FILES = trax.cmx trax.o $(CMXS)

install:
	echo "version = \"$(VERSION)\"" > META; cat META.in >> META
	INSTALL_FILES="$(COMMON_INSTALL_FILES)"; \
		if test -f bytecode; then \
		  INSTALL_FILES="$$INSTALL_FILES $(BC_INSTALL_FILES)"; \
		fi; \
		if test -f nativecode; then \
		  INSTALL_FILES="$$INSTALL_FILES $(NC_INSTALL_FILES)"; \
		fi; \
		ocamlfind install trax $$INSTALL_FILES

uninstall:
	ocamlfind remove trax
