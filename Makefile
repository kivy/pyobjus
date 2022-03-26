.PHONY: build_ext test all

build_ext:
	env CFLAGS="-O0" python setup.py build_ext --inplace -g

test_lib:
	rm -rf objc_classes/test/testlib.dylib objc_classes/test/CArrayTestlib.dylib
	clang objc_classes/test/testlib.m -o objc_classes/test/testlib.dylib -dynamiclib -framework Foundation -arch arm64 -arch x86_64
	clang objc_classes/test/CArrayTestlib.m -o objc_classes/test/CArrayTestlib.dylib -dynamiclib -framework Foundation -arch arm64 -arch x86_64

tests: build_ext
	cd tests && env PYTHONPATH=..:$(PYTHONPATH) python -m pytest -v

html:
	$(MAKE) -C docs html

distclean:
	rm -rf .pytest_cache
	rm -rf build
	rm -rf pyobjus/config.pxi
	rm -rf pyobjus/pyobjus.c
	rm -rf pyobjus/*.so
	rm -rf pyobjus/*.pyc
	rm -rf pyobjus/__pycache__

all: build_ext
