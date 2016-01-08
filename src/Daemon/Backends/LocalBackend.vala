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

    public class LocalBackend : Object, Backend {

        private WatchDog[] dogs; //pack of dogs
        private string[] photo_dirs; //directories to search for photos

        public LocalBackend () {
            photo_dirs = db_settings.photo_directories; //get photo dirs from dconf

            //release watch dogs
            init_watch_dogs ();

            //connect those dank signals
            connect_signals ();
        }

        private void init_watch_dogs () {
            dogs = {}; //init dogs list

            foreach (var str_path in photo_dirs) { //loop through all directories in settings
                if ("~" in str_path) { //if '~' is found
                    str_path = str_path.replace ("~", Environment.get_home_dir ()); //replace with abs home dir
                }

                dogs += new WatchDog (str_path); //create a new watch dog from that path
            }
        }

        private void connect_signals () {
            db_settings.changed.connect (() => {
                //convert vala arrays to gee arrays for easier manipulation
                Gee.ArrayList<string> dirs = new Gee.ArrayList<string>.wrap(photo_dirs);
                Gee.ArrayList<string> diff = new Gee.ArrayList<string>.wrap(db_settings.photo_directories);
                //Gee.ArrayList<string> dirs = new Gee.ArrayList<string>.wrap(a);
                //Gee.ArrayList<string> diff = new Gee.ArrayList<string>.wrap(b);

                //loop through directories currently saved in the program
                foreach (var s in dirs) {
                    if (diff.contains (s)) { //if s is also in gsettings
                        diff.remove (s); //remove it from the gsettings array
                    } else { //otherwise, the current item is not in the diff array
                        //dirs.remove (s);
                        diff.add (s); //so add it to the diff array
                    }
                }

                //convert all relative paths in diff to absolute paths
                for (var i = 0; i < diff.size; i++) {
                    if ("~" in diff[i]) { //if '~' is found
                        diff[i] = diff[i].replace ("~", Environment.get_home_dir ()); //replace with abs home dir
                    }
                }

                var tmp_dogs = new Gee.ArrayList<WatchDog>.wrap (dogs); //representation of dog array to easily remove items
                bool refr = false;
                foreach (string path in diff) { //loop through strings in the difference array
                    //message (path);
                    bool add = true;
                    foreach (var dog in dogs) { //loop through dogs, (note that its dogs, not tmp_dogs)
                        if (path == dog.watched_folder.get_path ()) { //compare path to dog
                            message ("Removing Photos in %s", path);
                            tmp_dogs.remove (dog);
                            add = false;
                            refr = true;
                            break;
                        }
                    } if (add) {
                        message ("Adding Photos in %s", path);
                        tmp_dogs.add (new WatchDog (path));
                        refr = true;
                    }
                }
                dogs = tmp_dogs.to_array ();

                photo_dirs = db_settings.photo_directories;

                if (refr) {
                    message ("changed");
                    refresh ();
                    update_database (); //fire signal to update database
                }
            });
        }

        /* Interface Methods */
        public DataEntry[] get_data_list () {
            DataEntry[] data = {}; //data array

            foreach (var dog in dogs) {
                var iter = dog.map.map_iterator (); //create iteration object

                while (iter.next ()) {
                    var key = iter.get_key (); //path item found by dog

                    var filename = Path.build_filename (dog.watched_folder.get_path (), key); //create filename
                    var width = -1;
                    var height = -1;

                    try {
                        var pixbuf = new Gdk.Pixbuf.from_file (filename); //pixbuf to get picture size
                        width = pixbuf.width;
                        height = pixbuf.height;
                    } catch (GLib.Error e) {
                        critical ("Couldn't read size from %s", filename);
                    }

                    //create and populate a data entry
                    DataEntry entry = DataEntry ();
                    entry.filepath = filename;
                    entry.width = width;
                    entry.height = height;
                    entry.filesize = (int) dog.map.get (key).get_size ();
                    entry.comment = null;

                    //add entry to data list
                    data += entry;
                }
            }

            return data;
        }

        public void refresh () {
            foreach (var dog in dogs) {
                dog.update_map ();
            }
        }
    }
}
