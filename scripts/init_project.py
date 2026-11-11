#!/usr/bin/env python3
"""Initialize a new repository created from this template using the Python standard library."""

import argparse
from pathlib import Path
import re


# C++20 保留字、标准命名空间及 Windows 保留目录名不可用作项目标识。
RESERVED_NAMES = frozenset("""
alignas alignof and and_eq asm atomic_cancel atomic_commit atomic_noexcept auto
bitand bitor bool break case catch char char8_t char16_t char32_t class compl
concept const consteval constexpr constinit const_cast continue co_await co_return
co_yield decltype default delete do double dynamic_cast else enum explicit export
extern false float for friend goto if import inline int long module mutable
namespace new noexcept not not_eq nullptr operator or or_eq private protected public
register reinterpret_cast requires return short signed sizeof static static_assert
static_cast struct switch synchronized template this thread_local throw true try
typedef typeid typename union unsigned using virtual void volatile wchar_t while xor
xor_eq std con prn aux nul
""".split()) | {f"{prefix}{number}" for prefix in ("com", "lpt") for number in range(1, 10)}

TEXT_SUFFIXES = frozenset({
    ".c", ".cc", ".cpp", ".cxx", ".h", ".hpp", ".hxx", ".inl", ".m", ".mm",
    ".cmake", ".md", ".json", ".yml", ".yaml", ".txt", ".in", ".xml", ".manifest",
    ".rc", ".plist", ".java", ".kt", ".gradle", ".kts", ".properties", ".toml",
    ".py", ".sh", ".ps1", ".bat", ".cmd",
})


def initialize_project(root: Path, name: str) -> None:
    """Validate the name, update project identifiers and rename the public include directory."""
    if not re.fullmatch(r"[a-z][a-z0-9]*(?:-[a-z0-9]+)*", name):
        raise ValueError("Use lowercase letters, digits and single hyphens, starting with a letter.")

    identifier = name.replace("-", "_")
    if identifier in RESERVED_NAMES:
        raise ValueError("The project name cannot be a C++ keyword, std or a Windows reserved name.")

    root = root.resolve()
    template_include = root / "include" / "cpp_template"
    if not template_include.is_dir() or not (root / "CMakeLists.txt").is_file():
        raise ValueError("Template files are missing. Run this once in a complete template checkout.")

    destination = template_include.with_name(identifier)
    if destination != template_include and destination.exists():
        raise ValueError(f"The destination include directory already exists: {destination}")

    replacements = (
        ("CPP_TEMPLATE", identifier.upper()),
        ("cpp_template", identifier),
        ("cpp-template", name),
    )
    files = [
        root / path
        for path in ("CMakeLists.txt", "CMakePresets.json", "vcpkg.json", "README.md", "AGENTS.md")
    ]
    for directory in ("cmake", "docs", "include", "src", "platforms", "tests", ".github"):
        files.extend(
            path for path in (root / directory).rglob("*")
            if path.is_file() and (path.name == "CMakeLists.txt" or path.suffix in TEXT_SUFFIXES)
        )

    # 先完成全部读取，避免编码或文件读取错误导致只更新部分文件。
    updates = []
    for path in files:
        if not path.is_file():
            continue
        original = path.read_text(encoding="utf-8")
        updated = original
        for old, new in replacements:
            updated = updated.replace(old, new)
        if updated != original:
            updates.append((path, updated))

    for path, content in updates:
        path.write_text(content, encoding="utf-8", newline="\n")
    if destination != template_include:
        template_include.rename(destination)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("name", help="New project name, for example my-app")
    arguments = parser.parse_args()
    try:
        initialize_project(Path(__file__).resolve().parent.parent, arguments.name)
    except (OSError, UnicodeError, ValueError) as error:
        parser.exit(1, f"Initialization failed: {error}\n")
    print(f"Initialized {arguments.name}. Run cmake --workflow --preset ninja-release.")


if __name__ == "__main__":
    main()
