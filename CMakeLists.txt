cmake_minimum_required(VERSION 3.25)

if(CMAKE_SOURCE_DIR STREQUAL CMAKE_BINARY_DIR)
    message(FATAL_ERROR "In-source builds are unsupported. Use a preset with a build/ directory.")
endif()

include(cmake/platforms/windows_defaults.cmake)

project(cpp_template VERSION 0.1.0 DESCRIPTION "Reusable C++20 project template" LANGUAGES CXX)

include(cmake/core/options.cmake)
include(cmake/install/compiler_cache.cmake)
include(cmake/core/target_options.cmake)
include(cmake/dependencies/core.cmake)

add_library(cpp_template_core STATIC src/greeting.cpp)
add_library(cpp_template::core ALIAS cpp_template_core)
target_compile_features(cpp_template_core PUBLIC cxx_std_20)
target_include_directories(cpp_template_core
    PUBLIC "$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>")
target_link_libraries(cpp_template_core PRIVATE fmt::fmt)
target_compile_definitions(cpp_template_core PRIVATE FMT_EXCEPTIONS=0)
cpp_template_apply_options(cpp_template_core)

include(cmake/platforms/desktop.cmake)
include(cmake/install/exports.cmake)

if(PROJECT_IS_TOP_LEVEL OR CPP_TEMPLATE_BUILD_TESTS)
    include(CTest)
endif()

if(BUILD_TESTING AND CPP_TEMPLATE_BUILD_TESTS)
    add_subdirectory(tests)
endif()
