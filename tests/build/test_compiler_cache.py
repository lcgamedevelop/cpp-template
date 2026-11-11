"""Test required compiler-cache failures through the actual CMake module."""

import json
from pathlib import Path
import subprocess
import unittest


ROOT = Path(__file__).resolve().parents[2]
PROJECT_PREFIX = json.loads((ROOT / "vcpkg.json").read_text(encoding="utf-8"))["name"]
PROJECT_PREFIX = PROJECT_PREFIX.replace("-", "_").upper()


class CompilerCacheTests(unittest.TestCase):
    def test_dependency_install_trees_are_isolated_by_preset(self):
        presets = json.loads((ROOT / "CMakePresets.json").read_text(encoding="utf-8"))
        base = next(preset for preset in presets["configurePresets"] if preset["name"] == "vcpkg")
        self.assertEqual(base["cacheVariables"]["VCPKG_INSTALLED_DIR"],
                         "${sourceDir}/build/dependencies/${presetName}")

    def configure_cache(self, generator="Ninja", **variables):
        command = ["cmake", f"-DCMAKE_GENERATOR={generator}"]
        command.extend(f"-D{PROJECT_PREFIX}_{name}={value}" for name, value in variables.items())
        command.extend(["-P", str(ROOT / "cmake/install/compiler_cache.cmake")])
        return subprocess.run(command, capture_output=True, text=True, check=False)

    def test_required_cache_cannot_be_disabled(self):
        result = self.configure_cache(USE_COMPILER_CACHE="OFF", REQUIRE_COMPILER_CACHE="ON")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("requires", result.stderr)

    def test_required_cache_rejects_unsupported_generator(self):
        result = self.configure_cache(generator="Xcode", USE_COMPILER_CACHE="ON",
                                      REQUIRE_COMPILER_CACHE="ON")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("requires a Ninja or Makefiles generator", result.stderr)

    def test_required_cache_must_be_executable(self):
        result = self.configure_cache(USE_COMPILER_CACHE="ON", REQUIRE_COMPILER_CACHE="ON",
                                      COMPILER_CACHE_PROGRAM=ROOT / "missing-compiler-cache")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Compiler cache cannot run", result.stderr)


if __name__ == "__main__":
    unittest.main()
