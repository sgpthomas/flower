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

using GLib;

namespace Flower.Services {

    /* Client Class */
    [DBus (name = "net.launchpad.flower")]
    public interface Client : Object {
        public abstract void print_message (string msg) throws IOError;
        public signal void database_changed ();
    }

    public class DBusManager {

        public Client client; //client instance

        public DBusManager () {
            sync_server (); //try and connect to the server (daemon)
        }

        //private function to connect to the server (daemon)
        private void sync_server () {
            try {
                //sync client to server
                client = Bus.get_proxy_sync (BusType.SESSION, "net.launchpad.flower", "/net/launchpad/flower");

                client.print_message ("Flower Client Starting"); //send message to daemon

            } catch (IOError e) {
                error (e.message); //throw error if something is wrong with the syncing
            }
        }
    }
}
