import json

from pyobjus._default_protocols import protocols as _protocols

__all__ = ["protocols"]


class ProtocolsDictionary:
    """
    This class is used to register protocols and their methods, and
    can be accessed as a dictionary.

    It's pre-populated with a set of default protocols (as historically
    pyobjus did), but you can add your own protocols methods, via
    the :meth:`add_protocol_method` method and batch add them via the
    :meth:`load_protocols_file` method.

    """

    _protocols = _protocols

    def __getitem__(self, key) -> dict:
        return self.get(key)

    def __setitem__(self, key, value) -> None:
        self._protocols[key] = value

    def get(self, key, default=None) -> dict:
        return ProtocolsDictionary._protocols.get(key, default)

    def add_protocol_method(
        self, protocol: str, method_selector: str, method_signatures: dict
    ) -> None:
        """
        Add a method to a protocol.
        If the protocol does not exist, it will be created.

        :param protocol: The protocol name.
        :param method_selector: The method selector.
        :param method_signature: The method signatures (a dict with 32 and 64).

        :return: None
        """

        if protocol not in ProtocolsDictionary._protocols:
            ProtocolsDictionary._protocols[protocol] = {}

        ProtocolsDictionary._protocols[protocol][method_selector] = (
            method_signatures["32"],
            method_signatures["64"],
        )

    def load_protocols_file(self, protocols_file: str) -> None:
        """
        Load protocols from a file.

        :param protocols_file: The protocols file path.

        The file can be generated via the `buildprotocols.py` tool
        (Located in the `tools` directory), and should be a JSON file
        with the following structure:

        .. code-block:: json

                ...
                {
                    "protocolName": {
                        "methodSelector": {
                            "signatures": {
                                "32": "methodSignature32",
                                "64": "methodSignature64"
                            }
                        }
                    }
                }
                ...

        :return: None
        """

        protocols_to_import = json.load(open(protocols_file, "r"))

        # Add the protocols to the dictionary
        for protocol_name, protocol_methods in protocols_to_import.items():
            for method_selector, method_data in protocol_methods.items():
                self.add_protocol_method(
                    protocol_name,
                    method_selector,
                    method_data["signatures"],
                )


protocols = ProtocolsDictionary()
