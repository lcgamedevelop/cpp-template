add_executable(cpp_template_tests core/greeting_test.cpp)
target_link_libraries(cpp_template_tests PRIVATE cpp_template::core)
cpp_template_apply_options(cpp_template_tests)
add_test(NAME cpp_template.unit COMMAND cpp_template_tests)

if(PROJECT_IS_TOP_LEVEL)
    find_package(Python3 3.10 REQUIRED COMPONENTS Interpreter)
    add_test(NAME cpp_template.compiler_cache
        COMMAND "${Python3_EXECUTABLE}" -m unittest discover
                -s "${CMAKE_CURRENT_SOURCE_DIR}/build" -p test_compiler_cache.py -v)
endif()

if(CPP_TEMPLATE_BUILD_APP)
    add_test(NAME cpp_template.cli COMMAND cpp_template_app CTest)
    set_tests_properties(cpp_template.cli PROPERTIES PASS_REGULAR_EXPRESSION "Hello, CTest!")
    add_test(NAME cpp_template.cli_default COMMAND cpp_template_app)
    set_tests_properties(cpp_template.cli_default PROPERTIES PASS_REGULAR_EXPRESSION "Hello, World!")

    if(PROJECT_IS_TOP_LEVEL)
        if(WIN32 AND MSVC)
            get_filename_component(_cpp_template_compiler_dir "${CMAKE_CXX_COMPILER}" DIRECTORY)
            find_program(CPP_TEMPLATE_DUMPBIN NAMES dumpbin
                         HINTS "${_cpp_template_compiler_dir}" REQUIRED)
        endif()
        add_test(NAME cpp_template.export
            COMMAND "${CMAKE_COMMAND}" "-DBUILD_DIR=${PROJECT_BINARY_DIR}"
                    "-DCONFIG=$<CONFIG>" "-DOUTPUT_DIR=${_cpp_template_export_root}/runtime"
                    "-DAPP_NAME=$<TARGET_FILE_NAME:cpp_template_app>"
                    "-DDEPENDENCY_TOOL=${CPP_TEMPLATE_DUMPBIN}"
                    -P "${CMAKE_CURRENT_SOURCE_DIR}/build/export_test.cmake")
    endif()
endif()
