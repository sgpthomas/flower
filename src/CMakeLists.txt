#define app source files
set (APP_SOURCES
    Flower.vala
    Config.vala
)

#define app source files : core
set (APP_SOURCES ${APP_SOURCES}
    Core/Photo.vala
)

#define app source files : services
set (APP_SOURCES ${APP_SOURCES}
    Services/DBusManager.vala
    Services/PhotoManager.vala
    Services/Settings.vala
    Services/StyleManager.vala
)

#define app source files : window
set (APP_SOURCES ${APP_SOURCES}
    Window/MainWindow.vala
)

#define app source files : window/dialog
set (APP_SOURCES ${APP_SOURCES}
    Window/Dialog/ModifyDirectoryDialog.vala
    Window/Dialog/FolderChooser.vala
)

#define app source files : window/view
set (APP_SOURCES ${APP_SOURCES}
    Window/View/GenericView.vala
    Window/View/ListView.vala
    Window/View/PhotoView.vala
    Window/View/WelcomeView.vala
)


#compiling sources
vala_precompile (VALA_C model
    ${APP_SOURCES}

#packages to compile with model
PACKAGES
    ${SOURCE_DEPS}
OPTIONS
    #--thread
    --target-glib=2.32
)

#automatically generate .pot template files
set (_pot_file ${CMAKE_SOURCE_DIR}/po/${PROJECT_NAME}.pot)
add_custom_command (OUTPUT ${_pot_file}
    COMMAND xgettext --output=${_pot_file} ${APP_SOURCES}
    DEPENDS ${APP_SOURCES}
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    COMMENT "Extract translatable messages to ${_pot_file}")
add_custom_target (pot_file ALL DEPENDS ${_pot_file})

#make executable
add_executable(${EXEC_NAME} ${VALA_C})

#install binaries
install (TARGETS ${EXEC_NAME} RUNTIME DESTINATION bin)
