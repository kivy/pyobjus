DEBUG = os.environ.get('PYOBJUS_DEBUG', '') == '1'

debug_types = {
    "d": "DEBUG",
    "w": "WARNING",
    "e": "ERROR",
    "i": "INFO"
}

def dprint(*args, **kwargs):
    if DEBUG == False:
        return

    of_type = kwargs.get('of_type', 'd')

    print("[{}] {}".format(
        debug_types[of_type],
        " ".join([repr(arg) for arg in args])))
