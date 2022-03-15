# CMakeLists.txt

# Copyright (c) 2018-2020 Cosmin Truta
# Copyright (c) 2007,2009-2018 Glenn Randers-Pehrson
# Written by Christian Ehrlicher, 2007
# Revised by Roger Lowman, 2009-2010
# Revised by Clifford Yapp, 2011-2012,2017
# Revised by Roger Leigh, 2016
# Revised by Andreas Franek, 2016
# Revised by Sam Serrels, 2017
# Revised by Vadim Barkov, 2017
# Revised by Vicky Pfau, 2018
# Revised by Cameron Cawley, 2018
# Revised by Kyle Bentley, 2018
# Revised by David Callu, 2020
# Revised by Steve Robinson, 2020
# Revised by Simon Hausmann, 2020
# Revised by Alex Gaynor, 2020

# This code is released under the libpng license.
# For conditions of distribution and use, see the disclaimer
# and license in png.h

CMAKE_MINIMUM_REQUIRED(VERSION 3.1)
CMAKE_POLICY(VERSION 3.1)

PROJECT(libpng C ASM)
ENABLE_TESTING()

SET(PNGLIB_MAJOR 1)
SET(PNGLIB_MINOR 6)
SET(PNGLIB_RELEASE 38)
SET(PNGLIB_NAME libpng${PNGLIB_MAJOR}${PNGLIB_MINOR})
SET(PNGLIB_VERSION ${PNGLIB_MAJOR}.${PNGLIB_MINOR}.${PNGLIB_RELEASE})

INCLUDE(GNUInstallDirs)
INCLUDE(CMakeModules/CPM.cmake)


# In this case, the name of the NAME variable is important.
# because it will be used to determine the path where the
# source code of the project is located.
CPMADDPACKAGE(
        NAME ZLIB
        GITHUB_REPOSITORY Andres6936/ZLib
        VERSION 1.2.12
)


IF (UNIX AND NOT APPLE AND NOT BEOS AND NOT HAIKU AND NOT EMSCRIPTEN)
    FIND_LIBRARY(M_LIBRARY m)
ELSE ()
    # libm is not needed and/or not available.
    SET(M_LIBRARY "")
ENDIF ()

# Public CMake configuration variables.
OPTION(PNG_SHARED "Build shared lib" ON)
OPTION(PNG_STATIC "Build static lib" ON)
OPTION(PNG_EXECUTABLES "Build libpng executables" ON)
OPTION(PNG_TESTS "Build libpng tests" ON)

# Many more configuration options could be added here.
OPTION(PNG_FRAMEWORK "Build OS X framework" OFF)
OPTION(PNG_DEBUG "Build with debug output" OFF)
OPTION(PNG_HARDWARE_OPTIMIZATIONS "Enable hardware optimizations" ON)

SET(PNG_PREFIX "" CACHE STRING "Prefix to add to the API function names")
SET(DFA_XTRA "" CACHE FILEPATH "File containing extra configuration settings")

