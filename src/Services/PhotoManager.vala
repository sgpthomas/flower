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

using Flower.Core;

namespace Flower.Services {

    public class PhotoManager : GLib.Object {

        private string db_path;

        //private PhotoDetail[] photo_details;

        public PhotoManager () {
            var db_name = "flower.db";
            var data_dir_path = Path.build_filename (Environment.get_user_data_dir (), Constants.GETTEXT_PACKAGE);
            db_path = Path.build_filename (data_dir_path, "data", db_name); //create db path
        }

        public PhotoDetail[] read_data () {
            var sql_string = "SELECT * FROM Photos";
            PhotoDetail[] photo_details = {};

            //init db database
            Database db;
            var err = Database.open (db_path, out db);
            if (err != Sqlite.OK) {
                critical ("Unable to open database");
            }

            Statement stmt; //sqlite statement
            err = db.prepare_v2 (sql_string, sql_string.length, out stmt); //prepare statement
            if (err != Sqlite.OK) {
                critical ("Unable to create statement");
            }

            while (stmt.step () == Sqlite.ROW) {
                var det = PhotoDetail ();
                det.id = stmt.column_int (0);
                det.filepath = stmt.column_text (1);
                det.width = stmt.column_int (2);
                det.height = stmt.column_int (3);
                photo_details += det;
            }

            return photo_details;
        }
    }
}
