IF (PNG_SHARED AND PNG_EXECUTABLES)
    ADD_EXECUTABLE(Png.Tool.Fix pngfix.c)
    TARGET_LINK_LIBRARIES(Png.Tool.Fix Png.Framework)


    ADD_EXECUTABLE(Png.Tool.Fix.ITXT png-fix-itxt.c)
    TARGET_LINK_LIBRARIES(Png.Tool.Fix.ITXT ZLib::Framework ${M_LIBRARY})
ENDIF ()