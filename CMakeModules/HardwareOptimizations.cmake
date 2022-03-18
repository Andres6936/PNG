MACRO(ENABLE_HARDWARE_OPTIMIZATIONS)
    MESSAGE(STATUS "Enable Hardware Optimizations")

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

ENDMACRO()

MACRO(DISABLE_HARDWARE_OPTIMIZATIONS)
    MESSAGE(STATUS "Disable Hardware Optimizations")

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

ENDMACRO()