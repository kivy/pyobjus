.. _installation:

Installation
============

Pyobjus depends on `Cython <http://cython.org/>`_.


Installation on the Desktop
---------------------------

You need to install Cython first. Then, just type::

    sudo python setup.py install

If you want to compile the extension within the directory for any development,
just type::

    make

You can run the tests suite to make sure everything is running correctly::

    make tests

Or you can build the documentation yourself::

    make html
    open docs/build/html/index.html 

Installation on iOS
-------------------

Please see the :ref:`pyobjus_ios` section.