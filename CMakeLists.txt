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

INCLUDE(CMakeModules/HardwareOptimizations.cmake)

IF (PNG_HARDWARE_OPTIMIZATIONS)
    ENABLE_HARDWARE_OPTIMIZATIONS()

ELSE ()
    DISABLE_HARDWARE_OPTIMIZATIONS()

ENDIF ()

# Set PNG_LIB_NAME.
SET(PNG_LIB_NAME png${PNGLIB_MAJOR}${PNGLIB_MINOR})

# Distinguish between debug and release builds.
SET(CMAKE_DEBUG_POSTFIX "d")

INCLUDE(CheckCSourceCompiles)
OPTION(ld-version-script "Enable linker version script" ON)
IF (ld-version-script AND NOT APPLE)
    # Check if LD supports linker Scripts.
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
    CONFIGURE_FILE(${CMAKE_CURRENT_SOURCE_DIR}/Scripts/pnglibconf.h.prebuilt
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
                -P "${CMAKE_CURRENT_BINARY_DIR}/Scripts/genchk.cmake"
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
                -P "${CMAKE_CURRENT_BINARY_DIR}/Scripts/genout.cmake"
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
                -P "${CMAKE_CURRENT_BINARY_DIR}/Scripts/gensrc.cmake"
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

    # Generate Scripts/pnglibconf.h
    GENERATE_SOURCE(OUTPUT "Scripts/pnglibconf.c"
            DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/Scripts/pnglibconf.dfa"
            "${CMAKE_CURRENT_SOURCE_DIR}/Scripts/options.awk"
            "${CMAKE_CURRENT_SOURCE_DIR}/pngconf.h")

    # Generate pnglibconf.c
    GENERATE_SOURCE(OUTPUT "pnglibconf.c"
            DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/Scripts/pnglibconf.dfa"
            "${CMAKE_CURRENT_SOURCE_DIR}/Scripts/options.awk"
            "${CMAKE_CURRENT_SOURCE_DIR}/pngconf.h")

    IF (PNG_PREFIX)
        SET(PNGLIBCONF_H_EXTRA_DEPENDS
                "${CMAKE_CURRENT_BINARY_DIR}/Scripts/prefix.out"
                "${CMAKE_CURRENT_SOURCE_DIR}/Scripts/macro.lst")
        SET(PNGPREFIX_H_EXTRA_DEPENDS
                "${CMAKE_CURRENT_BINARY_DIR}/Scripts/intprefix.out")
    ENDIF ()

    GENERATE_OUT(INPUT "${CMAKE_CURRENT_BINARY_DIR}/pnglibconf.c"
            OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/pnglibconf.out")

    # Generate pnglibconf.h
    GENERATE_SOURCE(OUTPUT "pnglibconf.h"
            DEPENDS "${CMAKE_CURRENT_BINARY_DIR}/pnglibconf.out"
            ${PNGLIBCONF_H_EXTRA_DEPENDS})

    GENERATE_OUT(INPUT "${CMAKE_CURRENT_SOURCE_DIR}/Scripts/intprefix.c"
            OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/Scripts/intprefix.out"
            DEPENDS "${CMAKE_CURRENT_BINARY_DIR}/pnglibconf.h")

    GENERATE_OUT(INPUT "${CMAKE_CURRENT_SOURCE_DIR}/Scripts/prefix.c"
            OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/Scripts/prefix.out"
            DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/png.h"
            "${CMAKE_CURRENT_SOURCE_DIR}/pngconf.h"
            "${CMAKE_CURRENT_BINARY_DIR}/pnglibconf.out")

    # Generate pngprefix.h
    GENERATE_SOURCE(OUTPUT "pngprefix.h"
            DEPENDS ${PNGPREFIX_H_EXTRA_DEPENDS})

    GENERATE_OUT(INPUT "${CMAKE_CURRENT_SOURCE_DIR}/Scripts/sym.c"
            OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/Scripts/sym.out"
            DEPENDS "${CMAKE_CURRENT_BINARY_DIR}/pnglibconf.h")

    GENERATE_OUT(INPUT "${CMAKE_CURRENT_SOURCE_DIR}/Scripts/symbols.c"
            OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/Scripts/symbols.out"
            DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/png.h"
            "${CMAKE_CURRENT_SOURCE_DIR}/pngconf.h"
            "${CMAKE_CURRENT_SOURCE_DIR}/Scripts/pnglibconf.h.prebuilt")

    GENERATE_OUT(INPUT "${CMAKE_CURRENT_SOURCE_DIR}/Scripts/vers.c"
            OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/Scripts/vers.out"
            DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/png.h"
            "${CMAKE_CURRENT_SOURCE_DIR}/pngconf.h"
            "${CMAKE_CURRENT_BINARY_DIR}/pnglibconf.h")

    GENERATE_CHK(INPUT "${CMAKE_CURRENT_BINARY_DIR}/Scripts/symbols.out"
            OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/Scripts/symbols.chk"
            DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/Scripts/checksym.awk"
            "${CMAKE_CURRENT_SOURCE_DIR}/Scripts/symbols.def")

    ADD_CUSTOM_TARGET(symbol-check
            DEPENDS "${CMAKE_CURRENT_BINARY_DIR}/Scripts/symbols.chk")

    GENERATE_COPY("${CMAKE_CURRENT_BINARY_DIR}/Scripts/sym.out"
            "${CMAKE_CURRENT_BINARY_DIR}/libpng.sym")
    GENERATE_COPY("${CMAKE_CURRENT_BINARY_DIR}/Scripts/vers.out"
            "${CMAKE_CURRENT_BINARY_DIR}/libpng.vers")

    ADD_CUSTOM_TARGET(genvers
            DEPENDS "${CMAKE_CURRENT_BINARY_DIR}/libpng.vers")
    ADD_CUSTOM_TARGET(gensym
            DEPENDS "${CMAKE_CURRENT_BINARY_DIR}/libpng.sym")

    ADD_CUSTOM_TARGET("genprebuilt"
            COMMAND "${CMAKE_COMMAND}"
            "-DOUTPUT=Scripts/pnglibconf.h.prebuilt"
            -P "${CMAKE_CURRENT_BINARY_DIR}/Scripts/gensrc.cmake"
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
            "${CMAKE_CURRENT_BINARY_DIR}/Scripts/intprefix.out"
            "${CMAKE_CURRENT_BINARY_DIR}/Scripts/pnglibconf.c"
            "${CMAKE_CURRENT_BINARY_DIR}/Scripts/prefix.out"
            "${CMAKE_CURRENT_BINARY_DIR}/Scripts/sym.out"
            "${CMAKE_CURRENT_BINARY_DIR}/Scripts/symbols.chk"
            "${CMAKE_CURRENT_BINARY_DIR}/Scripts/symbols.out"
            "${CMAKE_CURRENT_BINARY_DIR}/Scripts/vers.out")
ENDIF (NOT AWK OR ANDROID OR IOS)


IF (MSVC)
    ADD_DEFINITIONS(-D_CRT_SECURE_NO_DEPRECATE)
ENDIF ()

IF (PNG_DEBUG)
    ADD_DEFINITIONS(-DPNG_DEBUG)
ENDIF ()

UNSET(PNG_LIB_TARGETS)


ADD_LIBRARY(Png.Framework.Object OBJECT
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
    ADD_EXECUTABLE(pngfix contrib/tools/pngfix.c)
    TARGET_LINK_LIBRARIES(pngfix Png.Framework)
    SET(PNG_BIN_TARGETS pngfix)

    ADD_EXECUTABLE(png-fix-itxt contrib/tools/png-fix-itxt.c)
    TARGET_LINK_LIBRARIES(png-fix-itxt ZLib::Framework ${M_LIBRARY})
    LIST(APPEND PNG_BIN_TARGETS png-fix-itxt)
ENDIF ()
