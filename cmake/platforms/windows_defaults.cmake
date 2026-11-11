include_guard(GLOBAL)

if(NOT CMAKE_CURRENT_SOURCE_DIR STREQUAL CMAKE_SOURCE_DIR
   OR NOT CMAKE_HOST_WIN32
   OR (CMAKE_SYSTEM_NAME AND NOT CMAKE_SYSTEM_NAME STREQUAL "Windows"))
    return()
endif()

# vcpkg 在 project() 初始化工具链时读取 triplet。
if(NOT VCPKG_TARGET_TRIPLET)
    if(CMAKE_GENERATOR_PLATFORM)
        string(REGEX REPLACE ",.*$" "" _cpp_template_windows_arch "${CMAKE_GENERATOR_PLATFORM}")
    elseif(CMAKE_VS_PLATFORM_NAME_DEFAULT)
        set(_cpp_template_windows_arch "${CMAKE_VS_PLATFORM_NAME_DEFAULT}")
    elseif(DEFINED ENV{VSCMD_ARG_TGT_ARCH})
        set(_cpp_template_windows_arch "$ENV{VSCMD_ARG_TGT_ARCH}")
    elseif(CMAKE_SYSTEM_PROCESSOR)
        set(_cpp_template_windows_arch "${CMAKE_SYSTEM_PROCESSOR}")
    else()
        set(_cpp_template_windows_arch "$ENV{PROCESSOR_ARCHITECTURE}")
    endif()
    string(TOLOWER "${_cpp_template_windows_arch}" _cpp_template_windows_arch)
    if(_cpp_template_windows_arch MATCHES "^(amd64|x86_64|x64)$")
        set(_cpp_template_windows_arch x64)
    elseif(_cpp_template_windows_arch MATCHES "^(win32|i[3-6]86|x86)$")
        set(_cpp_template_windows_arch x86)
    elseif(_cpp_template_windows_arch MATCHES "^(aarch64|arm64)$")
        set(_cpp_template_windows_arch arm64)
    else()
        message(FATAL_ERROR "Cannot determine the Windows target architecture. "
                            "Set VCPKG_TARGET_TRIPLET to a matching static triplet.")
    endif()
    set(VCPKG_TARGET_TRIPLET "${_cpp_template_windows_arch}-windows-static"
        CACHE STRING "vcpkg target triplet" FORCE)
endif()

if(NOT DEFINED CMAKE_MSVC_RUNTIME_LIBRARY)
    set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>"
        CACHE STRING "MSVC runtime library for standalone builds")
endif()
