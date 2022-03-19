ADD_EXECUTABLE(Png.Examples.Pixel pngpixel.c)
TARGET_LINK_LIBRARIES(Png.Examples.Pixel PRIVATE Png.Framework)

# Move the DLL in Windows for link the target with the dependencies
ADD_CUSTOM_COMMAND(TARGET Png.Examples.Pixel POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_directory
        ${ZLIB_BINARY_DIR}
        $<TARGET_FILE_DIR:Png.Framework>)