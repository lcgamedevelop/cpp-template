# cpp-template

可复用的跨平台 C++20 模板，使用 CMake + vcpkg，支持 Windows、Linux 和 macOS。

- 静态库与命令行程序，实际编译、链接并使用 `{fmt}`。Windows 默认将第三方依赖和 MSVC CRT 静态合入单个 EXE。
- 平台入口位于 `platforms/`，增量构建位于 `build/`，最终交付位于 `output/`。
- CMake Presets、Ninja 编译缓存、CTest 和手动触发的三平台 CI。
- 项目初始化脚本，统一更新命名空间、头文件、平台入口、构建规则与文档。

## 快速开始

使用 GitHub 的 **Use this template → Create a new repository** 创建项目并克隆，然后在根目录执行一次。项目名使用小写字母、数字和连字符，以字母开头。

```sh
python scripts/init_project.py my-app
```

准备 CMake 3.25+、Python 3.10+、C++20 编译器与 vcpkg，设置 `VCPKG_ROOT`。Windows 使用 Visual Studio Developer PowerShell，运行 `./scripts/setup.ps1 -Install`。Linux / macOS 运行 `bash scripts/setup.sh --install`，准备 Ninja 与编译缓存。

```sh
cmake --workflow --preset ninja-debug
cmake --workflow --preset ninja-release
```

Debug workflow 完成构建，Release workflow 完成构建、测试及程序导出。默认交付到 `output/<platform>/<arch>/release/runtime/`。初始化后按项目需要更新本文件与 `LICENSE` 的版权归属。

## 文档

- [构建、平台目录与交付](docs/building.md)
- [开发、依赖与协作流程](docs/development.md)
- [测试与验证范围](docs/testing.md)
- [完整协作约定](AGENTS.md)

项目采用 [MIT License](LICENSE)。
