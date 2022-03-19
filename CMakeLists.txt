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

INCLUDE(CMakeModules/HardwareOptimizations.cmake)

IF (PNG_HARDWARE_OPTIMIZATIONS)
    ENABLE_HARDWARE_OPTIMIZATIONS()

ELSE ()
    DISABLE_HARDWARE_OPTIMIZATIONS()

ENDIF ()


# Set configuration file to include directories
CONFIGURE_FILE(${PNG_SOURCE_DIR}/Scripts/pnglibconf.h.prebuilt ${PNG_SOURCE_DIR}/Include/PNG/pnglibconf.h)


IF (MSVC)
    ADD_DEFINITIONS(-D_CRT_SECURE_NO_DEPRECATE)
ENDIF ()

IF (PNG_DEBUG)
    ADD_DEFINITIONS(-DPNG_DEBUG)
ENDIF ()


ADD_LIBRARY(Png.Framework.Object OBJECT
        ${libpng_arm_sources}
        ${libpng_intel_sources}
        ${libpng_mips_sources}
        ${libpng_powerpc_sources}

        Source/png.c
        Source/pngrio.c
        Source/pngget.c
        Source/pngmem.c
        Source/pngset.c
        Source/pngwio.c
        Source/pngread.c
        Source/pngpread.c
        Source/pngerror.c
        Source/pngrtran.c
        Source/pngrutil.c
        Source/pngtrans.c
        Source/pngwrite.c
        Source/pngwtran.c
        Source/pngwutil.c
        )

# Link to dependencies to OBJECT
TARGET_LINK_LIBRARIES(Png.Framework.Object PUBLIC ZLib::Framework ${M_LIBRARY})
TARGET_INCLUDE_DIRECTORIES(Png.Framework.Object PUBLIC $<BUILD_INTERFACE:${PNG_SOURCE_DIR}/Include/>)


IF (PNG_SHARED)

    # The POSITION_INDEPENDENT_CODE property determines whether position independent executables or
    # shared libraries will be created. This property is True by default for SHARED and MODULE library
    # targets and False otherwise.

    # Property: SHARED, POSITION_INDEPENDENT_CODE
    ADD_LIBRARY(Png.Framework SHARED $<TARGET_OBJECTS:Png.Framework.Object>)

    IF (WIN32)
        SET_TARGET_PROPERTIES(Png.Framework PROPERTIES DEFINE_SYMBOL PNG_BUILD_DLL)
    ENDIF ()

ELSE ()

    ADD_LIBRARY(Png.Framework STATIC $<TARGET_OBJECTS:Png.Framework.Object>)

ENDIF ()


TARGET_INCLUDE_DIRECTORIES(Png.Framework PUBLIC $<BUILD_INTERFACE:${PNG_SOURCE_DIR}/Include/>)
TARGET_LINK_LIBRARIES(Png.Framework PUBLIC ZLib::Framework ${M_LIBRARY})

# Move the DLL in Windows for link the target with the dependencies
ADD_CUSTOM_COMMAND(TARGET Png.Framework POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_directory
        ${ZLIB_BINARY_DIR}
        $<TARGET_FILE_DIR:Png.Framework>)



ADD_SUBDIRECTORY(Test/)
ADD_SUBDIRECTORY(Contrib/)
