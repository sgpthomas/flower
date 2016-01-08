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

using Sqlite;
using GLib;

using Flower.Daemon.Backends;

namespace Flower.Daemon {

    public class DatabaseManager {

        /* Sql Commands */
        private static string NEW_DATABASE = """
            CREATE TABLE Photos (
                id          INTEGER PRIMARY KEY AUTOINCREMENT,
                filepath    STRING,
                width       INTEGER,
                height      INTEGER,
                filesize    INTEGER,
                comment     STRING
            );
        """;

        private static string RESET_DATABASE = """
            DROP TABLE Photos;
        """;

        private string db_path;
        private Backend[] backends;

        private int refresh_rate; //in order to detect when timeout needs to be changed

        public DatabaseManager () {
            init_databases (); //init the databases

            init_backends (); //init the backends

            refresh_rate = db_settings.refresh_rate;

            //start searching
            init_search ();

            //refresh sources the first time this is created
            refresh_sources ();

            write_data ();

            connect_signals ();
        }

        private void init_databases () {
            //create the data directory if it doesn't exist already
            var data_dir_path = Path.build_filename (Environment.get_user_data_dir (), Constants.GETTEXT_PACKAGE);
            var data_dir = File.new_for_path (data_dir_path); //create file object from path
            var db_dir = File.new_for_path (Path.build_filename (data_dir_path, "data")); //db directory

            if (!data_dir.query_exists ()) { //if the directory doesn't exist
                try { //try to make the directory
                    message ("Creating Flower Data Directory");
                    data_dir.make_directory ();
                } catch (GLib.Error e) {
                    error (e.message); //yell if error
                }
            }

            if (!db_dir.query_exists ()) { //if the db directory doesn't exist
                try { //try to make the directory
                    message ("Creating Flower Database Directory");
                    db_dir.make_directory ();
                } catch (GLib.Error e) {
                    error (e.message); //yell if error
                }
            }

            message ("Initializing Flower Database"); //begin the database initialization
            var db_name = "flower.db";
            db_path = Path.build_filename (data_dir_path, "data", db_name); //create db path

            exec_sql_command (NEW_DATABASE); //create database object if it doesn't already exist
        }

        private void init_backends () {
            backends = {}; //init backend array

            backends += new LocalBackend ();
        }

        private void init_search () {
            Timeout.add (refresh_rate * 1000, refresh_sources);
        }

        public bool refresh_sources () {
            message ("Refreshed!");
            foreach (var b in backends) {
                b.refresh ();
            }

            if (db_settings.refresh_rate != refresh_rate) {
                refresh_rate = db_settings.refresh_rate;
                init_search ();
                return false;
            }

            return true;
        }

        public void write_data () {
            bool changed = false;

            /* write new data or update old data */
            Gee.ArrayList<string> all_paths = new Gee.ArrayList<string>();
            foreach (var b in backends) {
                DataEntry[] data = b.get_data_list (); //get data from backend

                foreach (var de in data) { //loop through data entries in data
                    var exists = exists_in_db (de); //check if data entry exists in the database
                    if (exists) { //if the file exists
                        if (!compare_to_db (de)) { //data entry is different than in database, update
                            update_entry (de); //update entry in database
                            changed = true;
                        }
                    } else { //if the file doesn't exist
                        insert_entry (de); //insert new entry
                        changed = true;
                        message ("Inserted %s %i %i %i", de.filepath, de.width, de.height, de.filesize);
                    }

                    if (!(de.filepath in all_paths)) {
                        all_paths.add (de.filepath);
                    }
                }
            }

            /* look for data to remove */
            var sql_string = "SELECT * FROM Photos;";
            //Open database
            Database db;
            var err = Database.open (db_path, out db);

            //check error code to see if opening was successful
            if (err != Sqlite.OK) {
                critical ("Error Opening Database");
                return;
            }

            //prepare statement
            Statement stmt;
            err = db.prepare_v2 (sql_string, sql_string.length, out stmt);
            if (err != Sqlite.OK) {
                critical ("Error creating statement");
                return;
            }

            string[] to_remove = {};
            while (stmt.step () == Sqlite.ROW) {
                var col = 1;
                if (!(stmt.column_text (col) in all_paths)) {
                    to_remove += stmt.column_text (col);
                }
            }

            stmt.reset ();

            foreach (string path in to_remove) {
                remove_entry (path);
                changed = true;
                message ("Removed %s from database", path);
            }

            if (changed) server.server.database_changed ();
        }

        private void connect_signals () {
            foreach (var b in backends) { //loop through the backends
                b.update_database.connect (write_data);
            }
        }

        private bool exists_in_db (DataEntry de) {
            var sql_string = "SELECT filepath FROM Photos WHERE filepath = '%s';".printf (de.filepath); //sql command
            //message (sql_string);

            //Init sql database
            Database db;
            var err = Database.open (db_path, out db); //creates the db object

            //check error code to see if opening was successful
            if (err != Sqlite.OK) {
                critical ("Error Opening Database");
                return false;
            }

            Statement stmt; //sql statement
            err = db.prepare_v2 (sql_string, sql_string.length, out stmt);
            if (err != Sqlite.OK) { //check for errors
                critical (db.errmsg ());
                return false;
            }

            return stmt.step () == Sqlite.ROW;
        }

        private bool compare_to_db (DataEntry de) {
            var sql_string = "SELECT * FROM Photos WHERE filepath='%s' AND width=%i AND height=%i AND filesize=%i;".printf (de.filepath, de.width, de.height, de.filesize); //sql command

            //Init sql database
            Database db;
            var err = Database.open (db_path, out db); //creates the db object

            //check error code to see if opening was successful
            if (err != Sqlite.OK) {
                critical ("Error Opening Database");
                return false;
            }

            Statement stmt; //sql statement
            err = db.prepare_v2 (sql_string, sql_string.length, out stmt); //prepare statement
            if (err != Sqlite.OK) { //check for errors
                critical (db.errmsg ());
                return false;
            }

            return stmt.step () == Sqlite.ROW;
        }

        private void update_entry (DataEntry de) {
            var sql_string = "UPDATE Photos SET filepath='%s', width=%i, height=%i, filesize=%i;".printf (de.filepath, de.width, de.height, de.filesize); //sql command

            exec_sql_command (sql_string, true);
        }

        private void insert_entry (DataEntry de) {
            var sql_string = "INSERT INTO Photos (filepath, width, height, filesize) VALUES ('%s', %i, %i, %i);".printf (de.filepath, de.width, de.height, de.filesize); //sql string

            exec_sql_command (sql_string, true); //execute sql command
        }

        private void remove_entry (string path) {
            var sql_string = "DELETE FROM Photos WHERE filepath='%s';".printf (path);

            exec_sql_command (sql_string, true);
        }

        public void reset_database () {
            message ("Dropping Photos Table");
            exec_sql_command (RESET_DATABASE, true);
            message ("Initializing Photos Table");
            exec_sql_command (NEW_DATABASE, true);
        }

        private void exec_sql_command (string command, bool print_err = false) {
            Database db; //sql database object
            var err = Database.open (db_path, out db); //creates db object

            //check error code to see if database successfully opened
            if (err != Sqlite.OK) {
                critical ("Error Opening Database");
                return;
            }

            //execute command
            string errmsg;
            err = db.exec (command, null, out errmsg);
            if (print_err && err != Sqlite.OK) { //if should print errors, print errors
                critical (errmsg);
            }

        }
    }
}
