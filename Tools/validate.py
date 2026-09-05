"""Run Weekly's complete local/CI checks. Requires Python 3.10+, Git and Lua tooling.

No packages are installed and no release files are written by validation.
The release check follows the checked-out dependency tree and .pkgmeta ignore
rules; it does not fetch CurseForge externals or replace the release packager.
"""

import argparse
import fnmatch
import json
from pathlib import Path, PurePosixPath
import posixpath
import re
import shutil
import subprocess
import sys
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parent.parent
LONG_BRACKET = re.compile(r"\[(=*)\[")
IDENTIFIER = re.compile(r"[A-Za-z_][A-Za-z_0-9]*")


def lua_tokens(source):
    """Tokenize enough Lua to find literal locale keys without reading comments."""
    index = 0
    while index < len(source):
        char = source[index]
        if char.isspace():
            index += 1
            continue
        comment = source.startswith("--", index)
        start = index + 2 if comment else index
        bracket = LONG_BRACKET.match(source, start)
        if bracket:
            closing = "]" + bracket.group(1) + "]"
            end = source.find(closing, bracket.end())
            if end < 0:
                raise ValueError("Unterminated Lua long string/comment")
            if not comment:
                value = source[bracket.end():end]
                yield "string", value.removeprefix("\n")
            index = end + len(closing)
            continue
        if comment:
            end = source.find("\n", start)
            index = len(source) if end < 0 else end + 1
            continue
        if char in "\"'":
            quote = char
            value = []
            index += 1
            while index < len(source) and source[index] != quote:
                char = source[index]
                if char == "\\":
                    index += 1
                    if index >= len(source):
                        raise ValueError("Unterminated Lua string")
                    escape = source[index]
                    if escape.isdigit():
                        digits = re.match(r"[0-9]{1,3}", source[index:]).group()
                        value.append(chr(int(digits)))
                        index += len(digits)
                        continue
                    value.append({"n": "\n", "r": "\r", "t": "\t", "a": "\a", "b": "\b", "f": "\f", "v": "\v"}.get(escape, escape))
                else:
                    value.append(char)
                index += 1
            if index >= len(source):
                raise ValueError("Unterminated Lua string")
            yield "string", "".join(value)
            index += 1
            continue
        name = IDENTIFIER.match(source, index)
        if name:
            yield "name", name.group()
            index = name.end()
        else:
            yield "symbol", char
            index += 1


def locale_keys(source, definitions=False):
    tokens = list(lua_tokens(source))
    for index in range(len(tokens) - 3):
        if (tokens[index] == ("name", "L")
                and tokens[index + 1] == ("symbol", "[")
                and tokens[index + 2][0] == "string"
                and tokens[index + 3] == ("symbol", "]")):
            if not definitions or (index + 4 < len(tokens) and tokens[index + 4] == ("symbol", "=")):
                yield tokens[index + 2][1]


def repository_files(root):
    result = subprocess.run(
        ["git", "ls-files", "--cached", "--others", "--exclude-standard", "-z"],
        cwd=root, capture_output=True, check=True,
    )
    return {name for name in result.stdout.decode("utf-8").split("\0") if name and (root / name).is_file()}


def check_localization(root, files):
    defined = set(locale_keys((root / "Locales/enUS.lua").read_text(encoding="utf-8-sig"), definitions=True))
    errors = []
    for name in sorted(files):
        if not name.endswith(".lua") or name.split("/")[0] in {"Libs", "Tests", "Tools", "Locales"}:
            continue
        used = set(locale_keys((root / name).read_text(encoding="utf-8-sig")))
        errors.extend(f"{name}: undefined locale key {key!r}" for key in sorted(used - defined))
    return errors


def package_ignores(source):
    """Read the scalar ignore list used by this repository's .pkgmeta."""
    patterns = []
    in_ignore = False
    for line in source.splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue
        if not line[0].isspace():
            in_ignore = stripped == "ignore:"
            if stripped.startswith("ignore:") and not in_ignore:
                raise ValueError(".pkgmeta: use a block list for ignore rules")
            continue
        if in_ignore:
            if not stripped.startswith("- "):
                raise ValueError(".pkgmeta: unsupported ignore rule: " + stripped)
            value = stripped[2:].strip()
            if value.startswith(("'", '"')):
                if len(value) < 2 or value[-1] != value[0]:
                    raise ValueError(".pkgmeta: malformed quoted ignore rule")
                value = value[1:-1]
            else:
                value = value.split(" #", 1)[0].strip()
            if not value or any(char in value for char in "{}[]"):
                raise ValueError(".pkgmeta: unsupported ignore rule: " + value)
            patterns.append(value.replace("\\", "/").rstrip("/"))
    return patterns


def is_ignored(name, patterns):
    # Matching a directory also excludes all of its descendants.
    parts = PurePosixPath(name).parts
    prefixes = ("/".join(parts[:index]) for index in range(1, len(parts) + 1))
    return any(fnmatch.fnmatchcase(prefix, pattern) for prefix in prefixes for pattern in patterns)


def toc_references(source, release):
    debug = False
    references = []
    for line in source.splitlines():
        line = line.strip()
        if line == "#@debug@":
            if debug:
                raise ValueError("Nested TOC debug block")
            debug = True
        elif line == "#@end-debug@":
            if not debug:
                raise ValueError("Unmatched TOC debug block end")
            debug = False
        elif line and not line.startswith("#") and not (release and debug):
            references.append(line)
    if debug:
        raise ValueError("Unclosed TOC debug block")
    return references


