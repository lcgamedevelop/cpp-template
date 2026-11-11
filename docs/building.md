# 构建与交付

## 宿主准备

需要 CMake 3.25+、Git、Python 3.10+、vcpkg 和支持 C++20 的编译器。Windows 安装 Visual Studio 2022+ C++ 桌面开发工作负载，Linux 使用 GCC 或 Clang，macOS 安装 Xcode Command Line Tools。

脚本默认只检查工具及其可执行性，安装通过显式参数启用。Windows 默认使用 sccache，Linux / macOS 默认使用 ccache。

```powershell
./scripts/setup.ps1
./scripts/setup.ps1 -Install
```

```sh
bash scripts/setup.sh --check
bash scripts/setup.sh --install
```

Windows 安装通过 WinGet，macOS 通过 Homebrew，Linux 支持 apt-get、dnf 和 pacman。脚本准备 CMake、Git、Ninja 和所选缓存。编译器、平台 SDK、Python 和 vcpkg 由宿主提供。`-Cache ccache` 或 `--cache sccache` 可选择其他缓存，`none` 用于显式关闭工具检查中的缓存项。Ninja 缓存预设仍要求缓存可用。

将 vcpkg 克隆到选定位置，执行对应系统的 bootstrap 脚本，再设置 `VCPKG_ROOT`。已有安装直接复用。PowerShell 示例使用仓库相邻的 vcpkg。

```powershell
git clone https://github.com/microsoft/vcpkg.git ../vcpkg
& ../vcpkg/bootstrap-vcpkg.bat
$env:VCPKG_ROOT = (Resolve-Path ../vcpkg).Path
```

```sh
git clone https://github.com/microsoft/vcpkg.git ../vcpkg
../vcpkg/bootstrap-vcpkg.sh
export VCPKG_ROOT="$(cd ../vcpkg && pwd)"
```

依赖版本由 `vcpkg.json` 固定，首次配置需要联网获取依赖。各预设的依赖安装树独立放在 `build/dependencies/<preset>/`，并复用 vcpkg 二进制缓存。切换编译器、架构或 triplet 时使用独立预设，保留已有安装树和增量产物。

## CMake Presets

根目录 `CMakePresets.json` 是配置、构建和测试入口。

| 预设 | 生成器 | 构建目录 | workflow 行为 |
| --- | --- | --- | --- |
| `debug` | 平台默认 | `build/debug/` | 配置与 Debug 构建 |
| `release` | 平台默认 | `build/release/` | 配置、Release 构建与测试 |
| `ninja-debug` | Ninja | `build/ninja-debug/` | 配置与 Debug 构建，要求编译缓存 |
| `ninja-release` | Ninja | `build/ninja-release/` | 配置、Release 构建与测试，要求编译缓存 |

```sh
cmake --workflow --preset ninja-debug
cmake --workflow --preset ninja-release
```

也可分步运行。Release CTest 包含交付用例，会调用导出目标并运行导出的程序。

```sh
cmake --preset ninja-release
cmake --build --preset ninja-release
ctest --preset ninja-release
```

Windows 的 Ninja 构建在 Visual Studio Developer PowerShell 中执行，使 `cl`、SDK 和链接库可用。原生 `debug` / `release` 通常采用 Visual Studio 多配置生成器。Linux / macOS 默认生成器由 CMake 选择。切换编译器、生成器或 triplet 时使用独立构建目录。单配置采用 `CMAKE_BUILD_TYPE`，多配置由 build / test preset 的 `configuration` 选择配置。

缓存仅应用于本项目目标。原生 Makefiles / Ninja 在缓存可用时使用缓存，Ninja 缓存预设在工具缺失、无法执行或缓存被禁用时配置失败。Visual Studio 原生生成器保留其增量构建机制。MSVC Ninja 使用英文依赖诊断和内嵌对象调试信息，以支持 sccache。

## 三类目录

```text
platforms/
  desktop/main.cpp            # Windows / Linux / macOS 共用程序入口
cmake/
  core/                       # 共享目标选项与编译配置
  dependencies/               # 依赖查找
  platforms/                  # 平台目标装配
  install/                    # 编译缓存与交付配置
build/
  <preset>/                   # CMake、Ninja/IDE 工程、对象、静态库和调试符号
  dependencies/<preset>/      # 按预设隔离的 vcpkg 依赖安装树
output/
  <platform>/<arch>/<debug|release>/runtime/
```

