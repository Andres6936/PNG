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

# Used for CMake in another directories find the root to sources
SET(PNG_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR})
SET(PNG_BINARY_DIR ${CMAKE_CURRENT_BINARY_DIR})

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


ADD_LIBRARY(Png.Framework.Object OBJECT
        ${libpng_public_hdrs}
        ${libpng_private_hdrs}
        ${libpng_arm_sources}
        ${libpng_intel_sources}
        ${libpng_mips_sources}
        ${libpng_powerpc_sources}

        png.c
        pngrio.c
        pngget.c
        pngmem.c
        pngset.c
        pngwio.c
        pngread.c
        pngpread.c
        pngerror.c
        pngrtran.c
        pngrutil.c
        pngtrans.c
        pngwrite.c
        pngwtran.c
        pngwutil.c
        )


# General configuration for Png.Framework, it can be STATIC or SHARED
ADD_DEPENDENCIES(Png.Framework.Object genfiles)
# Link to dependencies to OBJECT
TARGET_LINK_LIBRARIES(Png.Framework.Object PUBLIC ZLib::Framework ${M_LIBRARY})


IF (PNG_SHARED)

    # The POSITION_INDEPENDENT_CODE property determines whether position independent executables or
    # shared libraries will be created. This property is True by default for SHARED and MODULE library
    # targets and False otherwise.

    # Property: SHARED, POSITION_INDEPENDENT_CODE
    ADD_LIBRARY(Png.Framework SHARED $<TARGET_OBJECTS:Png.Framework.Object>)

    IF (UNIX AND AWK)
        IF (HAVE_LD_VERSION_SCRIPT)
            SET_TARGET_PROPERTIES(Png.Framework PROPERTIES
                    LINK_FLAGS "-Wl,--version-script='${CMAKE_CURRENT_BINARY_DIR}/libpng.vers'")
        ELSEIF (HAVE_SOLARIS_LD_VERSION_SCRIPT)
            SET_TARGET_PROPERTIES(Png.Framework PROPERTIES
                    LINK_FLAGS "-Wl,-M -Wl,'${CMAKE_CURRENT_BINARY_DIR}/libpng.vers'")
        ENDIF ()
    ENDIF ()

    IF (WIN32)
        SET_TARGET_PROPERTIES(Png.Framework PROPERTIES DEFINE_SYMBOL PNG_BUILD_DLL)
    ENDIF ()

ELSE ()

    ADD_LIBRARY(Png.Framework STATIC $<TARGET_OBJECTS:Png.Framework.Object>)

ENDIF ()


# General configuration for Png.Framework, it can be STATIC or SHARED
ADD_DEPENDENCIES(Png.Framework genfiles)
TARGET_LINK_LIBRARIES(Png.Framework PUBLIC ZLib::Framework ${M_LIBRARY})

# Move the DLL in Windows for link the target with the dependencies
ADD_CUSTOM_COMMAND(TARGET Png.Framework POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_directory
        ${ZLIB_BINARY_DIR}
        $<TARGET_FILE_DIR:Png.Framework>)



ADD_SUBDIRECTORY(tests/)


IF (PNG_SHARED AND PNG_EXECUTABLES)
    ADD_EXECUTABLE(pngfix ${pngfix_sources})
    TARGET_LINK_LIBRARIES(pngfix Png.Framework)
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



