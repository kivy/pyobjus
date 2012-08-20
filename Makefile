.PHONY: build_ext test

build_ext:
	python setup.py build_ext --inplace -f

tests: build_ext
	cd tests && env PYTHONPATH=..:$(PYTHONPATH) nosetests -v
