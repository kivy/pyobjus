"""
Build an informationnal protocol list, based on the objective-c headers.
"""

import argparse
import json
import os


class FrameworkDiscover:
    """
    Looks for frameworks (framework, xcframework) in a directory.
    """

    def __init__(self):
        self._frameworks = {}

    def _search_frameworks(self, directory):
        if not os.path.exists(directory):
            return

        for fn in os.listdir(directory):
            if fn.endswith(".framework") or fn.endswith(".xcframework"):
                self._frameworks[fn] = os.path.join(directory, fn)

    def search(self, directory):
        """
        Search for frameworks in a directory.

        :param directory: The directory to search in.

        :return: A dictionary with the frameworks found.
        """
        self._frameworks = {}
        self._search_frameworks(directory)
        return self._frameworks


class FrameworkProtocolsScanner:
    """
    This class is used to scan a framework for protocols.
    """

    def __init__(self, framework_path: str):
        """
        :param framework_path: The framework path
        (e.g. /System/Library/Frameworks/AddressBook.framework)
        """
        self._framework_path = framework_path
        self._results = {}

    def _search_frameworks(self, directory):
        for _framework_path in FrameworkDiscover().search(directory).values():
            self._scan_framework(_framework_path)

    def _scan_framework(self, framework_path):
        print("Scanning framework", framework_path)

        if framework_path.endswith(".framework"):
            self._scan_headers(framework_path, framework_path)
            _subframeworks_path = os.path.join(framework_path, "Frameworks")
            self._search_frameworks(_subframeworks_path)
        elif framework_path.endswith(".xcframework"):
            for _arch_dir in os.listdir(framework_path):
                _arch_path = os.path.join(framework_path, _arch_dir)
                if os.path.isdir(_arch_path):
                    self._search_frameworks(_arch_path)

    def _scan_headers(self, framework, pathfn):
        headers = os.path.join(pathfn, "Headers")
        if not os.path.exists(headers):
            return
        for fn in os.listdir(headers):
            fullfn = os.path.join(headers, fn)
            if os.path.isdir(fn):
                self._scan_headers(framework, fullfn)
            elif fn.endswith(".h"):
                self._scan_header(framework, fullfn)

    def _scan_header(self, framework, header_fn):
        framework_name = os.path.basename(framework).rsplit(".", 1)[0]
        with open(header_fn) as fd:
            lines = fd.readlines()

        protocol = None
        for line in lines:
            line = line.strip()

            if protocol is None:
                if line.startswith("@protocol") and not line.endswith(";"):
                    # extract protocol name
                    print(framework_name, line)
                    try:
                        protocol_name = line.split()[1]
                    except IndexError:
                        # not the droids we're looking for
                        pass
                    else:
                        protocol = (protocol_name, [])
            else:
                if line.startswith("@end"):
                    # done, insert the protocol!
                    self._insert_protocol(framework_name, protocol)
                    protocol = None
                elif line.startswith("-") and ":" in line:
                    try:
                        delegate = self._parse_delegate(line)
                    except Exception:
                        pass
                    else:
                        protocol[1].append(delegate)

    def _insert_protocol(self, framework_name, protocol):
        if framework_name not in self._results:
            self._results[framework_name] = {}
        protocol_name, delegates = protocol
        self._results[framework_name][protocol_name] = delegates

    @staticmethod
    def _tokenize_delegate(line):
        token = ""
        while line:
            # print 'tokenize', line
            if line[0] == "(":
                if token:
                    yield token
                token = ""
                end = line.index(")")
                yield line[: end + 1]
                line = line[end + 1 :]
                continue

            if line[0] == " " or line[0] == ";":
                if token:
                    yield token
                token = ""
                line = line[1:]
                continue

            token = token + line[0]
            line = line[1:]

        if token:
            yield token

    @staticmethod
    def _convert_type_to_signature(token):
        METHOD_ENCODINGS = dict(
            [
                ("const", "r"),
                ("in", "n"),
                ("inout", "N"),
                ("out", "o"),
                ("bycopy", "O"),
                ("byref", "R"),
                ("oneway", "V"),
            ]
        )

        sig = ""
        size = (4, 8)
        tokens = token.split(" ")
        # print 'convert_type_to_signature()', tokens
        while True:
            t = tokens[0]
            if t not in METHOD_ENCODINGS:
                break
            sig += METHOD_ENCODINGS[t]
            tokens = tokens[1:]

        token = " ".join(tokens)

        if token in ("BOOL",):
            sig += "B"
        elif token in ("char",):
            sig += "c"
        elif token in ("int", "NSInteger"):
            sig += "i"
        elif token in ("long",):
            sig += "l"
        elif token in ("long long",):
            sig += "q"
        elif token in ("unsigned char",):
            sig += "C"
        elif token in ("unsigned int", "NSUInteger"):
            sig += "I"
        elif token in ("unsigned short",):
            sig += "S"
        elif token in ("unsigned long",):
            sig += "L"
        elif token in ("unsigned long long",):
            sig += "Q"
        elif token in ("float", "CGFloat"):
            sig += "f"
        elif token in ("double", "CGDouble"):
            sig += "d"
        elif token in ("char *",):
            sig += "*"
        elif token == "void":
            sig += "v"
        elif token == "id":
            sig += "@"
        else:
            print("Unknown type: {!r}".format(token))
            # assert(0)
            sig += "@"

        return (sig, size)

    @staticmethod
    def _build_signature(items, index):
        sig = ""
        offset = 0
        for tp, sizes in items[1:]:
            sig += "{}{}".format(tp, offset)
            offset += sizes[index]

        sig = "{}{}".format(items[0][0], offset) + sig
        return sig

    def _parse_delegate(self, line):
        if line.startswith("- "):
            line = line[2:]
        elif line.startswith("-"):
            line = line[1:]

        print("----", line)
        fn = ""
        sig = []
        for index, token in enumerate(self._tokenize_delegate(line)):
            print("--->", token)
            if ":" in token:
                if index == 1:
                    sig.extend([("@", (4, 8)), (":", (4, 8))])
                if token != ":":
                    fn += token
            elif token[0] == "(":
                sig.append(self._convert_type_to_signature(token[1:-1]))
            elif token.upper() == token:
                # end?
                break
        sig32 = self._build_signature(sig, 0)
        sig64 = self._build_signature(sig, 1)
        print("---- selector", fn, sig32, sig64)

        # if 'plugInDidAcceptOutgoingFileTransferSession' in fn:
        #    import sys; sys.exit(0)

        return (fn, sig32, sig64)

    def scan(self) -> dict:
        """
        Scan the framework for protocols.

        :return: A dictionary with the protocols found.
        """

        self._results = {}

        self._scan_framework(self._framework_path)

        return self._results


