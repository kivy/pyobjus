.PHONY: build_ext test

build_ext:
	env CFLAGS="-O0" python setup.py build_ext --inplace -g

test_lib:
	rm -rf objc_classes/test/usrlib.dylib
	clang objc_classes/test/testlib.m -o objc_classes/test/testlib.dylib -dynamiclib -framework Foundation

tests: build_ext
	cd tests && env PYTHONPATH=..:$(PYTHONPATH) nosetests -v

html:
	$(MAKE) -C docs html

