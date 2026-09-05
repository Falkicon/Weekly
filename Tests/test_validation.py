import importlib.util
from contextlib import redirect_stdout
import io
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch


VALIDATE_PATH = Path(__file__).parents[1] / "Tools" / "validate.py"
SPEC = importlib.util.spec_from_file_location("weekly_validate", VALIDATE_PATH)
validate = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(validate)


class ValidationHelpersTest(unittest.TestCase):
    def test_locale_lexer_ignores_comments_and_string_contents(self):
        source = r'''
-- L["comment-key"]
local text = "L['inside-string']"
local plain = L["plain-key"]
local quoted = L['single\'quote']
local escaped = L["double\"quote"]
'''

        self.assertEqual(
            ["plain-key", "single'quote", 'double"quote'],
            list(validate.locale_keys(source)),
        )

    def test_locale_definitions_only_include_assignment_keys(self):
        source = 'local used = L["used"]\nL[\'defined\'] = true\n'

        self.assertEqual(["defined"], list(validate.locale_keys(source, definitions=True)))

    def test_package_ignores_match_directories_and_descendants(self):
        source = """
ignore:
  - Docs
  - Tools # local tooling
  - 'Assets/Build'
"""

        patterns = validate.package_ignores(source)

        self.assertEqual(["Docs", "Tools", "Assets/Build"], patterns)
        self.assertTrue(validate.is_ignored("Docs/release-notes.md", patterns))
        self.assertTrue(validate.is_ignored("Tools/nested/validate.py", patterns))
        self.assertTrue(validate.is_ignored("Assets/Build/output.zip", patterns))
        self.assertFalse(validate.is_ignored("Documentation/release-notes.md", patterns))

    def test_release_toc_removes_debug_block(self):
        source = """
Core.lua
#@debug@
DevMarker.lua
Dev/Discovery.lua
#@end-debug@
UI.lua
"""

        self.assertEqual(
            ["Core.lua", "DevMarker.lua", "Dev/Discovery.lua", "UI.lua"],
            validate.toc_references(source, release=False),
        )
        self.assertEqual(["Core.lua", "UI.lua"], validate.toc_references(source, release=True))


class ManifestValidationTest(unittest.TestCase):
    def test_manifest_follows_nested_xml_include_and_script_nodes(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "Weekly.toc").write_text("embeds.xml\n", encoding="utf-8")
            (root / "embeds.xml").write_text(
                "<Ui><Include file=\"Nested/child.xml\"/>"
                "<Frame><Scripts><Script file=\"Scripts/loaded.lua\"/>"
                "</Scripts></Frame></Ui>",
                encoding="utf-8",
            )
            (root / "Nested").mkdir()
            (root / "Nested/child.xml").write_text(
                "<Ui><Scripts><Script file=\"deep.lua\"/></Scripts></Ui>",
                encoding="utf-8",
            )

            files = {
                "Weekly.toc",
                "embeds.xml",
                "Nested/child.xml",
                "Nested/deep.lua",
                "Scripts/loaded.lua",
            }

            self.assertEqual([], validate.check_manifest(root, files))

    def test_manifest_reports_missing_release_dependency_and_case_mismatch(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "Weekly.toc").write_text("Nested/child.xml\n", encoding="utf-8")
            (root / "Nested").mkdir()
            (root / "Nested/child.xml").write_text(
                "<Ui><Include file=\"../Scripts/missing.lua\"/></Ui>",
                encoding="utf-8",
            )
            files = {"Weekly.toc", "Nested/child.xml", "Scripts/missing.lua"}

            errors = validate.check_manifest(root, files, release=True, ignores=("Scripts",))

            self.assertTrue(any("missing release dependency Scripts/missing.lua" in error for error in errors))

            (root / "Weekly.toc").write_text("only.lua\n", encoding="utf-8")
            (root / "Only.lua").write_text("-- exists with different case\n", encoding="utf-8")
            case_errors = validate.check_manifest(root, {"Weekly.toc", "Only.lua"})
            self.assertTrue(any("missing dependency only.lua" in error for error in case_errors))

    def test_manifest_rejects_dependency_outside_repository(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "Weekly.toc").write_text("../outside.lua\n", encoding="utf-8")

            errors = validate.check_manifest(root, {"Weekly.toc"})

            self.assertTrue(any("dependency escapes repository" in error for error in errors))


class ValidationCommandTest(unittest.TestCase):
    def test_orphan_season_is_not_silently_omitted_from_validation(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "Weekly.toc").write_text("Data\\Midnight\\Season1.lua\n", encoding="utf-8")
            errors = validate.check_season_manifest(root, {
                "Data/Midnight/Season1.lua", "Data/Midnight/Season2.lua", "Data/Factories.lua"
            })
            self.assertEqual(["Data/Midnight/Season2.lua: seasonal dataset is not listed in Weekly.toc"], errors)

    def test_tool_failure_returns_nonzero_and_runs_both_lua_suites(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "Tools").mkdir()
            (root / "Tools/toolchain.json").write_text(
                json.dumps({"lua": "5.1", "busted": "2.2.0-1", "luacheck": "1.2.0-1"}),
                encoding="utf-8",
            )
            labels = []

            def fake_run(label, args, root=validate.ROOT, capture=False):
                labels.append(label)
                if label == "Lua version":
                    return "Lua 5.1\n"
                if label == "busted version":
                    return "Busted 2.2.0-1\n"
                if label == "luacheck version":
                    return "Luacheck 1.2.0-1\n"
                if label == "Addon tests":
                    raise RuntimeError("simulated addon test failure")
                return ""

            with patch.object(validate, "ROOT", root), \
                    patch.object(validate, "run_command", side_effect=fake_run), \
                    patch.object(validate, "repository_files", return_value=set()), \
                    patch.object(validate, "check_localization", return_value=[]), \
                    patch.object(validate, "check_manifest", return_value=[]), \
                    patch.object(validate, "check_package", return_value=[]), \
                    patch.object(validate, "check_season_manifest", return_value=[]), \
                    redirect_stdout(io.StringIO()) as output:
                result = validate.main([
                    "--lua", "lua5.1",
                    "--busted", "busted",
                    "--luacheck", "luacheck",
                ])

            self.assertEqual(1, result)
            self.assertIn("simulated addon test failure", output.getvalue())
            self.assertIn("Addon tests", labels)
            self.assertIn("Pure action tests", labels)


if __name__ == "__main__":
    unittest.main()
