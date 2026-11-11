# 开发与第三方依赖

## 代码与职责

公共头文件位于 `include/cpp_template/`，共享实现位于 `src/`，桌面入口位于 `platforms/desktop/`。头文件从所属命名空间路径包含，例如 `#include "cpp_template/greeting.hpp"`。平台专用实现按平台放置，由 `cmake/platforms/` 选择和装配。

根 `CMakeLists.txt` 组织配置、依赖、共享库、平台程序、安装与测试。警告、异常和缓存通过目标级配置应用于自有目标，第三方保留自己的配置。`cpp_template::core` 向调用方传递 C++20 要求，fmt 保持实现私有依赖。

示例 `greeting(name, output)` 返回成功状态，空名字返回 `false` 并清空输出。调用方检查返回值，CLI 以英文错误信息和非零退出码报告失败。自有目标关闭 C++ 异常，fmt 调用使用编译期格式字符串并以 `FMT_EXCEPTIONS=0` 配置当前编译单元。

代码采用 Allman 大括号、4 空格、100 列与 UTF-8/LF。`.clang-format` 和 `.editorconfig` 为格式入口。源码字符串使用英文，本地化和 Unicode 测试数据通过独立资源承载。完整状态、错误、资源所有权、生命周期、访问权限、命名与模块边界约定见 [AGENTS.md](../AGENTS.md)。

## 第三方依赖

跨平台 port 由根 `vcpkg.json` 声明，版本由 `builtin-baseline` 和 `overrides` 固定。`VCPKG_ROOT` 指向已有 vcpkg，根 Presets 在配置时加载其工具链。

模板在 `cmake/dependencies/core.cmake` 中查找 `{fmt}`，`cpp_template_core` 链接 `fmt::fmt`，并在 `greeting()` 中实际调用格式化函数。新增依赖在 manifest 声明后，由所属依赖模块查找，再链接到实际消费者。

```cmake
# cmake/dependencies/core.cmake
find_package(example CONFIG REQUIRED)

# 使用该依赖的目标
target_link_libraries(cpp_template_core PRIVATE example::example)
```

实现内部使用的依赖采用 `PRIVATE`，公开头文件需要的依赖采用 `PUBLIC`。目标名称以包提供的 vcpkg usage 为准。依赖接入以实际编译和链接为验收。

`third_party/` 保存确需维护的补丁、overlay ports 和 triplets。对应设置写入 Presets 的 `VCPKG_OVERLAY_PORTS` / `VCPKG_OVERLAY_TRIPLETS`。没有适用 port 的源码依赖使用固定版本 Git 子项目，并保留许可和来源。补丁在构建前应用，普通构建复用现有依赖缓存。

## 项目初始化

`python scripts/init_project.py my-app` 将项目名改为 `my-app`，目标和命名空间改为 `my_app`，更新根配置、CMake 模块、头文件、共享实现、平台入口、C++ 测试、CI 和文档，并重命名公开头文件目录。

初始化先校验名称、目标目录和待修改文件的文本编码，再写入。脚本识别源码及配置的文本后缀，平台图标等二进制资源、本地脚本、第三方补丁、参考资料、构建缓存和交付产物保留原内容。新增文本格式时同步扩展脚本的 `TEXT_SUFFIXES`。脚本测试在隔离目录中验证这些边界。项目名称及目录调整采用当前版本的一次同步更新。

## 协作流程

一个功能在一个工作分支积累实现、修复和验证。独立功能从当时主干创建。完成后以 `git merge --no-ff` 合并一次，保留普通提交和明确的 merge commit。主干提交经由工作分支进入，既有初始化历史保留。

GitHub Actions 通过 `workflow_dispatch` 手动触发。工作流登记 Linux GCC、Linux Clang、Windows MSVC 和 macOS AppleClang 的 Ninja Debug / Release 构建，Release 运行测试。Action 固定完整提交 SHA，由 Dependabot 维护。实际执行结果以 Actions 为准。

构建命令与目录约定见[构建指南](building.md)，测试入口和已验证范围见[测试文档](testing.md)。
