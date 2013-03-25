.PHONY: build_ext test

build_ext:
	env CFLAGS="-O0" python setup.py build_ext --inplace -f -g

tests: build_ext
	cd tests && env PYTHONPATH=..:$(PYTHONPATH) nosetests -v
