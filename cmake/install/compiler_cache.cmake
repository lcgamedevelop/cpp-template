include_guard(GLOBAL)

if(CPP_TEMPLATE_REQUIRE_COMPILER_CACHE AND NOT CPP_TEMPLATE_USE_COMPILER_CACHE)
    message(FATAL_ERROR "CPP_TEMPLATE_REQUIRE_COMPILER_CACHE requires "
                        "CPP_TEMPLATE_USE_COMPILER_CACHE=ON")
endif()

if(CPP_TEMPLATE_USE_COMPILER_CACHE AND CMAKE_GENERATOR MATCHES "Makefiles|Ninja")
    if(CMAKE_HOST_WIN32)
        set(_cpp_template_cache_names sccache ccache)
    else()
        set(_cpp_template_cache_names ccache sccache)
    endif()
    find_program(CPP_TEMPLATE_COMPILER_CACHE_PROGRAM NAMES ${_cpp_template_cache_names}
                 NO_CMAKE_FIND_ROOT_PATH DOC "Compiler cache launcher for this project's targets")
    if(CPP_TEMPLATE_COMPILER_CACHE_PROGRAM)
        execute_process(COMMAND "${CPP_TEMPLATE_COMPILER_CACHE_PROGRAM}" --version
                        RESULT_VARIABLE _cpp_template_cache_status
                        OUTPUT_QUIET ERROR_QUIET TIMEOUT 10)
        if(NOT _cpp_template_cache_status STREQUAL "0")
            message(FATAL_ERROR "Compiler cache cannot run: ${CPP_TEMPLATE_COMPILER_CACHE_PROGRAM}")
        endif()
        message(STATUS "Compiler cache: ${CPP_TEMPLATE_COMPILER_CACHE_PROGRAM}")
    elseif(CPP_TEMPLATE_REQUIRE_COMPILER_CACHE)
        message(FATAL_ERROR "Compiler cache is required. Run scripts/setup.ps1 -Install "
                            "or scripts/setup.sh --install.")
    endif()
elseif(CPP_TEMPLATE_REQUIRE_COMPILER_CACHE)
    message(FATAL_ERROR "Compiler caching requires a Ninja or Makefiles generator. "
                        "Use a ninja preset.")
endif()

function(cpp_template_apply_compiler_cache target)
    if(NOT CMAKE_GENERATOR MATCHES "Makefiles|Ninja")
        return()
    endif()

    get_target_property(_launcher ${target} CXX_COMPILER_LAUNCHER)
    if(NOT _launcher)
        set(_launcher)
        if(CPP_TEMPLATE_USE_COMPILER_CACHE AND CPP_TEMPLATE_COMPILER_CACHE_PROGRAM)
            set(_launcher "${CPP_TEMPLATE_COMPILER_CACHE_PROGRAM}")
        endif()
    endif()
    if(CMAKE_HOST_WIN32 AND MSVC)
        # Ninja 的 /showIncludes 解析与缓存重放必须使用同一语言及构建目录。
        string(SHA256 _build_hash "${PROJECT_BINARY_DIR}")
        set(_cache_buster "cpp_template-msvc-vslang-1033:${_build_hash}")
        if(DEFINED ENV{SCCACHE_C_CUSTOM_CACHE_BUSTER})
            string(APPEND _cache_buster ":$ENV{SCCACHE_C_CUSTOM_CACHE_BUSTER}")
        endif()
        string(REPLACE ";" "\\;" _cache_buster "${_cache_buster}")
        list(PREPEND _launcher "${CMAKE_COMMAND}" -E env "VSLANG=1033"
             "SCCACHE_C_CUSTOM_CACHE_BUSTER=${_cache_buster}" --)
        set_property(TARGET ${target} PROPERTY MSVC_DEBUG_INFORMATION_FORMAT
                     "$<$<CONFIG:Debug,RelWithDebInfo>:Embedded>")
    endif()
    if(_launcher)
        set_property(TARGET ${target} PROPERTY CXX_COMPILER_LAUNCHER "${_launcher}")
    endif()
endfunction()
