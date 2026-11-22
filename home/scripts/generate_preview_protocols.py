"""Generate bindings from the protocols in the locked Quickshell source."""
import inspect
import sys
from pathlib import Path

from pywayland.protocol import wayland
from pywayland.protocol_core import Interface
from pywayland.scanner import Protocol


def generate(output, files):
    output = Path(output)
    output.mkdir(parents=True, exist_ok=True)
    (output / "__init__.py").touch()
    (output / "wayland.py").write_text("from pywayland.protocol.wayland import *\n")
    protocols = [Protocol.parse_file(str(path)) for path in files]
    imports = {value.name: "wayland" for _, value in inspect.getmembers(wayland)
               if inspect.isclass(value) and issubclass(value, Interface) and value is not Interface}
    imports.update({interface.name: protocol.name for protocol in protocols for interface in protocol.interface})
    for protocol in protocols:
        protocol.output(str(output), imports)


if __name__ == "__main__":
    generate(sys.argv[1], sys.argv[2:])
