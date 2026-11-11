execute_process(COMMAND "${CMAKE_COMMAND}" --build "${BUILD_DIR}" --config "${CONFIG}"
                        --target cpp_template_export
                RESULT_VARIABLE export_status)
if(NOT export_status STREQUAL "0")
    message(FATAL_ERROR "Application export failed")
endif()

if(NOT EXISTS "${OUTPUT_DIR}/${APP_NAME}")
    message(FATAL_ERROR "Exported application is missing: ${OUTPUT_DIR}/${APP_NAME}")
endif()
if(NOT EXISTS "${OUTPUT_DIR}/LICENSE" OR NOT EXISTS "${OUTPUT_DIR}/licenses/fmt.txt")
    message(FATAL_ERROR "Exported application licenses are missing")
endif()
file(GLOB_RECURSE build_artifacts "${OUTPUT_DIR}/*.lib" "${OUTPUT_DIR}/*.a" "${OUTPUT_DIR}/*.pdb"
     "${OUTPUT_DIR}/*.obj" "${OUTPUT_DIR}/*.o" "${OUTPUT_DIR}/CMakeCache.txt")
if(build_artifacts)
    message(FATAL_ERROR "Build artifacts leaked into the runtime export: ${build_artifacts}")
endif()

if(WIN32)
    file(GLOB_RECURSE exported_dlls "${OUTPUT_DIR}/*.dll")
    file(GLOB exported_executables "${OUTPUT_DIR}/*.exe")
    list(LENGTH exported_executables executable_count)
    if(exported_dlls OR NOT executable_count EQUAL 1)
        message(FATAL_ERROR "Windows export must contain one executable and zero companion DLLs")
    endif()
    if(DEPENDENCY_TOOL)
        execute_process(COMMAND "${DEPENDENCY_TOOL}" /nologo /dependents "${OUTPUT_DIR}/${APP_NAME}"
                        RESULT_VARIABLE dependency_status OUTPUT_VARIABLE dependency_output)
        if(NOT dependency_status STREQUAL "0")
            message(FATAL_ERROR "Cannot inspect executable imports: ${dependency_status}")
        endif()
        string(TOLOWER "${dependency_output}" dependency_output)
        string(REGEX MATCHALL "[a-z0-9_.+-]+\\.dll" imported_dlls "${dependency_output}")
        foreach(imported_dll IN LISTS imported_dlls)
            if(imported_dll MATCHES "^(vcruntime|msvcp|msvcr|ucrtbase|api-ms-win-crt-)")
                message(FATAL_ERROR "Executable imports a dynamic C/C++ runtime: ${imported_dll}")
            endif()
            if(NOT imported_dll MATCHES "^(api-ms-|ext-ms-)"
               AND NOT EXISTS "$ENV{SystemRoot}/System32/${imported_dll}"
               AND NOT EXISTS "$ENV{SystemRoot}/SysWOW64/${imported_dll}")
                message(FATAL_ERROR "Executable imports a companion DLL: ${imported_dll}")
            endif()
        endforeach()
    endif()
endif()

execute_process(COMMAND "${OUTPUT_DIR}/${APP_NAME}" CTest
                WORKING_DIRECTORY "${OUTPUT_DIR}" RESULT_VARIABLE app_status
                OUTPUT_VARIABLE app_output)
if(NOT app_status STREQUAL "0" OR NOT app_output STREQUAL "Hello, CTest!\n")
    message(FATAL_ERROR "Exported application failed: ${app_status}; ${app_output}")
endif()
