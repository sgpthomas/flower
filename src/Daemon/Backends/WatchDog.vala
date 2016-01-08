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

namespace Flower.Daemon.Backends {

    public class WatchDog : GLib.Object {

        public File watched_folder; //the file object that the watch dog will keep an eye on

        public Gee.HashMap<string, FileInfo> map; //photos of some sort

        public signal void folder_changed ();

        private string black_list = "x-xcf vnd.adobe.photoshop";

        public WatchDog (string path) {

            watched_folder = File.new_for_path (path); //create file object
            if (!watched_folder.query_exists ()) { //if the path is wrong
                watched_folder = null; //set the file object to null
            }

            map = new Gee.HashMap<string, FileInfo>(); //create map object
        }

        private bool look_for_new () {
            File file = watched_folder;
        	MainLoop loop = new MainLoop ();

            var count = 0; //count of new pictures discovered

            //if the folder doesn't exist, don't bother checking
            if (file == null) {
                message ("%s doesn't exist.", file.get_path ());
                return false;
            }

        	file.enumerate_children_async.begin ("standard::*", FileQueryInfoFlags.NOFOLLOW_SYMLINKS, Priority.DEFAULT, null, (obj, res) => {
        		try {
        			FileEnumerator enumerator = file.enumerate_children_async.end (res); //create async file enumerator
        			FileInfo info; //file info object
        			while ((info = enumerator.next_file (null)) != null) { //loop through files provided by enumerator
                        if (info.get_content_type ().split ("/")[0] == "image") { //if the mimetype is an image
                            if (!(info.get_content_type ().split ("/")[1] in black_list)) {
                                if (map.get (info.get_name ()) == null) { //if info is not already in the map, add it?
                                    map.set (info.get_name (), info);
                                    count += 1;
                                    //message ("%s", info.get_name ());
                                }
                            }        
                        }
        			}

                    message ("Images Found: %i", count);

        		} catch (GLib.Error e) {
        			error ("Error: %s\n", e.message);
        		}

        		loop.quit ();
        	});

        	loop.run ();

            if (count > 0) { //if count is greater than zero
                return true; //then return true
            }

            return false; //else return false
        }

        //this uses the map generated in *look_for_new* so this won't do anything if run before that
        private bool look_for_missing () {
            var iter = map.map_iterator (); //get map iterator object
            string[] to_remove = {}; //keys to removes

            while (iter.has_next ()) { //while iter has another object
                iter.next (); //move to next object
                var key = iter.get_key (); //gets the current key (path)
                var file = File.new_for_path (Path.build_filename (watched_folder.get_path (), key)); //file object representing path

                if (!file.query_exists ()) { //if file doesn't exist
                    message ("Removing %s", key);
                    to_remove += key; //mark them to be removed
                }
            }

            foreach (var key in to_remove) { //loop through keys to remove
                map.unset (key); //remove them
            }

            message ("Images Removed: %i", to_remove.length);

            if (to_remove.length > 0) {
                return true;
            }

            return false;
        }

        public void update_map () {
            var a = look_for_new ();
            var b = look_for_missing ();

            if (a || b) {
                folder_changed ();
            }
        }
    }
}
