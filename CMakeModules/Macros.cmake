MACRO(CONFIGURE_DEFAULTS)

    STRING(TOUPPER "${SHORT_NAME}" UPPER_SHORT_NAME)
    ADD_DEFINITIONS(-D${UPPER_SHORT_NAME}_VERSION=\"${VERSION}\")
    ADD_DEFINITIONS(-D${UPPER_SHORT_NAME}_MAJOR_VERSION=\"${MAJOR_VERSION}\")
    ADD_DEFINITIONS(-D${UPPER_SHORT_NAME}_MINOR_VERSION=\"${MINOR_VERSION}\")
    ADD_DEFINITIONS(-D${UPPER_SHORT_NAME}_PATCH_VERSION=\"${PATCH_VERSION}\")

    #Gles config
    if(ANDROID)
        if(USE_GLES1)
            set(GLES_LIBRARY -lGLESv1_CM)
        else()
            set(GLES_LIBRARY -lGLESv2)
        endif()
    elseif(APPLE)
    endif()
    
    include(DetermineCompiler)

    IF(UNIX AND NOT WIN32 AND NOT APPLE)
        IF(CMAKE_SIZEOF_VOID_P MATCHES "8")
            SET(LIB_POSTFIX "64" CACHE STRING "suffix for 32/64 dir placement")
            MARK_AS_ADVANCED(LIB_POSTFIX)
        ENDIF()
    ENDIF()
    IF(NOT DEFINED LIB_POSTFIX)
        SET(LIB_POSTFIX "")
    ENDIF()

    OPTION(BUILD_TREAT_WARNINGS_AS_ERRORS OFF "Enables -Werror or /WX")
    OPTION(BUILD_ENABLE_EFFECTIVE_CPP_WARNINGS OFF "Enables -Weffc++ or whatever required flag in other compilers if they exist")
    IF(MSVC)
        SET(EXTRA_CXX_FLAGS "/Wall /W3 /EHsc")
        IF(BUILD_TREAT_WARNINGS_AS_ERRORS)
             SET(EXTRA_CXX_FLAGS "${EXTRA_CXX_FLAGS} /WX")
        ENDIF()
        ADD_DEFINITIONS("-DWIN32")
    ELSE()
        SET(EXTRA_CXX_FLAGS " -W -Wall -Wextra -Wparentheses -Wno-long-long -Wno-import -pedantic -Wreturn-type -Wmissing-braces -Wunknown-pragmas -Wunused")
        IF(BUILD_TREAT_WARNINGS_AS_ERRORS)
             SET(EXTRA_CXX_FLAGS "${EXTRA_CXX_FLAGS} -Werror")
        ENDIF()
        IF(BUILD_ENABLE_EFFECTIVE_CPP_WARNINGS)
             SET(EXTRA_CXX_FLAGS "${EXTRA_CXX_FLAGS} -Weffc++")
        ENDIF()
        IF(UNIX)
            IF(APPLE)
               IF(CMAKE_COMPILER_IS_CLANGXX OR (CMAKE_GENERATOR STREQUAL Xcode) )
                    set(CMAKE_XCODE_ATTRIBUTE_CLANG_CXX_LANGUAGE_STANDARD "c++0x")
                    set(CMAKE_XCODE_ATTRIBUTE_CLANG_CXX_LIBRARY "libc++")
                    SET(EXTRA_CXX_FLAGS "${EXTRA_CXX_FLAGS}  -std=c++0x -stdlib=libc++ -U__STRICT_ANSI__")
                    SET(EXTRA_LINKER_FLAGS "${EXTRA_LINKER_FLAGS} -stdlib=libc++")
                ENDIF()
            ELSEIF(ANDROID)
                SET(EXTRA_CXX_FLAGS "${EXTRA_CXX_FLAGS} -std=gnu++0x -D__STDC_INT64__")
            ELSE()
                IF(CMAKE_COMPILER_IS_CLANGXX)
                    SET(EXTRA_CXX_FLAGS "${EXTRA_CXX_FLAGS} -std=c++11")
                ELSE()
                    SET(EXTRA_CXX_FLAGS "${EXTRA_CXX_FLAGS} -std=c++0x")
                ENDIF()
            ENDIF()
        ENDIF()
    ENDIF()

    IF(NOT CONFIG_HAS_BEEN_RUN_BEFORE)
        SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${EXTRA_CXX_FLAGS}" CACHE STRING "Flags used by the compiler during all build types." FORCE)
        SET(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} ${EXTRA_LINKER_FLAGS}" CACHE STRING "Flags used by the linker." FORCE)
        SET(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} ${EXTRA_LINKER_FLAGS}" CACHE STRING "Flags used by the linker." FORCE)
        SET(CMAKE_MODULE_LINKER_FLAGS "${CMAKE_MODULE_LINKER_FLAGS} ${EXTRA_LINKER_FLAGS}" CACHE STRING "Flags used by the linker." FORCE)
    ENDIF()

    SET(OUTPUT_BINDIR ${CMAKE_BINARY_DIR}/bin)
    MAKE_DIRECTORY(${OUTPUT_BINDIR})

    SET(OUTPUT_LIBDIR ${CMAKE_BINARY_DIR}/lib)
    MAKE_DIRECTORY(${OUTPUT_LIBDIR})
    IF(CMAKE_MAJOR_VERSION EQUAL 2 AND CMAKE_MINOR_VERSION GREATER 4)
        # If CMake >= 2.6.0
        SET(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${OUTPUT_LIBDIR})
        SET(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${OUTPUT_BINDIR})
        IF(WIN32)
            SET(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${OUTPUT_BINDIR})
        ELSE(WIN32)
            SET(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${OUTPUT_LIBDIR})
        ENDIF(WIN32)
    ELSE(CMAKE_MAJOR_VERSION EQUAL 2 AND CMAKE_MINOR_VERSION GREATER 4)
        SET(EXECUTABLE_OUTPUT_PATH ${OUTPUT_BINDIR})
        SET(LIBRARY_OUTPUT_PATH ${OUTPUT_LIBDIR})
    ENDIF(CMAKE_MAJOR_VERSION EQUAL 2 AND CMAKE_MINOR_VERSION GREATER 4)


    SET(dep_postfix lib)
    IF(WIN32)
        SET(dep_postfix bin)
    ENDIF(WIN32)

    # Dynamic vs Static Linking
    OPTION(DYNAMIC_${UPPER_SHORT_NAME} "Set to ON to build for dynamic linking.  Use OFF for static." ON)
    IF   (DYNAMIC_${UPPER_SHORT_NAME})
        SET(USER_DEFINED_DYNAMIC_OR_STATIC "SHARED")
    ELSE ()
        SET(USER_DEFINED_DYNAMIC_OR_STATIC "STATIC")
    ENDIF()

    IF(DYNAMIC_${UPPER_SHORT_NAME})
        ADD_DEFINITIONS(-D${UPPER_SHORT_NAME}_LIBRARY)
    ELSE()
        ADD_DEFINITIONS(-DUSE_STATIC)
    ENDIF()

    SET(CMAKE_DEBUG_POSTFIX "d" CACHE STRING "add a postfix, usually d on windows")
    SET(CMAKE_RELEASE_POSTFIX "" CACHE STRING "add a postfix, usually empty on windows")
    SET(CMAKE_RELWITHDEBINFO_POSTFIX "" CACHE STRING "add a postfix, usually empty on windows")
    SET(CMAKE_MINSIZEREL_POSTFIX "" CACHE STRING "add a postfix, usually empty on windows")

    # Set the build postfix extension according to what configuration is being built.
    IF (CMAKE_BUILD_TYPE MATCHES "Release")
        SET(CMAKE_BUILD_POSTFIX "${CMAKE_RELEASE_POSTFIX}")
    ELSEIF (CMAKE_BUILD_TYPE MATCHES "MinSizeRel")
        SET(CMAKE_BUILD_POSTFIX "${CMAKE_MINSIZEREL_POSTFIX}")
    ELSEIF(CMAKE_BUILD_TYPE MATCHES "RelWithDebInfo")
        SET(CMAKE_BUILD_POSTFIX "${CMAKE_RELWITHDEBINFO_POSTFIX}")
    ELSEIF(CMAKE_BUILD_TYPE MATCHES "Debug")
        SET(CMAKE_BUILD_POSTFIX "${CMAKE_DEBUG_POSTFIX}")
        ADD_DEFINITIONS(-D${UPPER_SHORT_NAME}_DEBUG)
    ELSE()
        SET(CMAKE_BUILD_POSTFIX "")
    ENDIF()

    # Set the library extension according to what configuration is being built.
    # If the string is empty, don't set the define.
    IF(CMAKE_DEBUG_POSTFIX)
        SET(CMAKE_CXX_FLAGS_DEBUG
            "${CMAKE_CXX_FLAGS_DEBUG} -DLIBRARY_POSTFIX=${CMAKE_DEBUG_POSTFIX}")
    ENDIF()
    IF(CMAKE_RELEASE_POSTFIX)
        SET(CMAKE_CXX_FLAGS_RELEASE
            "${CMAKE_CXX_FLAGS_RELEASE} -DLIBRARY_POSTFIX=${CMAKE_RELEASE_POSTFIX}")
    ENDIF()
    IF(CMAKE_RELWITHDEBINFO_POSTFIX)
        SET(CMAKE_CXX_FLAGS_RELWITHDEBINFO
            "${CMAKE_CXX_FLAGS_RELWITHDEBINFO} -DLIBRARY_POSTFIX=${CMAKE_RELWITHDEBINFO_POSTFIX}")
    ENDIF()
    IF(CMAKE_MINSIZEREL_POSTFIX)
        SET(CMAKE_CXX_FLAGS_MINSIZEREL
            "${CMAKE_CXX_FLAGS_MINSIZEREL} -DLIBRARY_POSTFIX=${CMAKE_MINSIZEREL_POSTFIX}")
    ENDIF()

    SET_PROPERTY(GLOBAL PROPERTY USE_FOLDERS ON)

    IF(NOT BIN_PATH)
        SET(BIN_PATH bin)
    ENDIF()
    IF(NOT INC_PATH)
        SET(INC_PATH include)
    ENDIF()
    IF(NOT LIB_PATH)
        SET(LIB_PATH lib)
    ENDIF()

    # I prefer not to ignore this kind of errors
    #IF(WIN32)
    #    ADD_DEFINITIONS(-D_CRT_SECURE_NO_WARNINGS)
    #ENDIF()

ENDMACRO(CONFIGURE_DEFAULTS)

MACRO(CONFIGURE_END)
    # This needs to be run very last so other parts of the scripts can take
    # advantage of this.
    IF(NOT CONFIG_HAS_BEEN_RUN_BEFORE)
        SET(CONFIG_HAS_BEEN_RUN_BEFORE 1 CACHE INTERNAL "Flag to track whether this is the first time running CMake or if CMake has been configured before")
    ENDIF(NOT CONFIG_HAS_BEEN_RUN_BEFORE)
ENDMACRO(CONFIGURE_END)

MACRO(SETUP_CORELIB CORELIB_NAME COMP)

    ADD_LIBRARY(${CORELIB_NAME}
        ${USER_DEFINED_DYNAMIC_OR_STATIC}
        ${HEADERS}
        ${SOURCES}
    )

    TARGET_LINK_LIBRARIES(${CORELIB_NAME} ${LIBRARIES})

    IF(LIBRARIES_OPTIMIZED)
        FOREACH(LIBOPT ${LIBRARIES_OPTIMIZED})
            TARGET_LINK_LIBRARIES(${CORELIB_NAME} optimized ${LIBOPT})
        ENDFOREACH(LIBOPT)
    ENDIF(LIBRARIES_OPTIMIZED)

    IF(LIBRARIES_DEBUG)
        FOREACH(LIBDEBUG ${LIBRARIES_DEBUG})
            TARGET_LINK_LIBRARIES(${CORELIB_NAME} debug ${LIBDEBUG})
        ENDFOREACH(LIBDEBUG)
    ENDIF(LIBRARIES_DEBUG)

    SET_TARGET_PROPERTIES(${CORELIB_NAME} PROPERTIES FOLDER "${SHORT_NAME} Libraries")

    IF(ANDROID)
        SET_TARGET_PROPERTIES(${CORELIB_NAME}
            PROPERTIES
            PROJECT_LABEL "${CORELIB_NAME}"
        )
    ELSE()
        SET_TARGET_PROPERTIES(${CORELIB_NAME}
            PROPERTIES
            PROJECT_LABEL "${CORELIB_NAME}"
            VERSION ${VERSION}
        )
    ENDIF()

    SET(install_dest_dir "${LIB_PATH}")
    IF(WIN32)
        SET(install_dest_dir "${BIN_PATH}")
    ENDIF(WIN32)
    IF(WIN32)
        FOREACH(BIN ${install_dest_dir})
            INSTALL(TARGETS ${CORELIB_NAME}
                    RUNTIME DESTINATION ${BIN} COMPONENT ${COMP}
            )
        ENDFOREACH()
        FOREACH(LIB ${LIB_PATH})
            INSTALL(TARGETS ${CORELIB_NAME}
                    ARCHIVE DESTINATION ${LIB} COMPONENT ${COMP}-dev
            )
    ENDFOREACH()

    ELSE(WIN32)
        FOREACH(BIN ${install_dest_dir})
            INSTALL(TARGETS ${CORELIB_NAME}
                    RUNTIME DESTINATION ${BIN} COMPONENT ${COMP}
                    LIBRARY DESTINATION ${BIN} COMPONENT ${COMP}
                    ARCHIVE DESTINATION ${BIN} COMPONENT ${COMP}-dev
            )
        ENDFOREACH()
    ENDIF(WIN32)
    FOREACH(INC ${INC_PATH})
        INSTALL(FILES ${HEADERS}
            DESTINATION ${INC}/${CORELIB_NAME}
            COMPONENT ${COMP}-dev
        )
    ENDFOREACH()

    IF(UNIX AND NOT APPLE)
        SET_TARGET_PROPERTIES ( ${CORELIB_NAME} PROPERTIES LINK_FLAGS "-Wl,-E")
    ENDIF(UNIX AND NOT APPLE)

ENDMACRO(SETUP_CORELIB)

#For Android native libraries
MACRO(SETUP_ANDROIDLIB ANDROIDLIB_NAME)

    ADD_LIBRARY(${ANDROIDLIB_NAME}
                ${USER_DEFINED_DYNAMIC_OR_STATIC}
        ${HEADERS}
        ${SOURCES}
    )

    TARGET_LINK_LIBRARIES(${ANDROIDLIB_NAME} ${LIBRARIES})

    IF(LIBRARIES_OPTIMIZED)
        FOREACH(LIBOPT ${LIBRARIES_OPTIMIZED})
            TARGET_LINK_LIBRARIES(${ANDROIDLIB_NAME} optimized ${LIBOPT})
        ENDFOREACH(LIBOPT)
    ENDIF(LIBRARIES_OPTIMIZED)

    IF(LIBRARIES_DEBUG)
        FOREACH(LIBDEBUG ${LIBRARIES_DEBUG})
            TARGET_LINK_LIBRARIES(${ANDROIDLIB_NAME} debug ${LIBDEBUG})
        ENDFOREACH(LIBDEBUG)
    ENDIF(LIBRARIES_DEBUG)

    SET_TARGET_PROPERTIES(${ANDROIDLIB_NAME}
        PROPERTIES
        PROJECT_LABEL "Android Native ${ANDROIDLIB_NAME}"
    )

    IF(UNIX AND NOT APPLE)
            SET_TARGET_PROPERTIES ( ${ANDROIDLIB_NAME} PROPERTIES LINK_FLAGS "-Wl,-E")
    ENDIF(UNIX AND NOT APPLE)

    add_custom_target(
        deploy_${ANDROIDLIB_NAME}
        COMMAND android update project -t "${DEPLOY_TARGET}" -p ${CMAKE_CURRENT_LIST_DIR}
        #The Java project is cleaned to force a complete rebuild. Changes in the native code
        #are not considered as such by the Java compiler.
        COMMAND ant clean -buildfile ${CMAKE_CURRENT_LIST_DIR}/build.xml
        COMMAND ${CMAKE_COMMAND}
        ARGS    -DDEPLOY_FILES="${DEPLOY_LIBRARIES}"
                -DDEPLOY_DIR=${CMAKE_CURRENT_LIST_DIR}/libs/${ANDROID_ABI}
                -P ${CMAKE_SOURCE_DIR}/CMakeModules/copy_files.cmake
        COMMAND ant debug -buildfile ${CMAKE_CURRENT_LIST_DIR}/build.xml
        DEPENDS ${ANDROIDLIB_NAME}
    )

    add_custom_target(
        deploy_install_${ANDROIDLIB_NAME}
        COMMAND android update project -t "${DEPLOY_TARGET}" -p ${CMAKE_CURRENT_LIST_DIR}
        #The Java project is cleaned to force a complete rebuild. Changes in the native code
        #are not considered as such by the Java compiler.
        COMMAND ant clean -buildfile ${CMAKE_CURRENT_LIST_DIR}/build.xml
        COMMAND ${CMAKE_COMMAND}
        ARGS    -DDEPLOY_FILES="${DEPLOY_LIBRARIES}"
                -DDEPLOY_DIR=${CMAKE_CURRENT_LIST_DIR}/libs/${ANDROID_ABI}
                -P ${CMAKE_SOURCE_DIR}/CMakeModules/copy_files.cmake
        COMMAND ant debug install -buildfile ${CMAKE_CURRENT_LIST_DIR}/build.xml
        DEPENDS ${ANDROIDLIB_NAME}
    )

    add_custom_target(
        clean_${ANDROIDLIB_NAME}
        COMMAND android update project -t "${DEPLOY_TARGET}" -p ${CMAKE_CURRENT_LIST_DIR}
        COMMAND ant clean -buildfile ${CMAKE_CURRENT_LIST_DIR}/build.xml
        COMMAND ${CMAKE_COMMAND} -E remove_directory ${CMAKE_CURRENT_LIST_DIR}/libs
    )

ENDMACRO(SETUP_ANDROIDLIB)

MACRO(SETUP_ANDROIDAPP ANDROIDAPP_NAME)

    add_custom_target(
        deploy_install_${ANDROIDAPP_NAME}
        COMMAND android update project -t "${DEPLOY_TARGET}" -p ${CMAKE_CURRENT_LIST_DIR}
        #The Java project is cleaned to force a complete rebuild. Changes in the native code
        #are not considered as such by the Java compiler.
        COMMAND ant clean -buildfile ${CMAKE_CURRENT_LIST_DIR}/build.xml
        COMMAND ${CMAKE_COMMAND}
        ARGS    -DDEPLOY_FILES="${DEPLOY_LIBRARIES}"
                -DDEPLOY_DIR=${CMAKE_CURRENT_LIST_DIR}/libs/${ANDROID_ABI}
                -P ${CMAKE_SOURCE_DIR}/CMakeModules/copy_files.cmake
        COMMAND ant debug install -buildfile ${CMAKE_CURRENT_LIST_DIR}/build.xml
        DEPENDS ${LIB_DEPENDS}
    )

    add_custom_target(
        clean_${ANDROIDAPP_NAME}
        COMMAND android update project -t "${DEPLOY_TARGET}" -p ${CMAKE_CURRENT_LIST_DIR}
        COMMAND ant clean -buildfile ${CMAKE_CURRENT_LIST_DIR}/build.xml
        COMMAND ${CMAKE_COMMAND} -E remove_directory ${CMAKE_CURRENT_LIST_DIR}/libs
    )

ENDMACRO(SETUP_ANDROIDAPP)

## Only for unit tests so no need to be installed
MACRO(SETUP_TEST_CORELIB CORELIB_NAME)

    ADD_LIBRARY(${CORELIB_NAME}
        ${USER_DEFINED_DYNAMIC_OR_STATIC}
        ${HEADERS}
        ${SOURCES}
    )

    TARGET_LINK_LIBRARIES(${CORELIB_NAME} ${LIBRARIES})

    IF(LIBRARIES_OPTIMIZED)
        FOREACH(LIBOPT ${LIBRARIES_OPTIMIZED})
            TARGET_LINK_LIBRARIES(${CORELIB_NAME} optimized ${LIBOPT})
        ENDFOREACH(LIBOPT)
    ENDIF(LIBRARIES_OPTIMIZED)

    IF(LIBRARIES_DEBUG)
        FOREACH(LIBDEBUG ${LIBRARIES_DEBUG})
            TARGET_LINK_LIBRARIES(${CORELIB_NAME} debug ${LIBDEBUG})
        ENDFOREACH(LIBDEBUG)
    ENDIF(LIBRARIES_DEBUG)

    SET_TARGET_PROPERTIES(${CORELIB_NAME} PROPERTIES FOLDER "Testing")
    SET_TARGET_PROPERTIES(${CORELIB_NAME}
        PROPERTIES
        PROJECT_LABEL "Core ${CORELIB_NAME}"
    )

    IF(UNIX AND NOT APPLE)
        SET_TARGET_PROPERTIES ( ${CORELIB_NAME} PROPERTIES LINK_FLAGS "-Wl,-E")
    ENDIF(UNIX AND NOT APPLE)

ENDMACRO(SETUP_TEST_CORELIB)

MACRO(SETUP_PLUGIN TARGET_NAME COMP)

    IF(ANDROID)
        SET(PLUGIN_PREFIX "lib_${SHORT_NAME}_")
    ENDIF()

    IF(NOT PLUGIN_NAME)
            SET(PLUGIN_NAME "${PLUGIN_PREFIX}${TARGET_NAME}")
    ENDIF(NOT PLUGIN_NAME)

    # here we use the command to generate the library
    IF(DYNAMIC_${UPPER_SHORT_NAME})
        ADD_LIBRARY(${PLUGIN_NAME} MODULE ${SOURCES} ${HEADERS})
    ELSE()
        ADD_LIBRARY(${PLUGIN_NAME}
                    ${USER_DEFINED_DYNAMIC_OR_STATIC}
                    ${SOURCES}
                    ${HEADERS})
    ENDIF()

    SET_TARGET_PROPERTIES(${PLUGIN_NAME} PROPERTIES PROJECT_LABEL "Plugin ${PLUGIN_NAME}")
    SET_TARGET_PROPERTIES(${PLUGIN_NAME} PROPERTIES PREFIX "")
    SET_TARGET_PROPERTIES(${PLUGIN_NAME} PROPERTIES FOLDER "Plugins")

    TARGET_LINK_LIBRARIES(${PLUGIN_NAME} ${LIBRARIES})

    IF(LIBRARIES_OPTIMIZED)
        FOREACH(LIBOPT ${LIBRARIES_OPTIMIZED})
            TARGET_LINK_LIBRARIES(${PLUGIN_NAME} optimized ${LIBOPT})
        ENDFOREACH(LIBOPT)
    ENDIF(LIBRARIES_OPTIMIZED)

    IF(LIBRARIES_DEBUG)
        FOREACH(LIBDEBUG ${LIBRARIES_DEBUG})
            TARGET_LINK_LIBRARIES(${PLUGIN_NAME} debug ${LIBDEBUG})
        ENDFOREACH(LIBDEBUG)
    ENDIF(LIBRARIES_DEBUG)
    SET(DEST_PATH "${LIB_PATH}")
    IF(WIN32)
        SET(DEST_PATH "${BIN_PATH}")
    ENDIF()
    FOREACH(BIN ${DEST_PATH})
        #MESSAGE("installing plugin ${PLUGIN_NAME} in ${BIN}/${install_dest_dir}")
        INSTALL(TARGETS ${PLUGIN_NAME}
            RUNTIME DESTINATION ${BIN}/${install_dest_dir} COMPONENT ${COMP}
            LIBRARY DESTINATION ${BIN}/${install_dest_dir} COMPONENT ${COMP}
        )
    ENDFOREACH()
    IF(UNIX AND NOT APPLE)
        SET_TARGET_PROPERTIES ( ${PLUGIN_NAME} PROPERTIES LINK_FLAGS "-Wl,-E")
    ENDIF(UNIX AND NOT APPLE)

ENDMACRO(SETUP_PLUGIN)

MACRO(SETUP_APPLICATION_PLUGIN TARGET_NAME COMP)

    IF(ANDROID)
        SET(PLUGIN_PREFIX "lib_${SHORT_NAME}_")
    ENDIF()

    IF(NOT PLUGIN_NAME)
            SET(PLUGIN_NAME "${PLUGIN_PREFIX}${TARGET_NAME}")
    ENDIF(NOT PLUGIN_NAME)

    # here we use the command to generate the library
    ADD_LIBRARY(${PLUGIN_NAME}
                ${USER_DEFINED_DYNAMIC_OR_STATIC}
                ${SOURCES}
                ${HEADERS})

    SET_TARGET_PROPERTIES(${PLUGIN_NAME} PROPERTIES PROJECT_LABEL "Plugin ${PLUGIN_NAME}")
    SET_TARGET_PROPERTIES(${PLUGIN_NAME} PROPERTIES PREFIX "")
    SET_TARGET_PROPERTIES(${PLUGIN_NAME} PROPERTIES FOLDER "Plugins")

    TARGET_LINK_LIBRARIES(${PLUGIN_NAME} ${LIBRARIES})

    IF(LIBRARIES_OPTIMIZED)
        FOREACH(LIBOPT ${LIBRARIES_OPTIMIZED})
            TARGET_LINK_LIBRARIES(${PLUGIN_NAME} optimized ${LIBOPT})
        ENDFOREACH(LIBOPT)
    ENDIF(LIBRARIES_OPTIMIZED)

    IF(LIBRARIES_DEBUG)
        FOREACH(LIBDEBUG ${LIBRARIES_DEBUG})
            TARGET_LINK_LIBRARIES(${PLUGIN_NAME} debug ${LIBDEBUG})
        ENDFOREACH(LIBDEBUG)
    ENDIF(LIBRARIES_DEBUG)
    SET(DEST_PATH "${LIB_PATH}")
    IF(WIN32)
        SET(DEST_PATH "${BIN_PATH}")
    ENDIF()
    FOREACH(BIN ${DEST_PATH})
        #MESSAGE("installing plugin ${PLUGIN_NAME} in ${BIN}/${install_dest_dir}")
        INSTALL(TARGETS ${PLUGIN_NAME}
            RUNTIME DESTINATION ${BIN}/${install_dest_dir} COMPONENT ${COMP}
            LIBRARY DESTINATION ${BIN}/${install_dest_dir} COMPONENT ${COMP}
        )
        IF(WIN32)
        INSTALL(TARGETS ${PLUGIN_NAME}
            ARCHIVE DESTINATION ${BIN}/${install_dest_dir}/lib COMPONENT ${COMP}-dev
        )
        ENDIF()
        INSTALL(FILES ${INTERFACE_HEADERS}
            DESTINATION ${BIN}/${install_dest_dir}/include COMPONENT ${COMP}-dev
        )
    ENDFOREACH()
    IF(UNIX AND NOT APPLE)
        SET_TARGET_PROPERTIES ( ${PLUGIN_NAME} PROPERTIES LINK_FLAGS "-Wl,-E")
    ENDIF(UNIX AND NOT APPLE)

ENDMACRO(SETUP_APPLICATION_PLUGIN)

MACRO(SETUP_TEST_PLUGIN TARGET_NAME)

    IF(ANDROID)
        SET(PLUGIN_PREFIX "lib_${SHORT_NAME}_")
    ENDIF()

    IF(NOT PLUGIN_NAME)
            SET(PLUGIN_NAME "${PLUGIN_PREFIX}${TARGET_NAME}")
    ENDIF(NOT PLUGIN_NAME)

    # here we use the command to generate the library
    IF(DYNAMIC_${UPPER_SHORT_NAME})
        ADD_LIBRARY(${PLUGIN_NAME} MODULE ${SOURCES} ${HEADERS})
    ELSE()
    ADD_LIBRARY(${PLUGIN_NAME}
                ${USER_DEFINED_DYNAMIC_OR_STATIC}
                ${SOURCES}
                ${HEADERS})
    ENDIF()

    SET_TARGET_PROPERTIES(${PLUGIN_NAME} PROPERTIES FOLDER "Testing")
    SET_TARGET_PROPERTIES(${PLUGIN_NAME} PROPERTIES PROJECT_LABEL "Plugin ${PLUGIN_NAME}")
    SET_TARGET_PROPERTIES(${PLUGIN_NAME} PROPERTIES PREFIX "")

    TARGET_LINK_LIBRARIES(${PLUGIN_NAME} ${LIBRARIES})

    IF(LIBRARIES_OPTIMIZED)
        FOREACH(LIBOPT ${LIBRARIES_OPTIMIZED})
            TARGET_LINK_LIBRARIES(${PLUGIN_NAME} optimized ${LIBOPT})
        ENDFOREACH(LIBOPT)
    ENDIF(LIBRARIES_OPTIMIZED)

    IF(LIBRARIES_DEBUG)
        FOREACH(LIBDEBUG ${LIBRARIES_DEBUG})
            TARGET_LINK_LIBRARIES(${PLUGIN_NAME} debug ${LIBDEBUG})
        ENDFOREACH(LIBDEBUG)
    ENDIF(LIBRARIES_DEBUG)

    IF(UNIX AND NOT APPLE)
        SET_TARGET_PROPERTIES ( ${PLUGIN_NAME} PROPERTIES LINK_FLAGS "-Wl,-E")
    ENDIF(UNIX AND NOT APPLE)

ENDMACRO(SETUP_TEST_PLUGIN)


MACRO(SETUP_LAUNCHER LAUNCHER_NAME COMP)

    ADD_EXECUTABLE(${LAUNCHER_NAME} ${SOURCES} ${HEADERS})

    TARGET_LINK_LIBRARIES(${LAUNCHER_NAME} ${LIBRARIES})
    IF(LIBRARIES_OPTIMIZED)
        FOREACH(LIBOPT ${LIBRARIES_OPTIMIZED})
            TARGET_LINK_LIBRARIES(${LAUNCHER_NAME} optimized ${LIBOPT})
        ENDFOREACH(LIBOPT)
    ENDIF(LIBRARIES_OPTIMIZED)

    IF(LIBRARIES_DEBUG)
        FOREACH(LIBDEBUG ${LIBRARIES_DEBUG})
            TARGET_LINK_LIBRARIES(${LAUNCHER_NAME} debug ${LIBDEBUG})
        ENDFOREACH(LIBDEBUG)
    ENDIF(LIBRARIES_DEBUG)

    SET_TARGET_PROPERTIES(${LAUNCHER_NAME} PROPERTIES PROJECT_LABEL "Launcher ${LAUNCHER_NAME}")
    SET_TARGET_PROPERTIES(${LAUNCHER_NAME} PROPERTIES DEBUG_OUTPUT_NAME "${LAUNCHER_NAME}${CMAKE_DEBUG_POSTFIX}")
    SET_TARGET_PROPERTIES(${LAUNCHER_NAME} PROPERTIES RELEASE_OUTPUT_NAME "${LAUNCHER_NAME}${CMAKE_RELEASE_POSTFIX}")
    SET_TARGET_PROPERTIES(${LAUNCHER_NAME} PROPERTIES RELWITHDEBINFO_OUTPUT_NAME "${LAUNCHER_NAME}${CMAKE_RELWITHDEBINFO_POSTFIX}")
    SET_TARGET_PROPERTIES(${LAUNCHER_NAME} PROPERTIES MINSIZEREL_OUTPUT_NAME "${LAUNCHER_NAME}${CMAKE_MINSIZEREL_POSTFIX}")
    SET_TARGET_PROPERTIES(${LAUNCHER_NAME} PROPERTIES FOLDER "Applications")


    SETUP_RESOURCES(${LAUNCHER_NAME} ${COMP})

    FOREACH(BIN ${BIN_PATH})
        INSTALL(TARGETS ${LAUNCHER_NAME}
            RUNTIME DESTINATION ${BIN} COMPONENT ${COMP}
        )
    ENDFOREACH()

ENDMACRO(SETUP_LAUNCHER)

MACRO(FIX_BUNDLE_SDK TARGET_NAME BINARY_NAME BINARY_NAME_DEBUG INSTALL_PATH BIN_PATH LIB_PATH COMP_LIST)
    SET(BINARY)
    SET(BINARY_DEBUG)
    FOREACH(BIN ${BIN_PATH})
        IF(IS_ABSOLUTE "${BIN}")
            SET(BINARY ${BINARY} "${BIN}/${BINARY_NAME}")
            SET(BINARY_DEBUG ${BINARY_DEBUG} "${BIN}/${BINARY_NAME_DEBUG}")
        ELSE()
            SET(BINARY ${BINARY} "${INSTALL_PATH}/${BIN}/${BINARY_NAME}")
            SET(BINARY_DEBUG ${BINARY_DEBUG} "${INSTALL_PATH}/${BIN}/${BINARY_NAME_DEBUG}")
        ENDIF()
    ENDFOREACH()

    IF(ADDITIONAL_LIBRARIES)
        FOREACH(COMP ${COMP_LIST})
            FOREACH(LIB ${LIB_PATH})
                INSTALL(FILES ${ADDITIONAL_LIBRARIES}
                   DESTINATION ${LIB} COMPONENT ${COMP}
                   PERMISSIONS OWNER_WRITE OWNER_READ GROUP_READ WORLD_READ
                   CONFIGURATIONS Release RelWithDebInfo
                )
            ENDFOREACH()
        ENDFOREACH()
    ENDIF()
    IF(ADDITIONAL_LIBRARIES_DEBUG)
        FOREACH(COMP ${COMP_LIST})
            FOREACH(LIB ${LIB_PATH})
                INSTALL(FILES ${ADDITIONAL_LIBRARIES_DEBUG}
                   DESTINATION ${LIB} COMPONENT ${COMP}
                   PERMISSIONS OWNER_WRITE OWNER_READ GROUP_READ WORLD_READ
                   CONFIGURATIONS Debug
                )
            ENDFOREACH()
        ENDFOREACH()
    ENDIF()

    IF(ADDITIONAL_TARGETS)
        FOREACH(TARGET ${ADDITIONAL_TARGETS})
            GET_TARGET_PROPERTY(TARGET_LOC ${TARGET} LOCATION)
            IF(TARGET_LOC)
                IF(WIN32)
                    SET(ADDITIONAL_LIBRARIES ${ADDITIONAL_LIBRARIES} "${CMAKE_BINARY_DIR}/bin/$(Configuration)/${TARGET}.dll")
                ELSE()
                    SET(ADDITIONAL_LIBRARIES ${ADDITIONAL_LIBRARIES} "${TARGET_LOC}")
                ENDIF()
            ENDIF(TARGET_LOC)
        ENDFOREACH(TARGET)
    ENDIF()
    IF(ADDITIONAL_TARGETS_DEBUG)
        FOREACH(TARGET ${ADDITIONAL_TARGETS_DEBUG})
            GET_TARGET_PROPERTY(TARGET_LOC ${TARGET} LOCATION)
            IF(TARGET_LOC)
                IF(WIN32)
                    SET(ADDITIONAL_LIBRARIES_DEBUG ${ADDITIONAL_LIBRARIES_DEBUG} "${CMAKE_BINARY_DIR}/bin/$(Configuration)/${TARGET}d.dll")
                ELSE()
                    SET(ADDITIONAL_LIBRARIES_DEBUG ${ADDITIONAL_LIBRARIES_DEBUG} "${TARGET_LOC}")
                ENDIF()
            ENDIF(TARGET_LOC)
        ENDFOREACH(TARGET)
    ENDIF()

    SET(BUILD_TYPE "${CMAKE_BUILD_TYPE}")
    IF(WIN32)
        SET(BUILD_TYPE "$(Configuration)")
    ENDIF()
    ADD_CUSTOM_TARGET(install_${TARGET_NAME})
    IF(APPLE)
        ADD_CUSTOM_COMMAND(TARGET install_${TARGET_NAME}
            COMMAND ${CMAKE_COMMAND} -DBUILD_TYPE="${BUILD_TYPE}" -DCOMP_LIST="${COMP_LIST}" -DLIB_PATH="${LIB_PATH}"
                    -DADDITIONAL_LIBRARIES="${ADDITIONAL_LIBRARIES}" -DADDITIONAL_LIBRARIES_DEBUG="${ADDITIONAL_LIBRARIES_DEBUG}"
                    -P ${CMAKE_SOURCE_DIR}/CMakeModules/install.cmake
            WORKING_DIRECTORY ${CMAKE_BINARY_DIR})
    ELSE()
        ADD_CUSTOM_COMMAND(TARGET install_${TARGET_NAME}
            COMMAND ${CMAKE_COMMAND} -DBUILD_TYPE="${BUILD_TYPE}" -DCOMP_LIST="${COMP_LIST}" -DLIB_PATH="${LIB_PATH}"
                    -DADDITIONAL_LIBRARIES="${ADDITIONAL_LIBRARIES}" -DADDITIONAL_LIBRARIES_DEBUG="${ADDITIONAL_LIBRARIES_DEBUG}"
                    -P ${CMAKE_SOURCE_DIR}/CMakeModules/install.cmake
            COMMAND ${CMAKE_COMMAND} -DBUILD_TYPE="${BUILD_TYPE}" -DBINARY="${BINARY}" -DBINARY_DEBUG="${BINARY_DEBUG}"
                    -DADDITIONAL_LIBRARIES="${ADDITIONAL_LIBRARIES}" -DADDITIONAL_LIBRARIES_DEBUG="${ADDITIONAL_LIBRARIES_DEBUG}"
                    -DBUNDLE_DEPENDENCY_DIRS="${BUNDLE_DEPENDENCY_DIRS}" -P ${CMAKE_SOURCE_DIR}/CMakeModules/bundle.cmake
            WORKING_DIRECTORY ${CMAKE_BINARY_DIR})
    ENDIF()

    SET_TARGET_PROPERTIES(install_${TARGET_NAME} PROPERTIES FOLDER "Packaging")

ENDMACRO(FIX_BUNDLE_SDK)

MACRO(INSTALL_APP_SDK TARGET_NAME APP_NAME COMP_LIST)
    SET(INSTALL_PATH "\${CMAKE_INSTALL_PREFIX}")
    SET(BINARY_NAME       "${APP_NAME}")
    SET(BINARY_NAME_DEBUG "${APP_NAME}d")
    IF(APPLE)
        SET(BIN_PATH "${APP_NAME}.app/Contents/MacOS")
        SET(BINARY_NAME "${APP_NAME}.app")
        SET(BINARY_NAME_DEBUG "${APP_NAME}d.app")
    ELSE(APPLE)
        IF(WIN32)
            SET(BINARY_NAME "${APP_NAME}.exe")
            SET(BINARY_NAME_DEBUG "${APP_NAME}d.exe")
        ENDIF(WIN32)
    ENDIF(APPLE)
	
    IF(APPLE)
        SET(LIB_PATH "${APP_NAME}.app/Contents/MacOS")
    ENDIF(APPLE)
    IF(WIN32)
        SET(LIB_PATH "${BIN_PATH}")
    ENDIF(WIN32)

    FIX_BUNDLE_SDK("${TARGET_NAME}" ${BINARY_NAME} ${BINARY_NAME_DEBUG} "${INSTALL_PATH}" "${BIN_PATH}" "${LIB_PATH}" "${COMP_LIST}")
ENDMACRO()

MACRO(INSTALL_LAUNCHER_SDK TARGET_NAME APP_NAME COMP_LIST)
    SET(INSTALL_PATH "\${CMAKE_INSTALL_PREFIX}")
    SET(BINARY_NAME "${APP_NAME}")
    SET(BINARY_NAME_DEBUG "${APP_NAME}d")
    IF(WIN32)
        SET(BINARY_NAME "${APP_NAME}.exe")
        SET(BINARY_NAME_DEBUG "${APP_NAME}d.exe")
    ENDIF(WIN32)

    IF(WIN32)
        SET(LIB_PATH "${BIN_PATH}")
    ENDIF(WIN32)
    FIX_BUNDLE_SDK("${TARGET_NAME}" ${BINARY_NAME} ${BINARY_NAME_DEBUG} "${INSTALL_PATH}" "${BIN_PATH}" "${LIB_PATH}" "${COMP_LIST}")
ENDMACRO()

MACRO(SETUP_APPLICATION LAUNCHER_NAME COMP)
    IF(APPLE)
        # Short Version is the "marketing version". It is the version
        # the user sees in an information panel.
        SET(MACOSX_BUNDLE_SHORT_VERSION_STRING "${MAJOR_VERSION}.${MINOR_VERSION}.${PATCH_VERSION}")
        # Bundle version is the version the OS looks at.
        SET(MACOSX_BUNDLE_BUNDLE_VERSION "${MAJOR_VERSION}.${MINOR_VERSION}.${PATCH_VERSION}")
        SET(MACOSX_BUNDLE_GUI_IDENTIFIER "${LAUNCHER_NAME}" )
        if(NOT APPLICATION_NAME)
            set(APPLICATION_NAME ${LAUNCHER_NAME})
        endif()
        SET(MACOSX_BUNDLE_BUNDLE_NAME "${APPLICATION_NAME}" )
        IF(ICON)
            get_filename_component(ICON_WP ${ICON} NAME)
            SET(MACOSX_BUNDLE_ICON_FILE ${ICON_WP})
        ENDIF(ICON)
        SET(MACOSX_BUNDLE_COPYRIGHT "Mirage Technologies S.L.")
        # SET(MACOSX_BUNDLE_INFO_STRING "Info string, localized?")
        SET(PLATFORM_SPECIFIC_CONTROL MACOSX_BUNDLE)
    ENDIF(APPLE)

    IF(WIN32)
        SET(PLATFORM_SPECIFIC_CONTROL WIN32)
    ENDIF(WIN32)

    ADD_EXECUTABLE(${LAUNCHER_NAME} ${PLATFORM_SPECIFIC_CONTROL} ${SOURCES} ${HEADERS})

    TARGET_LINK_LIBRARIES(${LAUNCHER_NAME} ${LIBRARIES})
    IF(LIBRARIES_OPTIMIZED)
        FOREACH(LIBOPT ${LIBRARIES_OPTIMIZED})
            TARGET_LINK_LIBRARIES(${LAUNCHER_NAME} optimized ${LIBOPT})
        ENDFOREACH(LIBOPT)
    ENDIF(LIBRARIES_OPTIMIZED)

    IF(LIBRARIES_DEBUG)
        FOREACH(LIBDEBUG ${LIBRARIES_DEBUG})
            TARGET_LINK_LIBRARIES(${LAUNCHER_NAME} debug ${LIBDEBUG})
        ENDFOREACH(LIBDEBUG)
    ENDIF(LIBRARIES_DEBUG)

    SET_TARGET_PROPERTIES(${LAUNCHER_NAME} PROPERTIES PROJECT_LABEL "Application ${LAUNCHER_NAME}")
    SET_TARGET_PROPERTIES(${LAUNCHER_NAME} PROPERTIES DEBUG_OUTPUT_NAME "${LAUNCHER_NAME}${CMAKE_DEBUG_POSTFIX}")
    SET_TARGET_PROPERTIES(${LAUNCHER_NAME} PROPERTIES RELEASE_OUTPUT_NAME "${LAUNCHER_NAME}${CMAKE_RELEASE_POSTFIX}")
    SET_TARGET_PROPERTIES(${LAUNCHER_NAME} PROPERTIES RELWITHDEBINFO_OUTPUT_NAME "${LAUNCHER_NAME}${CMAKE_RELWITHDEBINFO_POSTFIX}")
    SET_TARGET_PROPERTIES(${LAUNCHER_NAME} PROPERTIES MINSIZEREL_OUTPUT_NAME "${LAUNCHER_NAME}${CMAKE_MINSIZEREL_POSTFIX}")
    SET_TARGET_PROPERTIES(${LAUNCHER_NAME} PROPERTIES FOLDER "Applications")

    IF(APPLE)
        INSTALL(TARGETS ${LAUNCHER_NAME}
	    BUNDLE DESTINATION . COMPONENT ${COMP}
        )
    ELSE()
        FOREACH(BIN ${BIN_PATH})
	     INSTALL(TARGETS ${LAUNCHER_NAME}
	             RUNTIME DESTINATION ${BIN} COMPONENT ${COMP}
             )
        ENDFOREACH()
    ENDIF()
    
    SET(IS_APPLICATION 1)

    SETUP_RESOURCES(${LAUNCHER_NAME} ${COMP})

    INSTALL_APP_SDK(${LAUNCHER_NAME} ${LAUNCHER_NAME} "${COMP}")

ENDMACRO(SETUP_APPLICATION)

MACRO(SETUP_TESTS TARGET TEST_FILES)
    SET(TESTS_TO_PASS)
    FOREACH(file ${TEST_FILES})
        get_filename_component(TEST_NAME ${file} NAME_WE)
        ADD_EXECUTABLE(${TEST_NAME} ${file})
        SET_TARGET_PROPERTIES(${TEST_NAME} PROPERTIES FOLDER "Testing")
        TARGET_LINK_LIBRARIES(${TEST_NAME} unit-- ${LIBRARIES})
        ADD_TEST(${TEST_NAME} ${OUTPUT_BINDIR}/${TEST_NAME})
        SET(TESTS_TO_PASS ${TESTS_TO_PASS} ${TEST_NAME})
    ENDFOREACH()
    add_dependencies(${TARGET} ${TESTS_TO_PASS})
ENDMACRO(SETUP_TESTS)

MACRO(SETUP_RESOURCES TARGET_NAME COMP)
    if(NOT install_res_dir)
        set(install_res_dir share/${SHORT_NAME}/${TARGET_NAME})
        if(WIN32)
            set(install_res_dir ${BIN_PATH})
        endif(WIN32)
    endif()
    if(NOT install_script_dir)
        set(install_script_dir ${BIN_PATH})
    endif()
    IF(APPLE)
        IF(IS_APPLICATION)
            SET(install_res_dir ${TARGET_NAME}.app/Contents/Resources)
            SET(install_script_dir ${TARGET_NAME}.app/Contents/Resources)
        ENDIF(IS_APPLICATION)
    ENDIF(APPLE)

    IF(RESOURCE_FILES)
        foreach(dir ${install_res_dir})
            install(FILES ${RESOURCE_FILES}
                    DESTINATION ${dir} COMPONENT ${COMP}
            )
        endforeach()
    ENDIF(RESOURCE_FILES)

    IF(RESOURCE_DIRS)
        foreach(dir ${install_res_dir})
            install(DIRECTORY ${RESOURCE_DIRS}
                    DESTINATION ${dir} COMPONENT ${COMP}
                    PATTERN ".svn" EXCLUDE
            )
        endforeach()
    ENDIF(RESOURCE_DIRS)

    IF(SCRIPT_FILES)
        foreach(dir ${install_script_dir})
            install(PROGRAMS ${SCRIPT_FILES}
                    DESTINATION ${dir} COMPONENT ${COMP}
                    PERMISSIONS OWNER_WRITE OWNER_READ OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE
            )
        endforeach()
    ENDIF(SCRIPT_FILES)

    IF(WRAPPER_FILES)
        if(WIN32 OR APPLE)
            foreach(dir ${install_res_dir})
                install(FILES ${WRAPPER_FILES}
                        DESTINATION ${dir} COMPONENT ${COMP}
                )
            endforeach()
        endif(WIN32 OR APPLE)
    ENDIF(WRAPPER_FILES)

    IF(ICON)
        IF(APPLE)
            IF(IS_APPLICATION)
                INSTALL(FILES ${ICON}
                        DESTINATION ${TARGET_NAME}.app/Contents/Resources
                        COMPONENT ${COMP})
            ENDIF(IS_APPLICATION)
        ELSE(APPLE)
            IF(UNIX AND IS_APPLICATION)
                INSTALL(FILES ${ICON}
                        DESTINATION ${install_res_dir}
                        COMPONENT ${COMP})
            ENDIF(UNIX AND IS_APPLICATION)
        ENDIF(APPLE)
    ENDIF(ICON)

    IF(DESKTOP_FILES)
        IF(UNIX AND NOT APPLE)
            INSTALL(FILES ${DESKTOP_FILES}
                DESTINATION share/applications COMPONENT ${COMP}
            )
        ENDIF(UNIX AND NOT APPLE)
    ENDIF(DESKTOP_FILES)

    IF(MENU_FILES)
        IF(UNIX AND NOT APPLE)
            INSTALL(FILES ${MENU_FILES}
                DESTINATION share/menu COMPONENT ${COMP}
            )
        ENDIF(UNIX AND NOT APPLE)
    ENDIF(MENU_FILES)
ENDMACRO(SETUP_RESOURCES)

MACRO(BUILD_JAVA_SWIG LIB_NAME)
    SWIG_ADD_MODULE(${LIB_NAME} java
        ${SOURCES}
    )
    SWIG_LINK_LIBRARIES(${LIB_NAME}
        ${LIBRARIES}
    )

    IF(UNIX)
        SET_TARGET_PROPERTIES(${LIB_NAME}
            PROPERTIES
            PREFIX lib)
        IF(APPLE)
            SET_TARGET_PROPERTIES(${LIB_NAME}
            PROPERTIES
            SUFFIX .jnilib)
        ENDIF(APPLE)
    ENDIF(UNIX)
    SET(install_dest_dir share/${SHORT_NAME}/java/${LIB_NAME})
    IF(WIN32)
        INSTALL(TARGETS ${LIB_NAME}
            RUNTIME DESTINATION ${install_dest_dir} COMPONENT ${COMP}
            LIBRARY DESTINATION ${install_dest_dir} COMPONENT ${COMP}
        )
    ELSE(WIN32)
        INSTALL(TARGETS ${LIB_NAME}
            LIBRARY DESTINATION ${install_dest_dir} COMPONENT ${COMP}
        )
    ENDIF(WIN32)

    INSTALL(DIRECTORY ${CMAKE_BINARY_DIR}/src/wrapper/java/${BIND_PROJECT}/
            DESTINATION ${install_dest_dir}/src/main/java/${INSTALL_DESTINATION} COMPONENT runtime
            FILES_MATCHING PATTERN "*.java"
            PATTERN "CMakeFiles" EXCLUDE
    )

    INSTALL(FILES ${CMAKE_SOURCE_DIR}/scripts/pom.xml
            DESTINATION ${install_dest_dir} COMPONENT ${COMP}
    )
ENDMACRO(BUILD_JAVA_SWIG)

MACRO(BUILD_PYTHON_SWIG LIB_NAME)
    SWIG_ADD_MODULE(${LIB_NAME} python
        ${SOURCES}
    )
    SWIG_LINK_LIBRARIES(${LIB_NAME}
        ${LIBRARIES}
    )

    SET(install_dest_dir lib/python/site-packages/${LIB_NAME})
    IF(WIN32)
        SET(install_dest_dir bin)
    ENDIF(WIN32)

    INSTALL(TARGETS _${LIB_NAME}
        RUNTIME DESTINATION ${install_dest_dir} COMPONENT ${COMP}
        LIBRARY DESTINATION ${install_dest_dir} COMPONENT ${COMP}
    )

    INSTALL(DIRECTORY ${CMAKE_BINARY_DIR}/src/wrapper/python/
            DESTINATION ${install_dest_dir} COMPONENT ${COMP}
            FILES_MATCHING PATTERN "*.py"
            PATTERN "CMakeFiles" EXCLUDE
            PATTERN ".dir" EXCLUDE
    )
ENDMACRO(BUILD_PYTHON_SWIG)

MACRO(BUILD_LUA_SWIG LIB_NAME)
    SWIG_ADD_MODULE(${LIB_NAME} lua
        ${SOURCES}
    )

    SWIG_LINK_LIBRARIES(${LIB_NAME}
        ${LIBRARIES}
    )
    SET(install_dest_dir share/mirage/lua/${LIB_NAME})
    IF(WIN32)
        INSTALL(TARGETS ${LIB_NAME}
            RUNTIME DESTINATION ${install_dest_dir} COMPONENT ${COMP}
            LIBRARY DESTINATION ${install_dest_dir} COMPONENT ${COMP}
        )
    ELSE(WIN32)
        INSTALL(TARGETS ${LIB_NAME}
            LIBRARY DESTINATION ${install_dest_dir} COMPONENT ${COMP}
        )
    ENDIF(WIN32)

    INSTALL(DIRECTORY ${CMAKE_SOURCE_DIR}/src/wrapper/lua/
            DESTINATION ${install_dest_dir} COMPONENT ${COMP}
            FILES_MATCHING PATTERN "*.lua"
            PATTERN "CMakeFiles" EXCLUDE
    )
ENDMACRO(BUILD_LUA_SWIG)


MACRO(PDFLATEX FILE)

#file(GLOB_RECURSE DOC_FILES *)
foreach(f ${DOC_FILES})
    IF(NOT IS_DIRECTORY ${f} AND
       NOT "${f}" MATCHES "[.]svn/|[.]DS_Store|[.]swp|[.]txt")
        get_filename_component(basef ${f} NAME)
        set(outputf ${CMAKE_CURRENT_BINARY_DIR}/${basef})
        add_custom_command(
            OUTPUT ${outputf}
            DEPENDS ${f}
            COMMAND ${CMAKE_COMMAND}
            ARGS -E copy ${f} ${outputf}
            WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})
        list(APPEND refman_copied_srcs ${outputf})
    ENDIF()
endforeach()

SET(pdflatex_args -interaction=batchmode
"\"\\input{${FILE}.tex}\"")

add_custom_command(
  OUTPUT    ${CMAKE_CURRENT_BINARY_DIR}/${FILE}.aux
  DEPENDS   ${refman_copied_srcs}
  COMMAND   ${PDFLATEX_COMPILER}
  ARGS      ${pdflatex_args}
  COMMENT   "Latex (first pass)"
  WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
  )

#add_custom_command(
#  OUTPUT    ${CMAKE_CURRENT_BINARY_DIR}/${FILE}.bbl
#  DEPENDS   ${CMAKE_CURRENT_BINARY_DIR}/${FILE}.aux
#  COMMAND   ${BIBTEX_COMPILER}
#  ARGS      ${CMAKE_CURRENT_BINARY_DIR}/${FILE}
#  COMMENT   "Bibtex"
#  WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
#  )

add_custom_command(
  OUTPUT    ${CMAKE_CURRENT_BINARY_DIR}/${FILE}.pdf
  DEPENDS   ${CMAKE_CURRENT_BINARY_DIR}/${FILE}.aux
  COMMAND   ${PDFLATEX_COMPILER}
  ARGS      ${pdflatex_args}
  COMMENT   "Latex (second pass)"
  WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
  )


add_custom_command(
  OUTPUT    ${CMAKE_CURRENT_BINARY_DIR}/${FILE}.log
  DEPENDS   #${CMAKE_CURRENT_BINARY_DIR}/${FILE}.bbl
            ${CMAKE_CURRENT_BINARY_DIR}/${FILE}.pdf
  COMMAND   ${PDFLATEX_COMPILER}
  ARGS      ${pdflatex_args}
  COMMENT   "Latex (third pass)"
  WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
  )

add_custom_target(${FILE}_Documentation ALL echo
   DEPENDS   ${CMAKE_CURRENT_BINARY_DIR}/${FILE}.log
   )
set(dest_dir share/${SHORT_NAME}/doc)
IF(APPLE)
    set(dest_dir Documentation)
ENDIF(APPLE)
INSTALL(FILES "${CMAKE_CURRENT_BINARY_DIR}/${FILE}.pdf"
        DESTINATION "${dest_dir}" COMPONENT ${COMP})

ENDMACRO()

## Params: nom, [opt]
macro(find_m_project nom)
    if(ANDROID)
        find_host_package(${ARGV})
    else()
        find_package(${ARGV})
    endif()
endmacro()
