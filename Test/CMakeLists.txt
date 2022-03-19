
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

    CONFIGURE_FILE("${PNG_SOURCE_DIR}/Scripts/test.cmake.in"
            "${PNG_BINARY_DIR}/tests/${_PAT_NAME}.cmake"
            @ONLY)
    ADD_TEST(NAME "${_PAT_NAME}"
            COMMAND "${CMAKE_COMMAND}"
            "-DLIBPNG=$<TARGET_FILE:Png.Framework>"
            "-DTEST_COMMAND=$<TARGET_FILE:${_PAT_COMMAND}>"
            -P "${PNG_BINARY_DIR}/tests/${_PAT_NAME}.cmake")
ENDFUNCTION()

IF (PNG_TESTS AND PNG_SHARED)
    # Find test PNG files by globbing, but sort lists to ensure
    # consistency between different filesystems.
    FILE(GLOB PNGSUITE_PNGS "${PNG_SOURCE_DIR}/contrib/pngsuite/*.png")
    LIST(SORT PNGSUITE_PNGS)
    FILE(GLOB TEST_PNGS "${PNG_SOURCE_DIR}/contrib/testpngs/*.png")
    LIST(SORT TEST_PNGS)

    SET(PNGTEST_PNG "${PNG_SOURCE_DIR}/pngtest.png")

    ADD_EXECUTABLE(pngtest ${PNG_SOURCE_DIR}/Test/pngtest.c)
    TARGET_LINK_LIBRARIES(pngtest Png.Framework)

    PNG_ADD_TEST(NAME pngtest
            COMMAND pngtest
            FILES "${PNGTEST_PNG}")

    ADD_EXECUTABLE(pngvalid ${PNG_SOURCE_DIR}/contrib/libtests/pngvalid.c)
    TARGET_LINK_LIBRARIES(pngvalid Png.Framework)

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

    ADD_EXECUTABLE(pngstest ${PNG_SOURCE_DIR}/contrib/libtests/pngstest.c)
    TARGET_LINK_LIBRARIES(pngstest Png.Framework)

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

    ADD_EXECUTABLE(pngunknown ${PNG_SOURCE_DIR}/contrib/libtests/pngunknown.c)
    TARGET_LINK_LIBRARIES(pngunknown Png.Framework)

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

    ADD_EXECUTABLE(pngimage ${PNG_SOURCE_DIR}/contrib/libtests/pngimage.c)
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