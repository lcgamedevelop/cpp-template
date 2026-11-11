include_guard(GLOBAL)

if(NOT PROJECT_IS_TOP_LEVEL OR NOT TARGET cpp_template_app)
    return()
endif()

find_package(Python3 3.10 REQUIRED COMPONENTS Interpreter)

if(WIN32)
    get_target_property(_cpp_template_fmt_type fmt::fmt TYPE)
    if(_cpp_template_fmt_type STREQUAL "SHARED_LIBRARY")
        message(FATAL_ERROR "Windows export requires static dependencies. fmt is shared at ${fmt_DIR}. "
                            "Select a matching windows-static triplet. Clear stale fmt_DIR cache "
                            "entries when switching linkage.")
    endif()
    if(MSVC)
        get_target_property(_cpp_template_crt cpp_template_app MSVC_RUNTIME_LIBRARY)
        if(NOT _cpp_template_crt OR _cpp_template_crt MATCHES "DLL")
            message(FATAL_ERROR "Windows export requires a static MSVC runtime. "
                                "Set CMAKE_MSVC_RUNTIME_LIBRARY=MultiThreaded$<$<CONFIG:Debug>:Debug>.")
        endif()
    endif()
    # 依赖检查先于安装，完整安装成功后再由发布脚本替换输出。
    install(CODE "if(NOT \"$<TARGET_RUNTIME_DLLS:cpp_template_app>\" STREQUAL \"\")
        message(FATAL_ERROR \"Windows export contains shared-library dependencies\")
    endif()" COMPONENT runtime)
endif()

string(TOLOWER "${CMAKE_SYSTEM_NAME}" _cpp_template_platform)
if(_cpp_template_platform STREQUAL "darwin")
    set(_cpp_template_platform macos)
endif()

if(CMAKE_OSX_ARCHITECTURES)
    list(LENGTH CMAKE_OSX_ARCHITECTURES _cpp_template_arch_count)
    if(_cpp_template_arch_count GREATER 1)
        set(_cpp_template_arch universal)
    else()
        set(_cpp_template_arch "${CMAKE_OSX_ARCHITECTURES}")
    endif()
elseif(CMAKE_VS_PLATFORM_NAME)
    set(_cpp_template_arch "${CMAKE_VS_PLATFORM_NAME}")
elseif(MSVC AND CMAKE_CXX_COMPILER_ARCHITECTURE_ID)
    set(_cpp_template_arch "${CMAKE_CXX_COMPILER_ARCHITECTURE_ID}")
else()
    set(_cpp_template_arch "${CMAKE_SYSTEM_PROCESSOR}")
endif()
string(TOLOWER "${_cpp_template_arch}" _cpp_template_arch)
if(_cpp_template_arch MATCHES "^(amd64|x86_64)$")
    set(_cpp_template_arch x64)
elseif(_cpp_template_arch MATCHES "^(aarch64|arm64)$")
    set(_cpp_template_arch arm64)
elseif(_cpp_template_arch MATCHES "^(win32|i[3-6]86)$")
    set(_cpp_template_arch x86)
endif()

set(_cpp_template_export_root
    "${PROJECT_SOURCE_DIR}/output/${_cpp_template_platform}/${_cpp_template_arch}/$<LOWER_CASE:$<CONFIG>>")
install(TARGETS cpp_template_app RUNTIME DESTINATION runtime COMPONENT runtime)
install(FILES "${PROJECT_SOURCE_DIR}/LICENSE" DESTINATION runtime COMPONENT runtime)
install(FILES "${fmt_DIR}/copyright" DESTINATION runtime/licenses RENAME fmt.txt COMPONENT runtime)
add_custom_target(cpp_template_export
    COMMAND "${Python3_EXECUTABLE}" "${PROJECT_SOURCE_DIR}/scripts/export_app.py"
            --cmake "${CMAKE_COMMAND}" --build-dir "${PROJECT_BINARY_DIR}" --config "$<CONFIG>"
            --output "${_cpp_template_export_root}/runtime"
    DEPENDS cpp_template_app
    COMMENT "Exporting application to ${_cpp_template_export_root}/runtime"
    VERBATIM)