IF (PNG_HARDWARE_OPTIMIZATIONS)

    # Set definitions and sources for ARM.
    IF (CMAKE_SYSTEM_PROCESSOR MATCHES "^arm" OR
            CMAKE_SYSTEM_PROCESSOR MATCHES "^aarch64")
        SET(PNG_ARM_NEON_POSSIBLE_VALUES check on off)
        SET(PNG_ARM_NEON "check"
                CACHE STRING "Enable ARM NEON optimizations: check|on|off; check is default")
        SET_PROPERTY(CACHE PNG_ARM_NEON
                PROPERTY STRINGS ${PNG_ARM_NEON_POSSIBLE_VALUES})
        LIST(FIND PNG_ARM_NEON_POSSIBLE_VALUES ${PNG_ARM_NEON} index)
        IF (index EQUAL -1)
            MESSAGE(FATAL_ERROR "PNG_ARM_NEON must be one of [${PNG_ARM_NEON_POSSIBLE_VALUES}]")
        ELSEIF (NOT ${PNG_ARM_NEON} STREQUAL "off")
            SET(libpng_arm_sources
                    arm/arm_init.c
                    arm/filter_neon.S
                    arm/filter_neon_intrinsics.c
                    arm/palette_neon_intrinsics.c)
            IF (${PNG_ARM_NEON} STREQUAL "on")
                ADD_DEFINITIONS(-DPNG_ARM_NEON_OPT=2)
            ELSEIF (${PNG_ARM_NEON} STREQUAL "check")
                ADD_DEFINITIONS(-DPNG_ARM_NEON_CHECK_SUPPORTED)
            ENDIF ()
        ELSE ()
            ADD_DEFINITIONS(-DPNG_ARM_NEON_OPT=0)
        ENDIF ()
    ENDIF ()

    # Set definitions and sources for PowerPC.
    IF (CMAKE_SYSTEM_PROCESSOR MATCHES "^powerpc*" OR
            CMAKE_SYSTEM_PROCESSOR MATCHES "^ppc64*")
        SET(PNG_POWERPC_VSX_POSSIBLE_VALUES on off)
        SET(PNG_POWERPC_VSX "on"
                CACHE STRING "Enable POWERPC VSX optimizations: on|off; on is default")
        SET_PROPERTY(CACHE PNG_POWERPC_VSX
                PROPERTY STRINGS ${PNG_POWERPC_VSX_POSSIBLE_VALUES})
        LIST(FIND PNG_POWERPC_VSX_POSSIBLE_VALUES ${PNG_POWERPC_VSX} index)
        IF (index EQUAL -1)
            MESSAGE(FATAL_ERROR "PNG_POWERPC_VSX must be one of [${PNG_POWERPC_VSX_POSSIBLE_VALUES}]")
        ELSEIF (NOT ${PNG_POWERPC_VSX} STREQUAL "off")
            SET(libpng_powerpc_sources
                    powerpc/powerpc_init.c
                    powerpc/filter_vsx_intrinsics.c)
            IF (${PNG_POWERPC_VSX} STREQUAL "on")
                ADD_DEFINITIONS(-DPNG_POWERPC_VSX_OPT=2)
            ENDIF ()
        ELSE ()
            ADD_DEFINITIONS(-DPNG_POWERPC_VSX_OPT=0)
        ENDIF ()
    ENDIF ()

    # Set definitions and sources for Intel.
    IF (CMAKE_SYSTEM_PROCESSOR MATCHES "^i?86" OR
            CMAKE_SYSTEM_PROCESSOR MATCHES "^x86_64*")
        SET(PNG_INTEL_SSE_POSSIBLE_VALUES on off)
        SET(PNG_INTEL_SSE "on"
                CACHE STRING "Enable INTEL_SSE optimizations: on|off; on is default")
        SET_PROPERTY(CACHE PNG_INTEL_SSE
                PROPERTY STRINGS ${PNG_INTEL_SSE_POSSIBLE_VALUES})
        LIST(FIND PNG_INTEL_SSE_POSSIBLE_VALUES ${PNG_INTEL_SSE} index)
        IF (index EQUAL -1)
            MESSAGE(FATAL_ERROR "PNG_INTEL_SSE must be one of [${PNG_INTEL_SSE_POSSIBLE_VALUES}]")
        ELSEIF (NOT ${PNG_INTEL_SSE} STREQUAL "off")
            SET(libpng_intel_sources
                    intel/intel_init.c
                    intel/filter_sse2_intrinsics.c)
            IF (${PNG_INTEL_SSE} STREQUAL "on")
                ADD_DEFINITIONS(-DPNG_INTEL_SSE_OPT=1)
            ENDIF ()
        ELSE ()
            ADD_DEFINITIONS(-DPNG_INTEL_SSE_OPT=0)
        ENDIF ()
    ENDIF ()

    # Set definitions and sources for MIPS.
    IF (CMAKE_SYSTEM_PROCESSOR MATCHES "mipsel*" OR
            CMAKE_SYSTEM_PROCESSOR MATCHES "mips64el*")
        SET(PNG_MIPS_MSA_POSSIBLE_VALUES on off)
        SET(PNG_MIPS_MSA "on"
                CACHE STRING "Enable MIPS_MSA optimizations: on|off; on is default")
        SET_PROPERTY(CACHE PNG_MIPS_MSA
                PROPERTY STRINGS ${PNG_MIPS_MSA_POSSIBLE_VALUES})
        LIST(FIND PNG_MIPS_MSA_POSSIBLE_VALUES ${PNG_MIPS_MSA} index)
        IF (index EQUAL -1)
            MESSAGE(FATAL_ERROR "PNG_MIPS_MSA must be one of [${PNG_MIPS_MSA_POSSIBLE_VALUES}]")
        ELSEIF (NOT ${PNG_MIPS_MSA} STREQUAL "off")
            SET(libpng_mips_sources
                    mips/mips_init.c
                    mips/filter_msa_intrinsics.c)
            IF (${PNG_MIPS_MSA} STREQUAL "on")
                ADD_DEFINITIONS(-DPNG_MIPS_MSA_OPT=2)
            ENDIF ()
        ELSE ()
            ADD_DEFINITIONS(-DPNG_MIPS_MSA_OPT=0)
        ENDIF ()
    ENDIF ()

ELSE (PNG_HARDWARE_OPTIMIZATIONS)

    # Set definitions and sources for ARM.
    IF (CMAKE_SYSTEM_PROCESSOR MATCHES "^arm" OR
            CMAKE_SYSTEM_PROCESSOR MATCHES "^aarch64")
        ADD_DEFINITIONS(-DPNG_ARM_NEON_OPT=0)
    ENDIF ()

    # Set definitions and sources for PowerPC.
    IF (CMAKE_SYSTEM_PROCESSOR MATCHES "^powerpc*" OR
            CMAKE_SYSTEM_PROCESSOR MATCHES "^ppc64*")
        ADD_DEFINITIONS(-DPNG_POWERPC_VSX_OPT=0)
    ENDIF ()

    # Set definitions and sources for Intel.
    IF (CMAKE_SYSTEM_PROCESSOR MATCHES "^i?86" OR
            CMAKE_SYSTEM_PROCESSOR MATCHES "^x86_64*")
        ADD_DEFINITIONS(-DPNG_INTEL_SSE_OPT=0)
    ENDIF ()

    # Set definitions and sources for MIPS.
    IF (CMAKE_SYSTEM_PROCESSOR MATCHES "mipsel*" OR
            CMAKE_SYSTEM_PROCESSOR MATCHES "mips64el*")
        ADD_DEFINITIONS(-DPNG_MIPS_MSA_OPT=0)
    ENDIF ()

ENDIF (PNG_HARDWARE_OPTIMIZATIONS)

# Set PNG_LIB_NAME.
SET(PNG_LIB_NAME png${PNGLIB_MAJOR}${PNGLIB_MINOR})

# Distinguish between debug and release builds.
SET(CMAKE_DEBUG_POSTFIX "d")

INCLUDE(CheckCSourceCompiles)
OPTION(ld-version-script "Enable linker version script" ON)
IF (ld-version-script AND NOT APPLE)
    # Check if LD supports linker scripts.
    FILE(WRITE "${CMAKE_CURRENT_BINARY_DIR}/conftest.map" "VERS_1 {
        global: sym;
        local: *;
};

