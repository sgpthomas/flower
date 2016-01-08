#install files needed for model
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/flower.desktop DESTINATION ${DATADIR}/applications)
install (DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/style/ DESTINATION ${PKG_DATADIR}/style)
#install (DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/icons/ DESTINATION ${DATADIR}/icons/hicolor)
#install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/flower.svg DESTINATION ${DATADIR}/pixmaps)
