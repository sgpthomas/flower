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

using Flower.Daemon.Backends;

namespace Flower.Daemon {

    public DBusServer server; //server instance
    public DatabaseManager db_manager; //database manager
    public DatabaseSettings db_settings; //settings instance

    public class Daemon : GLib.Application {

        public Daemon () {
            Object (application_id: "net.launchpad.flower", flags: ApplicationFlags.NON_UNIQUE);
            set_inactivity_timeout (1000);
        }

        ~Daemon () {
            release ();
        }

        /* Startup */
        public override void startup () {
            message ("flower-daemon has started");
            base.startup ();

            db_settings = new DatabaseSettings (); //create the settings object
            server = new DBusServer (); //create dbus server
            db_manager = new DatabaseManager (); //create the database manager

            hold ();
        }

        /* Activation Phase */
        /*  Empty function  */
        public override void activate () {
            message ("flower-daemon has activated");
        }

        /* On DBUS register */
        public override bool dbus_register (DBusConnection connection, string object_path) throws Error {
            return true;
        }
    }

    /* called when application is run */
    /* starts daemon */
    public static int main (string[] args) {
        var daemon = new Daemon (); //instantiate daemon

        //attempt to register application
        try {
            daemon.register ();
        } catch (GLib.Error e) { //if there is an error
            error ("Was unable to register flower-daemon"); //throw error
        }

        //run daemon and return result
        return daemon.run (args);
    }

}
