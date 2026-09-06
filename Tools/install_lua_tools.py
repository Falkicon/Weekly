"""Install the pinned Lua tools into the caller's configured LuaRocks tree."""

import json
from pathlib import Path
import subprocess


def main():
    versions = json.loads(Path(__file__).with_name("toolchain.json").read_text())
    for tool in ("busted", "luacheck"):
        subprocess.run(
            ["luarocks", f"--lua-version={versions['lua']}", "install", tool, versions[tool]],
            check=True,
        )


if __name__ == "__main__":
    main()
