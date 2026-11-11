include_guard(GLOBAL)

if(PROJECT_IS_TOP_LEVEL AND NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    set(CMAKE_BUILD_TYPE Debug CACHE STRING "Build configuration for single-config generators" FORCE)
endif()

option(CPP_TEMPLATE_BUILD_APP "Build the example command-line application" ${PROJECT_IS_TOP_LEVEL})
option(CPP_TEMPLATE_BUILD_TESTS "Build this project's tests" ${PROJECT_IS_TOP_LEVEL})
option(CPP_TEMPLATE_WARNINGS_AS_ERRORS "Treat warnings in this project's targets as errors" OFF)
option(CPP_TEMPLATE_USE_COMPILER_CACHE "Use an available ccache or sccache launcher" ON)
option(CPP_TEMPLATE_REQUIRE_COMPILER_CACHE "Fail when compiler caching is unavailable" OFF)
