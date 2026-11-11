# 测试与验证

## 验证入口

C++ 或构建规则改动完成受影响的 Debug / Release 构建。功能验证统一使用 Release。根 workflow 将这一约定落实到命令入口。

```sh
cmake --workflow --preset ninja-debug
cmake --workflow --preset ninja-release
```

原生生成器对应使用 `debug` / `release`。Debug workflow 执行配置和编译，Release workflow 继续执行 CTest。通过后按需运行单项用例。

```sh
ctest --preset ninja-release -R cpp_template.unit
python -m unittest discover -s scripts/tests -v
```

脚本测试使用隔离临时目录，覆盖项目重命名、非法名称、目标冲突、重复初始化、完整模板更新、本地文件与平台二进制资源保护。导出脚本覆盖重复发布、安装失败、发布回滚、恢复失败时的备份保留和并发锁。构建规则用例通过实际 CMake 模块验证缓存要求。

## CTest 用例

| 用例 | 覆盖 |
| --- | --- |
| `cpp_template.unit` | 普通名字、有限长度 string_view、内嵌空字符、失败状态及输出清空 |
| `cpp_template.compiler_cache` | 依赖安装树按预设隔离，缓存必需时拒绝禁用、不可执行程序和不支持的生成器 |
| `cpp_template.cli` | 带参数的实际 CLI 输出 |
| `cpp_template.cli_default` | 无参数的默认输出 |
| `cpp_template.export` | 调用真实导出目标，检查单个 EXE 与许可证、静态运行库导入、构建产物隔离并运行程序 |

库单元测试通过正式接口和普通失败返回值校验，Release 下保持生效。构建规则用例位于 `tests/build/`，导出用例仅在独立构建且启用程序时登记。

## 平台覆盖

GitHub Actions 登记 Windows MSVC、Linux GCC/Clang 和 macOS AppleClang 的 Debug / Release 矩阵，手动运行后在 Actions 查看实际结果。宿主准备分别使用 Windows WinGet、macOS Homebrew 和 Linux 包管理器。

当前本地验证环境为 Windows x64、MSVC 19.44、CMake 4.4、Ninja 1.13 与 sccache 0.18。

- Ninja Debug / Release 构建通过，Release 的 5 项 CTest 通过。
- Visual Studio 原生生成器 Release 构建及 5 项 CTest 通过。
- 当前示例 Release EXE 的导入表只有 Windows 系统的 `KERNEL32.dll`。运行目录含单个 EXE 及项目、fmt 许可证文本。
- 12 项初始化与导出脚本测试通过，覆盖失败恢复和并发锁。
- 初始化后的项目完成静态 CRT / 静态依赖的 Release 构建、测试与单 EXE 导出运行。
- `add_subdirectory()` 消费者完成 Release 编译和运行，库集成保持程序、测试和导出目标默认关闭。显式关闭自动编译缓存的路径完成验证。
- Windows 宿主工具检查通过，Shell 安装脚本通过 Bash 语法检查。Linux / macOS 实际构建和包管理器安装路径待对应宿主验证，GitHub CI 待手动执行。

MSVC 关闭异常时会输出 D9025 选项覆盖提示，实际编译命令以 `/EHs-c-` 为准。CMake 3.25 与 Python 3.10 的最低版本组合待对应环境验证。