def main():
    parser = argparse.ArgumentParser(
        description="Scan a framework for protocols."
    )
    parser.add_argument(
        "-f",
        "--framework",
        metavar="FRAMEWORK",
        type=str,
        nargs="+",
        default=[],
        help="framework(s) to analyze",
    )
    parser.add_argument(
        "-d",
        "--directory",
        metavar="DIRECTORY",
        type=str,
        nargs="+",
        default=[],
        help="directory(ies) to analyze for frameworks",
    )
    parser.add_argument(
        "-o",
        "--output",
        metavar="OUTPUT",
        type=str,
        default="pyobjus_extra_protocols.json",
        help="output file name (default: pyobjus_extra_protocols.json)",
    )
    args = parser.parse_args()

    results = {}

    _frameworks = []
    _frameworks.extend(args.framework)

    for _directory in args.directory:
        _frameworks.extend(FrameworkDiscover().search(_directory))

    for _framework in _frameworks:
        scanner = FrameworkProtocolsScanner(_framework)
        _framework_results = scanner.scan()

        for framework_protocols in _framework_results.values():
            for protocol, methods in framework_protocols.items():
                if protocol not in results:
                    results[protocol] = {}
                for (
                    method_name,
                    method_sig_32,
                    method_sig_64,
                ) in methods:
                    results[protocol][method_name] = {
                        "signatures": {
                            "32": method_sig_32,
                            "64": method_sig_64,
                        }
                    }

    json.dump(results, open(args.output, "w"))


if __name__ == "__main__":
    main()
