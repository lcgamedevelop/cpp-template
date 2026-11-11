include_guard(GLOBAL)

if(NOT CPP_TEMPLATE_BUILD_APP)
    return()
endif()

if(NOT CMAKE_SYSTEM_NAME MATCHES "^(Windows|Linux|Darwin)$")
    message(FATAL_ERROR "The example app supports Windows, Linux and macOS. "
                        "Disable CPP_TEMPLATE_BUILD_APP for other platforms.")
endif()

add_executable(cpp_template_app "${PROJECT_SOURCE_DIR}/platforms/desktop/main.cpp")
target_link_libraries(cpp_template_app PRIVATE cpp_template::core)
cpp_template_apply_options(cpp_template_app)
