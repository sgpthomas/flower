#define app source files
set (DAEMON_SOURCES
    Config.vala
    Daemon.vala
    DatabaseManager.vala
    DBusServer.vala
    Settings.vala
)

set (DAEMON_SOURCES ${DAEMON_SOURCES}
    Backends/Backend.vala
    Backends/LocalBackend.vala
    Backends/WatchDog.vala
)

#compiling sources
vala_precompile (VALA_C model
    ${DAEMON_SOURCES}

#packages to compile with model
PACKAGES
    ${DAEMON_DEPS}
)

#make executable
add_executable(${EXEC_NAME}-daemon ${VALA_C})

#install binaries
install (TARGETS ${EXEC_NAME}-daemon RUNTIME DESTINATION bin)
