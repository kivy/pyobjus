DEBUG = False

debug_types = {
    "d": "DEBUG",
    "w": "WARNING",
    "e": "ERROR"
    }

def dprint(*args, **kwargs):
    if DEBUG == False:
        return
    type = "d"
    if "type" in kwargs:
        type = kwargs["type"]

    print "[{0}]".format(debug_types[type]),
    for argument in args:
        print "{0}".format(argument),
    print ''



if __name__ == "__main__":
    dprint("pa di si", "v", type="e")
    dprint("bu")

