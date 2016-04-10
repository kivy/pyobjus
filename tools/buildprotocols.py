'''
Build an informationnal protocol list, based on the objective-c headers.

FIXME: early version, do not use unless you known what you're doing.
'''

from os import listdir, environ
from os.path import join, exists, isdir, basename

protocols = {}
DEBUG = environ.get('PYOBJUS_DEBUG', '0') == '1'

def dprint(*args):
    if not DEBUG:
        return
    print args


def search_frameworks(directory):
    for fn in listdir(directory):
        if not fn.endswith('.framework'):
            continue
        scan_framework(join(directory, fn))


def scan_framework(framework):
    scan_headers(framework, framework)
    frameworks = join(framework, 'Frameworks')
    if exists(frameworks):
        search_frameworks(frameworks)


def scan_headers(framework, pathfn):
    headers = join(pathfn, 'Headers')
    if not exists(headers):
        return
    for fn in listdir(headers):
        fullfn = join(headers, fn)
        if isdir(fn):
            scan_headers(framework, fullfn)
        elif fn.endswith('.h'):
            scan_header(framework, fullfn)


def scan_header(framework, header_fn):
    framework_name = basename(framework).rsplit('.', 1)[0]
    with open(header_fn) as fd:
        lines = fd.readlines()

    protocol = None
    for line in lines:
        line = line.strip()

        if protocol is None:
            if line.startswith('@protocol') and not line.endswith(';'):
                # extract protocol name
                dprint(framework_name, line)
                try:
                    protocol_name = line.split()[1]
                except IndexError:
                    # not the droids we're looking for
                    pass
                else:
                    protocol = (protocol_name, [])
        else:
            if line.startswith('@end'):
                # done, insert the protocol!
                insert_protocol(framework_name, protocol)
                protocol = None
            elif line.startswith('-') and ':' in line:
                try:
                    delegate = parse_delegate(line)
                except Exception:
                    pass
                else:
                    protocol[1].append(delegate)


def insert_protocol(framework_name, protocol):
    if framework_name not in protocols:
        protocols[framework_name] = {}
    protocol_name, delegates = protocol
    protocols[framework_name][protocol_name] = delegates
    #print 'find', protocol_name, delegates


def parse_delegate(line):

    if line.startswith('- '):
        line = line[2:]
    elif line.startswith('-'):
        line = line[1:]

    dprint('----', line)
    fn = ''
    sig = []
    for index, token in enumerate(tokenize_delegate(line)):
        dprint('--->', token)
        if ':' in token:
            if index == 1:
                sig.extend([
                    ('@', (4, 8)),
                    (':', (4, 8))])
            if token != ':':
                fn += token
        elif token[0] == '(':
            sig.append(convert_type_to_signature(token[1:-1]))
        elif token.upper() == token:
            # end?
            break
    sig32 = build_signature(sig, 0)
    sig64 = build_signature(sig, 1)
    dprint('---- selector', fn, sig32, sig64)

    #if 'plugInDidAcceptOutgoingFileTransferSession' in fn:
    #    import sys; sys.exit(0)

    return (fn, sig32, sig64)


def build_signature(items, index):
    sig = ''
    offset = 0
    for tp, sizes in items[1:]:
        sig += '{}{}'.format(tp, offset)
        offset += sizes[index]

    sig = '{}{}'.format(items[0][0], offset) + sig
    return sig



def tokenize_delegate(line):
    token = ''
    while line:
        #print 'tokenize', line
        if line[0] == '(':
            if token:
                yield token
            token = ''
            end = line.index(')')
            yield line[:end + 1]
            line = line[end + 1:]
            continue

        if line[0] == ' ' or line[0] == ';':
            if token:
                yield token
            token = ''
            line = line[1:]
            continue

        token = token + line[0]
        line = line[1:]

    if token:
        yield token


method_encodings = dict([
    ('const', 'r'), ('in', 'n'), ('inout', 'N'), ('out', 'o'), ('bycopy', 'O'),
    ('byref', 'R'), ('oneway', 'V')])

def convert_type_to_signature(token):
    sig = ''
    size = (4, 8)
    tokens = token.split(' ')
    #print 'convert_type_to_signature()', tokens
    while True:
        t = tokens[0]
        if t not in method_encodings:
            break
        sig += method_encodings[t]
        tokens = tokens[1:]

    token = ' '.join(tokens)

    if token in ('BOOL', ):
        sig += 'B'
    elif token in ('char', ):
        sig += 'c'
    elif token in ('int', 'NSInteger'):
        sig += 'i'
    elif token in ('long', ):
        sig += 'l'
    elif token in ('long long', ):
        sig += 'q'
    elif token in ('unsigned char', ):
        sig += 'C'
    elif token in ('unsigned int', 'NSUInteger'):
        sig += 'I'
    elif token in ('unsigned short', ):
        sig += 'S'
    elif token in ('unsigned long', ):
        sig += 'L'
    elif token in ('unsigned long long', ):
        sig += 'Q'
    elif token in ('float', 'CGFloat'):
        sig += 'f'
    elif token in ('double', 'CGDouble'):
        sig += 'd'
    elif token in ('char *', ):
        sig += '*'
    elif token == 'void':
        sig += 'v'
    elif token == 'id':
        sig += '@'
    else:
        dprint('Unknown type: {!r}'.format(token))
        #assert(0)
        sig += '@'

    return (sig, size)

if __name__ == '__main__':
    from os.path import dirname
    search_frameworks('/System/Library/Frameworks')
    fn = join(dirname(__file__), '..', 'pyobjus', 'protocols.py')
    with open(fn, 'w') as fd:
        fd.write('# autogenerated by buildprotocols.py\n')
        fd.write('protocols = {\n')
        for items in protocols.values():
            for protocol, delegates in items.items():
                fd.write('    "{}": {{\n'.format(protocol))
                for delegate, sig32, sig64 in delegates:
                    fd.write('        "{}": ("{}", "{}"),\n'.format(
                        delegate, sig32, sig64))
                fd.write('    },\n')
        fd.write('}')


