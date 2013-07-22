.PHONY: build_ext test

build_ext:
	env CFLAGS="-O0" python setup.py build_ext --inplace -f -g

usr_lib:
	rm -rf objc_usr_classes/usrlib.dylib
	clang objc_usr_classes/usrlib.m -o objc_usr_classes/usrlib.dylib -dynamiclib -framework Foundation

tests: build_ext
	cd tests && env PYTHONPATH=..:$(PYTHONPATH) nosetests -v

html:
	$(MAKE) -C docs html

