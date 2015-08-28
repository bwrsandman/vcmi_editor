CC=gcc
CFLAGS=
CDEPS = c_editor_utils.h
COBJ = $(CDEPS:.h=.o)

%.o: %.c $(CDEPS)
	$(CC) -c -o $@ $< $(CFLAGS)

all: vcmieditor

vcmieditor: $(COBJ)
	lazbuild 3rd_party/csvdocument/csvdocument_package.lpk vcmieditor.lpr

build_tests: vcmieditor tests/tests.lpi tests/tests.lpr
	lazbuild tests/tests.lpr
	$(CC) -lcheck tests/tests.c $(COBJ) -o tests/c_tests

test: build_tests
	./tests/tests --all --progress --format=plain
	./tests/c_tests

clean_tests:
	rm -rf tests/tests tests/c_tests tests/*.o tests/*.ppu tests/*.compiled

clean: clean_tests
	rm -rf vcmieditor *.o *.ppu *.compiled 3rd_party/csvdocument/lib/