VERS_2 {
        global: sym2;
                main;
} VERS_1;
")
    SET(CMAKE_REQUIRED_FLAGS_SAVE ${CMAKE_REQUIRED_FLAGS})
    SET(CMAKE_REQUIRED_FLAGS ${CMAKE_REQUIRED_FLAGS} "-Wl,--version-script='${CMAKE_CURRENT_BINARY_DIR}/conftest.map'")
    CHECK_C_SOURCE_COMPILES("void sym(void) {}
void sym2(void) {}
int main(void) {return 0;}
" HAVE_LD_VERSION_SCRIPT)
    IF (NOT HAVE_LD_VERSION_SCRIPT)
        SET(CMAKE_REQUIRED_FLAGS ${CMAKE_REQUIRED_FLAGS_SAVE} "-Wl,-M -Wl,${CMAKE_CURRENT_BINARY_DIR}/conftest.map")
        CHECK_C_SOURCE_COMPILES("void sym(void) {}
void sym2(void) {}
int main(void) {return 0;}
" HAVE_SOLARIS_LD_VERSION_SCRIPT)
    ENDIF ()
    SET(CMAKE_REQUIRED_FLAGS ${CMAKE_REQUIRED_FLAGS_SAVE})
    FILE(REMOVE "${CMAKE_CURRENT_BINARY_DIR}/conftest.map")
ENDIF ()


FIND_PROGRAM(AWK NAMES gawk awk)

INCLUDE_DIRECTORIES(${CMAKE_CURRENT_BINARY_DIR})

IF (NOT AWK OR ANDROID OR IOS)
    # No awk available to generate sources; use pre-built pnglibconf.h
    CONFIGURE_FILE(${CMAKE_CURRENT_SOURCE_DIR}/scripts/pnglibconf.h.prebuilt
            ${CMAKE_CURRENT_BINARY_DIR}/pnglibconf.h)
    ADD_CUSTOM_TARGET(genfiles) # Dummy
ELSE ()
    # Generate .chk from .out with awk:
    # generate_chk(INPUT inputfile OUTPUT outputfile [DEPENDS dep1 [dep2...]])
    INCLUDE(CMakeParseArguments)
    FUNCTION(GENERATE_CHK)
        SET(options)
        SET(oneValueArgs INPUT OUTPUT)
        SET(multiValueArgs DEPENDS)
        CMAKE_PARSE_ARGUMENTS(_GC "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})
        IF (NOT _GC_INPUT)
            MESSAGE(FATAL_ERROR "generate_chk: Missing INPUT argument")
        ENDIF ()
        IF (NOT _GC_OUTPUT)
            MESSAGE(FATAL_ERROR "generate_chk: Missing OUTPUT argument")
        ENDIF ()

        ADD_CUSTOM_COMMAND(OUTPUT "${_GC_OUTPUT}"
                COMMAND "${CMAKE_COMMAND}"
                "-DINPUT=${_GC_INPUT}"
                "-DOUTPUT=${_GC_OUTPUT}"
                -P "${CMAKE_CURRENT_BINARY_DIR}/scripts/genchk.cmake"
                DEPENDS "${_GC_INPUT}" ${_GC_DEPENDS}
                WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}")
    ENDFUNCTION()

    # Generate .out from .c with awk
    # generate_out(INPUT inputfile OUTPUT outputfile [DEPENDS dep1 [dep2...]])
    FUNCTION(GENERATE_OUT)
        SET(options)
        SET(oneValueArgs INPUT OUTPUT)
        SET(multiValueArgs DEPENDS)
        CMAKE_PARSE_ARGUMENTS(_GO "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})
        IF (NOT _GO_INPUT)
            MESSAGE(FATAL_ERROR "generate_out: Missing INPUT argument")
        ENDIF ()
        IF (NOT _GO_OUTPUT)
            MESSAGE(FATAL_ERROR "generate_out: Missing OUTPUT argument")
        ENDIF ()

        ADD_CUSTOM_COMMAND(OUTPUT "${_GO_OUTPUT}"
                COMMAND "${CMAKE_COMMAND}"
                "-DINPUT=${_GO_INPUT}"
                "-DOUTPUT=${_GO_OUTPUT}"
                -P "${CMAKE_CURRENT_BINARY_DIR}/scripts/genout.cmake"
                DEPENDS "${_GO_INPUT}" ${_GO_DEPENDS}
                WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}")
    ENDFUNCTION()

    # Generate specific source file with awk
    # generate_source(OUTPUT outputfile [DEPENDS dep1 [dep2...]])
    FUNCTION(GENERATE_SOURCE)
        SET(options)
        SET(oneValueArgs OUTPUT)
        SET(multiValueArgs DEPENDS)
        CMAKE_PARSE_ARGUMENTS(_GSO "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})
        IF (NOT _GSO_OUTPUT)
            MESSAGE(FATAL_ERROR "generate_source: Missing OUTPUT argument")
        ENDIF ()

        ADD_CUSTOM_COMMAND(OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/${_GSO_OUTPUT}"
                COMMAND "${CMAKE_COMMAND}"
                "-DOUTPUT=${_GSO_OUTPUT}"
                -P "${CMAKE_CURRENT_BINARY_DIR}/scripts/gensrc.cmake"
                DEPENDS ${_GSO_DEPENDS}
                WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}")
    ENDFUNCTION()

    # Copy file
    FUNCTION(GENERATE_COPY source destination)
        ADD_CUSTOM_COMMAND(OUTPUT "${destination}"
                COMMAND "${CMAKE_COMMAND}"
                -E remove "${destination}"
                COMMAND "${CMAKE_COMMAND}"
                -E copy "${source}" "${destination}"
                DEPENDS "${source}")
    ENDFUNCTION()

    # Generate scripts/pnglibconf.h
    GENERATE_SOURCE(OUTPUT "scripts/pnglibconf.c"
            DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/scripts/pnglibconf.dfa"
            "${CMAKE_CURRENT_SOURCE_DIR}/scripts/options.awk"
            "${CMAKE_CURRENT_SOURCE_DIR}/pngconf.h")

    # Generate pnglibconf.c
    GENERATE_SOURCE(OUTPUT "pnglibconf.c"
            DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/scripts/pnglibconf.dfa"
            "${CMAKE_CURRENT_SOURCE_DIR}/scripts/options.awk"
            "${CMAKE_CURRENT_SOURCE_DIR}/pngconf.h")

    IF (PNG_PREFIX)
        SET(PNGLIBCONF_H_EXTRA_DEPENDS
                "${CMAKE_CURRENT_BINARY_DIR}/scripts/prefix.out"
                "${CMAKE_CURRENT_SOURCE_DIR}/scripts/macro.lst")
        SET(PNGPREFIX_H_EXTRA_DEPENDS
                "${CMAKE_CURRENT_BINARY_DIR}/scripts/intprefix.out")
    ENDIF ()

    GENERATE_OUT(INPUT "${CMAKE_CURRENT_BINARY_DIR}/pnglibconf.c"
            OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/pnglibconf.out")

    # Generate pnglibconf.h
    GENERATE_SOURCE(OUTPUT "pnglibconf.h"
            DEPENDS "${CMAKE_CURRENT_BINARY_DIR}/pnglibconf.out"
            ${PNGLIBCONF_H_EXTRA_DEPENDS})

    GENERATE_OUT(INPUT "${CMAKE_CURRENT_SOURCE_DIR}/scripts/intprefix.c"
            OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/scripts/intprefix.out"
            DEPENDS "${CMAKE_CURRENT_BINARY_DIR}/pnglibconf.h")

    GENERATE_OUT(INPUT "${CMAKE_CURRENT_SOURCE_DIR}/scripts/prefix.c"
            OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/scripts/prefix.out"
            DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/png.h"
            "${CMAKE_CURRENT_SOURCE_DIR}/pngconf.h"
            "${CMAKE_CURRENT_BINARY_DIR}/pnglibconf.out")

    # Generate pngprefix.h
    GENERATE_SOURCE(OUTPUT "pngprefix.h"
            DEPENDS ${PNGPREFIX_H_EXTRA_DEPENDS})

    GENERATE_OUT(INPUT "${CMAKE_CURRENT_SOURCE_DIR}/scripts/sym.c"
            OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/scripts/sym.out"
            DEPENDS "${CMAKE_CURRENT_BINARY_DIR}/pnglibconf.h")

    GENERATE_OUT(INPUT "${CMAKE_CURRENT_SOURCE_DIR}/scripts/symbols.c"
            OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/scripts/symbols.out"
            DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/png.h"
            "${CMAKE_CURRENT_SOURCE_DIR}/pngconf.h"
            "${CMAKE_CURRENT_SOURCE_DIR}/scripts/pnglibconf.h.prebuilt")

    GENERATE_OUT(INPUT "${CMAKE_CURRENT_SOURCE_DIR}/scripts/vers.c"
            OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/scripts/vers.out"
            DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/png.h"
            "${CMAKE_CURRENT_SOURCE_DIR}/pngconf.h"
            "${CMAKE_CURRENT_BINARY_DIR}/pnglibconf.h")

    GENERATE_CHK(INPUT "${CMAKE_CURRENT_BINARY_DIR}/scripts/symbols.out"
            OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/scripts/symbols.chk"
            DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/scripts/checksym.awk"
            "${CMAKE_CURRENT_SOURCE_DIR}/scripts/symbols.def")

    ADD_CUSTOM_TARGET(symbol-check
            DEPENDS "${CMAKE_CURRENT_BINARY_DIR}/scripts/symbols.chk")

    GENERATE_COPY("${CMAKE_CURRENT_BINARY_DIR}/scripts/sym.out"
            "${CMAKE_CURRENT_BINARY_DIR}/libpng.sym")
    GENERATE_COPY("${CMAKE_CURRENT_BINARY_DIR}/scripts/vers.out"
            "${CMAKE_CURRENT_BINARY_DIR}/libpng.vers")

    ADD_CUSTOM_TARGET(genvers
            DEPENDS "${CMAKE_CURRENT_BINARY_DIR}/libpng.vers")
    ADD_CUSTOM_TARGET(gensym
            DEPENDS "${CMAKE_CURRENT_BINARY_DIR}/libpng.sym")

    ADD_CUSTOM_TARGET("genprebuilt"
            COMMAND "${CMAKE_COMMAND}"
            "-DOUTPUT=scripts/pnglibconf.h.prebuilt"
            -P "${CMAKE_CURRENT_BINARY_DIR}/scripts/gensrc.cmake"
            WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}")

    # A single target handles generation of all generated files.
    # If they are depended upon separately by multiple targets, this
    # confuses parallel make (it would require a separate top-level
    # target for each file to track the dependencies properly).
    ADD_CUSTOM_TARGET(genfiles
            DEPENDS "${CMAKE_CURRENT_BINARY_DIR}/libpng.sym"
            "${CMAKE_CURRENT_BINARY_DIR}/libpng.vers"
            "${CMAKE_CURRENT_BINARY_DIR}/pnglibconf.c"
            "${CMAKE_CURRENT_BINARY_DIR}/pnglibconf.h"
            "${CMAKE_CURRENT_BINARY_DIR}/pnglibconf.out"
            "${CMAKE_CURRENT_BINARY_DIR}/pngprefix.h"
            "${CMAKE_CURRENT_BINARY_DIR}/scripts/intprefix.out"
            "${CMAKE_CURRENT_BINARY_DIR}/scripts/pnglibconf.c"
            "${CMAKE_CURRENT_BINARY_DIR}/scripts/prefix.out"
            "${CMAKE_CURRENT_BINARY_DIR}/scripts/sym.out"
            "${CMAKE_CURRENT_BINARY_DIR}/scripts/symbols.chk"
            "${CMAKE_CURRENT_BINARY_DIR}/scripts/symbols.out"
            "${CMAKE_CURRENT_BINARY_DIR}/scripts/vers.out")
ENDIF (NOT AWK OR ANDROID OR IOS)

# List the source code files.
SET(libpng_public_hdrs
        png.h
        pngconf.h
        "${CMAKE_CURRENT_BINARY_DIR}/pnglibconf.h"
        )
SET(libpng_private_hdrs
        pngpriv.h
        pngdebug.h
        pnginfo.h
        pngstruct.h
        )
IF (AWK AND NOT ANDROID AND NOT IOS)
    LIST(APPEND libpng_private_hdrs "${CMAKE_CURRENT_BINARY_DIR}/pngprefix.h")
ENDIF ()
SET(libpng_sources
        ${libpng_public_hdrs}
        ${libpng_private_hdrs}
        png.c
        pngerror.c
        pngget.c
        pngmem.c
        pngpread.c
        pngread.c
        pngrio.c
        pngrtran.c
        pngrutil.c
        pngset.c
        pngtrans.c
        pngwio.c
        pngwrite.c
        pngwtran.c
        pngwutil.c
        ${libpng_arm_sources}
        ${libpng_intel_sources}
        ${libpng_mips_sources}
        ${libpng_powerpc_sources}
        )
SET(pngtest_sources
        pngtest.c
        )
SET(pngvalid_sources
        contrib/libtests/pngvalid.c
        )
SET(pngstest_sources
        contrib/libtests/pngstest.c
        )
SET(pngunknown_sources
        contrib/libtests/pngunknown.c
        )
SET(pngimage_sources
        contrib/libtests/pngimage.c
        )
SET(pngfix_sources
        contrib/tools/pngfix.c
        )
SET(png_fix_itxt_sources
        contrib/tools/png-fix-itxt.c
        )

IF (MSVC)
    ADD_DEFINITIONS(-D_CRT_SECURE_NO_DEPRECATE)
ENDIF ()

IF (PNG_DEBUG)
    ADD_DEFINITIONS(-DPNG_DEBUG)
ENDIF ()

UNSET(PNG_LIB_TARGETS)

IF (PNG_SHARED)
    ADD_LIBRARY(png SHARED ${libpng_sources})
    SET(PNG_LIB_TARGETS png)
    SET_TARGET_PROPERTIES(png PROPERTIES OUTPUT_NAME ${PNG_LIB_NAME})
    ADD_DEPENDENCIES(png genfiles)
    IF (MSVC)
        # MVC does not append 'lib'. Do it here, to have consistent name.
        SET_TARGET_PROPERTIES(png PROPERTIES PREFIX "lib")
        SET_TARGET_PROPERTIES(png PROPERTIES IMPORT_PREFIX "lib")
    ENDIF ()
    TARGET_LINK_LIBRARIES(png ZLib::Framework ${M_LIBRARY})

    IF (UNIX AND AWK)
        IF (HAVE_LD_VERSION_SCRIPT)
            SET_TARGET_PROPERTIES(png PROPERTIES
                    LINK_FLAGS "-Wl,--version-script='${CMAKE_CURRENT_BINARY_DIR}/libpng.vers'")
        ELSEIF (HAVE_SOLARIS_LD_VERSION_SCRIPT)
            SET_TARGET_PROPERTIES(png PROPERTIES
                    LINK_FLAGS "-Wl,-M -Wl,'${CMAKE_CURRENT_BINARY_DIR}/libpng.vers'")
        ENDIF ()
    ENDIF ()


    # Reference: https://www.py4u.net/discuss/2364298
    ADD_CUSTOM_COMMAND(TARGET png POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy_directory
            "${ZLIB_BINARY_DIR}"
            $<TARGET_FILE_DIR:png>)
ENDIF ()

IF (PNG_STATIC)
    # does not work without changing name
    SET(PNG_LIB_NAME_STATIC png_static)
    ADD_LIBRARY(png_static STATIC ${libpng_sources})
    ADD_DEPENDENCIES(png_static genfiles)
    # MSVC doesn't use a different file extension for shared vs. static
    # libs. We are able to change OUTPUT_NAME to remove the _static
    # for all other platforms.
    IF (NOT MSVC)
        SET_TARGET_PROPERTIES(png_static PROPERTIES
                OUTPUT_NAME "${PNG_LIB_NAME}"
                CLEAN_DIRECT_OUTPUT 1)
    ELSE ()
        SET_TARGET_PROPERTIES(png_static PROPERTIES
                OUTPUT_NAME "${PNG_LIB_NAME}_static"
                CLEAN_DIRECT_OUTPUT 1)
    ENDIF ()
    LIST(APPEND PNG_LIB_TARGETS png_static)
    IF (MSVC)
        # MSVC does not append 'lib'. Do it here, to have consistent name.
        SET_TARGET_PROPERTIES(png_static PROPERTIES PREFIX "lib")
    ENDIF ()
    TARGET_LINK_LIBRARIES(png_static ZLib::Framework ${M_LIBRARY})

    # Reference: https://www.py4u.net/discuss/2364298
    ADD_CUSTOM_COMMAND(TARGET png_static POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy_directory
            "${ZLIB_BINARY_DIR}"
            $<TARGET_FILE_DIR:png_static>)
ENDIF ()

IF (PNG_FRAMEWORK)
    SET(PNG_LIB_NAME_FRAMEWORK png_framework)
    ADD_LIBRARY(png_framework SHARED ${libpng_sources})
    ADD_DEPENDENCIES(png_framework genfiles)
    LIST(APPEND PNG_LIB_TARGETS png_framework)
    SET_TARGET_PROPERTIES(png_framework PROPERTIES
            FRAMEWORK TRUE
            FRAMEWORK_VERSION ${PNGLIB_VERSION}
            MACOSX_FRAMEWORK_SHORT_VERSION_STRING ${PNGLIB_MAJOR}.${PNGLIB_MINOR}
            MACOSX_FRAMEWORK_BUNDLE_VERSION ${PNGLIB_VERSION}
            MACOSX_FRAMEWORK_IDENTIFIER org.libpng.libpng
            XCODE_ATTRIBUTE_INSTALL_PATH "@rpath"
            PUBLIC_HEADER "${libpng_public_hdrs}"
            OUTPUT_NAME png)
    TARGET_LINK_LIBRARIES(png_framework ZLib::Framework ${M_LIBRARY})
ENDIF ()

IF (NOT PNG_LIB_TARGETS)
    MESSAGE(SEND_ERROR "No library variant selected to build. "
            "Please enable at least one of the following options: "
            "PNG_STATIC, PNG_SHARED, PNG_FRAMEWORK")
ENDIF ()

IF (PNG_SHARED AND WIN32)
    SET_TARGET_PROPERTIES(png PROPERTIES
            DEFINE_SYMBOL PNG_BUILD_DLL)
ENDIF ()

FUNCTION(PNG_ADD_TEST)
    SET(options)
    SET(oneValueArgs NAME COMMAND)
    SET(multiValueArgs OPTIONS FILES)
    CMAKE_PARSE_ARGUMENTS(_PAT "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    IF (NOT _PAT_NAME)
        MESSAGE(FATAL_ERROR "png_add_test: Missing NAME argument")
    ENDIF ()
    IF (NOT _PAT_COMMAND)
        MESSAGE(FATAL_ERROR "png_add_test: Missing COMMAND argument")
    ENDIF ()

    SET(TEST_OPTIONS "${_PAT_OPTIONS}")
    SET(TEST_FILES "${_PAT_FILES}")

    CONFIGURE_FILE("${CMAKE_CURRENT_SOURCE_DIR}/scripts/test.cmake.in"
            "${CMAKE_CURRENT_BINARY_DIR}/tests/${_PAT_NAME}.cmake"
            @ONLY)
    ADD_TEST(NAME "${_PAT_NAME}"
            COMMAND "${CMAKE_COMMAND}"
            "-DLIBPNG=$<TARGET_FILE:png>"
            "-DTEST_COMMAND=$<TARGET_FILE:${_PAT_COMMAND}>"
            -P "${CMAKE_CURRENT_BINARY_DIR}/tests/${_PAT_NAME}.cmake")
ENDFUNCTION()

IF (PNG_TESTS AND PNG_SHARED)
    # Find test PNG files by globbing, but sort lists to ensure
    # consistency between different filesystems.
    FILE(GLOB PNGSUITE_PNGS "${CMAKE_CURRENT_SOURCE_DIR}/contrib/pngsuite/*.png")
    LIST(SORT PNGSUITE_PNGS)
    FILE(GLOB TEST_PNGS "${CMAKE_CURRENT_SOURCE_DIR}/contrib/testpngs/*.png")
    LIST(SORT TEST_PNGS)

    SET(PNGTEST_PNG "${CMAKE_CURRENT_SOURCE_DIR}/pngtest.png")

    ADD_EXECUTABLE(pngtest ${pngtest_sources})
    TARGET_LINK_LIBRARIES(pngtest png)

    PNG_ADD_TEST(NAME pngtest
            COMMAND pngtest
            FILES "${PNGTEST_PNG}")

    ADD_EXECUTABLE(pngvalid ${pngvalid_sources})
    TARGET_LINK_LIBRARIES(pngvalid png)

    PNG_ADD_TEST(NAME pngvalid-gamma-16-to-8
            COMMAND pngvalid
            OPTIONS --gamma-16-to-8)
    PNG_ADD_TEST(NAME pngvalid-gamma-alpha-mode
            COMMAND pngvalid
            OPTIONS --gamma-alpha-mode)
    PNG_ADD_TEST(NAME pngvalid-gamma-background
            COMMAND pngvalid
            OPTIONS --gamma-background)
    PNG_ADD_TEST(NAME pngvalid-gamma-expand16-alpha-mode
            COMMAND pngvalid
            OPTIONS --gamma-alpha-mode --expand16)
    PNG_ADD_TEST(NAME pngvalid-gamma-expand16-background
            COMMAND pngvalid
            OPTIONS --gamma-background --expand16)
    PNG_ADD_TEST(NAME pngvalid-gamma-expand16-transform
            COMMAND pngvalid
            OPTIONS --gamma-transform --expand16)
    PNG_ADD_TEST(NAME pngvalid-gamma-sbit
            COMMAND pngvalid
            OPTIONS --gamma-sbit)
    PNG_ADD_TEST(NAME pngvalid-gamma-threshold
            COMMAND pngvalid
            OPTIONS --gamma-threshold)
    PNG_ADD_TEST(NAME pngvalid-gamma-transform
            COMMAND pngvalid
            OPTIONS --gamma-transform)
    PNG_ADD_TEST(NAME pngvalid-progressive-interlace-standard
            COMMAND pngvalid
            OPTIONS --standard --progressive-read --interlace)
    PNG_ADD_TEST(NAME pngvalid-progressive-size
            COMMAND pngvalid
            OPTIONS --size --progressive-read)
    PNG_ADD_TEST(NAME pngvalid-progressive-standard
            COMMAND pngvalid
            OPTIONS --standard --progressive-read)
    PNG_ADD_TEST(NAME pngvalid-standard
            COMMAND pngvalid
            OPTIONS --standard)
    PNG_ADD_TEST(NAME pngvalid-transform
            COMMAND pngvalid
            OPTIONS --transform)

    ADD_EXECUTABLE(pngstest ${pngstest_sources})
    TARGET_LINK_LIBRARIES(pngstest png)

    FOREACH (gamma_type 1.8 linear none sRGB)
        FOREACH (alpha_type none alpha)
            SET(PNGSTEST_FILES)
            FOREACH (test_png ${TEST_PNGS})
                STRING(REGEX MATCH ".*-linear[-.].*" TEST_PNG_LINEAR "${test_png}")
                STRING(REGEX MATCH ".*-sRGB[-.].*" TEST_PNG_SRGB "${test_png}")
                STRING(REGEX MATCH ".*-1.8[-.].*" TEST_PNG_G18 "${test_png}")
                STRING(REGEX MATCH ".*-alpha-.*" TEST_PNG_ALPHA "${test_png}")

                SET(TEST_PNG_VALID TRUE)

                IF (TEST_PNG_ALPHA)
                    IF (NOT "${alpha_type}" STREQUAL "alpha")
                        SET(TEST_PNG_VALID FALSE)
                    ENDIF ()
                ELSE ()
                    IF ("${alpha_type}" STREQUAL "alpha")
                        SET(TEST_PNG_VALID FALSE)
                    ENDIF ()
                ENDIF ()

                IF (TEST_PNG_LINEAR)
                    IF (NOT "${gamma_type}" STREQUAL "linear")
                        SET(TEST_PNG_VALID FALSE)
                    ENDIF ()
                ELSEIF (TEST_PNG_SRGB)
                    IF (NOT "${gamma_type}" STREQUAL "sRGB")
                        SET(TEST_PNG_VALID FALSE)
                    ENDIF ()
                ELSEIF (TEST_PNG_G18)
                    IF (NOT "${gamma_type}" STREQUAL "1.8")
                        SET(TEST_PNG_VALID FALSE)
                    ENDIF ()
                ELSE ()
                    IF (NOT "${gamma_type}" STREQUAL "none")
                        SET(TEST_PNG_VALID FALSE)
                    ENDIF ()
                ENDIF ()

                IF (TEST_PNG_VALID)
                    LIST(APPEND PNGSTEST_FILES "${test_png}")
                ENDIF ()
            ENDFOREACH ()
            # Should already be sorted, but sort anyway to be certain.
            LIST(SORT PNGSTEST_FILES)
            PNG_ADD_TEST(NAME pngstest-${gamma_type}-${alpha_type}
                    COMMAND pngstest
                    OPTIONS --tmpfile "${gamma_type}-${alpha_type}-" --log
                    FILES ${PNGSTEST_FILES})
        ENDFOREACH ()
    ENDFOREACH ()

    ADD_EXECUTABLE(pngunknown ${pngunknown_sources})
    TARGET_LINK_LIBRARIES(pngunknown png)

    PNG_ADD_TEST(NAME pngunknown-discard
            COMMAND pngunknown
            OPTIONS --strict default=discard
            FILES "${PNGTEST_PNG}")
    PNG_ADD_TEST(NAME pngunknown-IDAT
            COMMAND pngunknown
            OPTIONS --strict default=discard IDAT=save
            FILES "${PNGTEST_PNG}")
    PNG_ADD_TEST(NAME pngunknown-if-safe
            COMMAND pngunknown
            OPTIONS --strict default=if-safe
            FILES "${PNGTEST_PNG}")
    PNG_ADD_TEST(NAME pngunknown-sAPI
            COMMAND pngunknown
            OPTIONS --strict bKGD=save cHRM=save gAMA=save all=discard iCCP=save sBIT=save sRGB=save
            FILES "${PNGTEST_PNG}")
    PNG_ADD_TEST(NAME pngunknown-save
            COMMAND pngunknown
            OPTIONS --strict default=save
            FILES "${PNGTEST_PNG}")
    PNG_ADD_TEST(NAME pngunknown-sTER
            COMMAND pngunknown
            OPTIONS --strict sTER=if-safe
            FILES "${PNGTEST_PNG}")
    PNG_ADD_TEST(NAME pngunknown-vpAg
            COMMAND pngunknown
            OPTIONS --strict vpAg=if-safe
            FILES "${PNGTEST_PNG}")

    ADD_EXECUTABLE(pngimage ${pngimage_sources})
    TARGET_LINK_LIBRARIES(pngimage png)

    PNG_ADD_TEST(NAME pngimage-quick
            COMMAND pngimage
            OPTIONS --list-combos --log
            FILES ${PNGSUITE_PNGS})
    PNG_ADD_TEST(NAME pngimage-full
            COMMAND pngimage
            OPTIONS --exhaustive --list-combos --log
            FILES ${PNGSUITE_PNGS})
ENDIF ()

IF (PNG_SHARED AND PNG_EXECUTABLES)
    ADD_EXECUTABLE(pngfix ${pngfix_sources})
    TARGET_LINK_LIBRARIES(pngfix png)
    SET(PNG_BIN_TARGETS pngfix)

    ADD_EXECUTABLE(png-fix-itxt ${png_fix_itxt_sources})
    TARGET_LINK_LIBRARIES(png-fix-itxt ZLib::Framework ${M_LIBRARY})
    LIST(APPEND PNG_BIN_TARGETS png-fix-itxt)
ENDIF ()

# Creates a symlink from src to dest (if possible), or, alternatively,
# copies src to dest if different.
INCLUDE(CMakeParseArguments)
FUNCTION(CREATE_SYMLINK DEST_FILE)
    CMAKE_PARSE_ARGUMENTS(S "" "FILE;TARGET" "" ${ARGN})

    IF (NOT S_TARGET AND NOT S_FILE)
        MESSAGE(FATAL_ERROR "create_symlink: Missing TARGET or FILE argument")
    ENDIF ()

    IF (S_TARGET AND S_FILE)
        MESSAGE(FATAL_ERROR "create_symlink: "
                "Both source file ${S_FILE} and build target ${S_TARGET} arguments are present; "
                "can only have one")
    ENDIF ()

    IF (S_FILE)
        # If we don't need to symlink something that's coming from a build target,
        # we can go ahead and symlink/copy at configure time.
        IF (CMAKE_HOST_WIN32 AND NOT CYGWIN)
            EXECUTE_PROCESS(COMMAND "${CMAKE_COMMAND}"
                    -E copy_if_different
                    ${S_FILE} ${DEST_FILE}
                    WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}")
        ELSE ()
            EXECUTE_PROCESS(COMMAND "${CMAKE_COMMAND}"
                    -E create_symlink
                    ${S_FILE} ${DEST_FILE}
                    WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}")
        ENDIF ()
    ENDIF ()

    IF (S_TARGET)
        # We need to use generator expressions, which can be a bit tricky.
        # For simplicity, make the symlink a POST_BUILD step, and use the TARGET
        # signature of add_custom_command.
        IF (CMAKE_HOST_WIN32 AND NOT CYGWIN)
            ADD_CUSTOM_COMMAND(TARGET ${S_TARGET}
                    POST_BUILD
                    COMMAND "${CMAKE_COMMAND}"
                    -E copy_if_different
                    $<TARGET_LINKER_FILE_NAME:${S_TARGET}>
                    $<TARGET_LINKER_FILE_DIR:${S_TARGET}>/${DEST_FILE})
        ELSE ()
            ADD_CUSTOM_COMMAND(TARGET ${S_TARGET}
                    POST_BUILD
                    COMMAND "${CMAKE_COMMAND}"
                    -E create_symlink
                    $<TARGET_LINKER_FILE_NAME:${S_TARGET}>
                    $<TARGET_LINKER_FILE_DIR:${S_TARGET}>/${DEST_FILE})
        ENDIF ()
    ENDIF ()
ENDFUNCTION()

# Create source generation scripts.
CONFIGURE_FILE(${CMAKE_CURRENT_SOURCE_DIR}/scripts/genchk.cmake.in
        ${CMAKE_CURRENT_BINARY_DIR}/scripts/genchk.cmake
        @ONLY)
CONFIGURE_FILE(${CMAKE_CURRENT_SOURCE_DIR}/scripts/genout.cmake.in
        ${CMAKE_CURRENT_BINARY_DIR}/scripts/genout.cmake
        @ONLY)
CONFIGURE_FILE(${CMAKE_CURRENT_SOURCE_DIR}/scripts/gensrc.cmake.in
        ${CMAKE_CURRENT_BINARY_DIR}/scripts/gensrc.cmake
        @ONLY)


# Create pkgconfig files.
# We use the same files like ./configure, so we have to set its vars.
# Only do this on Windows for Cygwin - the files don't make much sense
# outside of a UNIX look-alike.
IF (NOT WIN32 OR CYGWIN OR MINGW)
    SET(prefix ${CMAKE_INSTALL_PREFIX})
    SET(exec_prefix ${CMAKE_INSTALL_PREFIX})
    SET(libdir ${CMAKE_INSTALL_FULL_LIBDIR})
    SET(includedir ${CMAKE_INSTALL_FULL_INCLUDEDIR})
    SET(LIBS "-lz -lm")
    CONFIGURE_FILE(${CMAKE_CURRENT_SOURCE_DIR}/libpng.pc.in
            ${CMAKE_CURRENT_BINARY_DIR}/${PNGLIB_NAME}.pc
            @ONLY)
    CREATE_SYMLINK(libpng.pc FILE ${PNGLIB_NAME}.pc)
    CONFIGURE_FILE(${CMAKE_CURRENT_SOURCE_DIR}/libpng-config.in
            ${CMAKE_CURRENT_BINARY_DIR}/${PNGLIB_NAME}-config
            @ONLY)
    CREATE_SYMLINK(libpng-config FILE ${PNGLIB_NAME}-config)
ENDIF ()

# Set up links.
IF (PNG_SHARED)
    SET_TARGET_PROPERTIES(png PROPERTIES
            VERSION 16.${PNGLIB_RELEASE}.git
            #   VERSION 16.${PNGLIB_RELEASE}.0
            SOVERSION 16
            CLEAN_DIRECT_OUTPUT 1)
ENDIF ()


