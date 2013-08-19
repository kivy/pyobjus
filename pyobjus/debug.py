DEBUG = True

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

    print "[{0}]".format(debug_types[of_type]),
    for argument in args:
        print "{0}".format(argument),
    print ''