平台专用工程、入口、源文件和打包资源放在 `platforms/<platform>/`，例如 `platforms/windows/`、`platforms/linux/`、`platforms/macos/`。共享库代码放在 `src/` 和 `include/`。当前入口由三个桌面平台共用，放在 `platforms/desktop/`。编译参数和平台选择集中在目标级 CMake 中。

`build/` 保留编译缓存、依赖、静态归档和调试符号。`output/` 收集最终可执行程序及许可证。Windows 交付一个 EXE，第三方库和 MSVC CRT 静态链接。生成内容由 Git 忽略，仅保存空目录占位。

## 导出与运行

单独导出通过现有构建预设选择导出目标，无需运行测试。

```sh
cmake --build --preset ninja-release --target cpp_template_export
```

导出目标依赖程序目标，通过 Python 在临时目录完成 CMake `runtime` 安装组件的部署，再替换交付目录。成功后清除旧产物，安装失败保留上一版，发布失败执行恢复。恢复受文件占用等原因阻止时保留备份并报告位置。同一交付目录使用进程锁协调并发导出。

平台名使用 `windows`、`linux`、`macos`，常见架构统一为 `x64`、`x86`、`arm64`。macOS 多架构构建使用 `universal`。

| 平台示例 | 程序位置 |
| --- | --- |
| Windows x64 | `output/windows/x64/release/runtime/cpp_template_app.exe` |
| Linux x64 | `output/linux/x64/release/runtime/cpp_template_app` |
| macOS ARM64 | `output/macos/arm64/release/runtime/cpp_template_app` |

传入 `Alice` 会输出 `Hello, Alice!`。Windows EXE 独立运行，静态库、对象和 PDB 保留在 `build/`。程序许可证放在运行目录的 `LICENSE`，fmt 的 vcpkg 版权文件放在 `licenses/fmt.txt`。macOS 默认交付直接运行的原生可执行文件。

Windows 独立构建在 `project()` 初始化工具链之前选择静态依赖。默认 triplet 根据 Visual Studio 生成器的平台、Developer PowerShell 目标架构或宿主架构选择 `x64-windows-static`、`x86-windows-static` 或 `arm64-windows-static`。跨工具链构建显式提供匹配的静态 triplet。

MSVC 运行库通过 `CMAKE_MSVC_RUNTIME_LIBRARY=MultiThreaded$<$<CONFIG:Debug>:Debug>` 初始化目标属性，Debug 使用 `/MTd`，Release 使用 `/MT`。所有默认预设及手动 CI 使用这一配置。Windows 导出要求静态依赖和静态 CRT，配置与安装阶段检查依赖，Release 用例继续检查 EXE 导入表并实际运行。[CMake 运行库属性](https://cmake.org/cmake/help/v3.25/variable/CMAKE_MSVC_RUNTIME_LIBRARY.html)、[MSVC 运行库选项](https://learn.microsoft.com/en-us/cpp/build/reference/md-mt-ld-use-run-time-library?view=msvc-170)

程序许可证位于运行目录，程序及第三方版权文本随交付保留。初始化为新项目后，目标与程序名同步更新。项目使用运行资源时，在所属安装模块声明独立资源的部署。

## 构建选项

| 选项 | 顶层默认值 | 用途 |
| --- | --- | --- |
| `CPP_TEMPLATE_BUILD_APP` | `ON` | 构建桌面命令行程序 |
| `CPP_TEMPLATE_BUILD_TESTS` | `ON` | 构建本项目测试，同时受 `BUILD_TESTING` 控制 |
| `CPP_TEMPLATE_WARNINGS_AS_ERRORS` | `OFF` | 将本项目目标的警告视为错误，CI 开启 |
| `CPP_TEMPLATE_USE_COMPILER_CACHE` | `ON` | 使用可用的 ccache / sccache |
| `CPP_TEMPLATE_REQUIRE_COMPILER_CACHE` | `OFF` | 缓存不可用时配置失败，Ninja 缓存预设开启 |

作为 `add_subdirectory()` 子项目使用时，示例程序与本项目测试默认关闭。链接 `cpp_template::core` 复用库及其 C++20 要求。宿主统一配置 vcpkg 与 CRT。交付目标仅由独立构建创建。
