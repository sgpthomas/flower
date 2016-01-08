/* Copyright 2015 Sam Thomas
*
* This file is part of Flower.
*
* Flower is free software: you can redistribute it
* and/or modify it under the terms of the GNU General Public License as
* published by the Free Software Foundation, either version 3 of the
* License, or (at your option) any later version.
*
* Flower is distributed in the hope that it will be
* useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
* Public License for more details.
*
* You should have received a copy of the GNU General Public License along
* with Flower. If not, see http://www.gnu.org/licenses/.
*/

/* Exit function */
extern void exit (int exit_code);

namespace Flower.Daemon {

    /* Class where all of the dbus accessible functions reside */
    [DBus (name = "net.launchpad.flower")]
    public class Server : Object {

        public void print_message (string msg) {
            message (msg);
        }

        public void update () {
            db_manager.refresh_sources ();
        }

        public void write_data () {
            db_manager.write_data ();
        }

        public void reset_database () {
            db_manager.reset_database ();
        }

        public signal void database_changed ();
    }

    /* Error Class */
    [DBus (name = "net.launchpad.flower")]
    public errordomain Error {
        SOME_ERROR
    }

    /* Internal Abstraction of Flower Server */
    public class DBusServer {

        public Server server; //server Object

        public DBusServer () {

            server = new Server (); //create server object

            //attempt to register dbus name
            Bus.own_name (BusType.SESSION,
                      "net.launchpad.flower",
                      BusNameOwnerFlags.NONE,
                      (conn) => { on_bus_acquired (conn); },
                      (c, name) => { message ("%s was successfully registered!", name); },
                      () => { critical ("Could not aquire service name"); exit (-1); });
        }

        /* On bus acquired */
        private void on_bus_acquired (DBusConnection connection) {
            try {
                // start service and register it as dbus object
                connection.register_object ("/net/launchpad/flower", server);
            } catch (IOError e) {
                critical ("Could not register service: %s", e.message);
            }
        }
    }
}