def check_manifest(root, files, release=False, ignores=()):
    available = {name for name in files if not release or not is_ignored(name, ignores)}
    errors = []
    visited = set()

    def visit(parent, reference):
        reference = reference.replace("\\", "/")
        target = (root / parent).parent / reference
        try:
            target.resolve().relative_to(root.resolve())
        except ValueError:
            errors.append(f"{parent}: dependency escapes repository: {reference}")
            return
        # resolve() canonicalizes existing filename case on Windows. Keep the
        # lexical spelling for inventory comparison, as Linux/WoW packages do.
        name = posixpath.normpath(posixpath.join(str(PurePosixPath(parent).parent), reference))
        if name not in available:
            errors.append(f"{parent}: missing {'release ' if release else ''}dependency {name}")
            return
        if name in visited:
            return
        visited.add(name)
        if name.endswith(".xml"):
            try:
                document = ET.parse(root / name)
            except ET.ParseError as error:
                errors.append(f"{name}: invalid XML: {error}")
                return
            for element in document.iter():
                if element.tag.rsplit("}", 1)[-1] in {"Include", "Script"} and "file" in element.attrib:
                    visit(name, element.attrib["file"])

    if "Weekly.toc" not in available:
        return ["Weekly.toc missing from " + ("release" if release else "checkout")]
    for reference in toc_references((root / "Weekly.toc").read_text(encoding="utf-8-sig"), release):
        visit("Weekly.toc", reference)
    return errors


def check_package(root, files):
    ignores = package_ignores((root / ".pkgmeta").read_text(encoding="utf-8-sig"))
    errors = check_manifest(root, files, release=True, ignores=ignores)
    for name in sorted(files):
        if name.split("/")[0] in {"Tests", "Tools", "Docs", "Dev", ".github"} and not is_ignored(name, ignores):
            errors.append(f".pkgmeta: development file would ship: {name}")
    return errors


def check_season_manifest(root, files):
    listed = {name.replace("\\", "/") for name in toc_references(
        (root / "Weekly.toc").read_text(encoding="utf-8-sig"), release=False
    )}
    return [f"{name}: seasonal dataset is not listed in Weekly.toc"
            for name in sorted(files)
            if fnmatch.fnmatchcase(name, "Data/*/Season*.lua") and name not in listed]


def command(executable, script, lua):
    return [lua, str(Path(script).resolve())] if script else [executable]


def run_command(label, args, root=ROOT, capture=False):
    print(f"\n{label}", flush=True)
    result = subprocess.run(args, cwd=root, text=True, capture_output=capture)
    if capture:
        output = result.stdout + result.stderr
        print(output.strip(), flush=True)
    else:
        output = ""
    if result.returncode:
        raise RuntimeError(f"{label} failed (exit {result.returncode})")
    return output


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--lua", default=shutil.which("lua5.1") or shutil.which("lua") or "lua")
    parser.add_argument("--busted", default="busted")
    parser.add_argument("--busted-script", help="Run a Busted Lua entrypoint directly, bypassing its launcher")
    parser.add_argument("--luacheck", default="luacheck")
    parser.add_argument("--luacheck-script", help="Run a Luacheck Lua entrypoint directly")
    args = parser.parse_args(argv)
    versions = json.loads((ROOT / "Tools/toolchain.json").read_text())
    busted = command(args.busted, args.busted_script, args.lua)
    luacheck = command(args.luacheck, args.luacheck_script, args.lua)
    failures = []

    def stage(label, callback):
        try:
            callback()
        except (OSError, ValueError, RuntimeError, subprocess.CalledProcessError) as error:
            failures.append(f"{label}: {error}")
            print(f"FAIL: {failures[-1]}", flush=True)

    def versions_check():
        output = run_command("Lua version", [args.lua, "-e", "print(_VERSION)"], capture=True)
        if output.strip() != "Lua " + versions["lua"]:
            raise RuntimeError("Tests must run under Lua " + versions["lua"])
        for name, executable in (("busted", busted), ("luacheck", luacheck)):
            output = run_command(name + " version", executable + ["--version"], capture=True)
            expected = versions[name].rsplit("-", 1)[0]
            first_line = output.strip().splitlines()[0] if output.strip() else ""
            prefix = r"(?:busted\s*:?\s*)?" if name == "busted" else r"luacheck\s*:?\s*"
            if not re.match(prefix + re.escape(expected) + r"(?:-\d+)?(?:\s|$)", first_line, re.IGNORECASE):
                raise RuntimeError(f"Expected {name} {expected}; see Tools/toolchain.json")

    stage("Tool versions", versions_check)
    if failures:
        return 1
    stage("Validation tooling tests", lambda: run_command("Validation tooling tests", [sys.executable, "-m", "unittest", "discover", "-s", "Tests", "-p", "test_validation.py"]))

    def static_checks():
        files = repository_files(ROOT)
        errors = (check_localization(ROOT, files) + check_manifest(ROOT, files)
                  + check_package(ROOT, files) + check_season_manifest(ROOT, files))
        if errors:
            raise RuntimeError("\n".join(errors))
        print("Localization, checkout manifest, and release dependency checks passed.", flush=True)

    stage("Static checks", static_checks)
    stage("Lua lint", lambda: run_command("Lua lint", luacheck + ["."]))
    stage("Addon tests (including data validation and lifecycle)", lambda: run_command("Addon tests", busted + ["--pattern=test_.*%.lua", "Tests"]))
    stage("Pure action tests", lambda: run_command("Pure action tests", busted + ["Tests/Core"]))
    stage("Diff whitespace", lambda: run_command("Diff whitespace", ["git", "-c", "core.safecrlf=false", "diff", "--check", "HEAD"]))
    if failures:
        print(f"\nValidation failed: {len(failures)} stage(s).", flush=True)
        return 1
    print("\nAll validation stages passed.", flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
