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

using Gtk;

namespace Flower.Window.Dialog {

    public static void show_file_chooser (Gtk.Window? window=null) {
        //setup dialog
        var chooser = new FileChooserDialog (
            _("Select photo directories"), window,
            FileChooserAction.SELECT_FOLDER);

        chooser.add_button ("_Cancel", ResponseType.CANCEL);
        chooser.add_button ("_Select", ResponseType.ACCEPT).get_style_context ().add_class ("suggested-action");
        chooser.select_multiple = true;

        //TODO: filter folders
        var filter = new FileFilter ();
        chooser.set_filter (filter);
        filter.add_mime_type ("inode/directory");

        //setup signals
        chooser.response.connect ((type) => {
            if (type == ResponseType.ACCEPT) {
                var tmp_database_settings = database_settings.photo_directories;
                SList<GLib.File> locations = chooser.get_files ();
                foreach (unowned GLib.File file in locations) {
                    if (!(file.get_path () in tmp_database_settings)) {
                        tmp_database_settings += file.get_path ();
                    }
                }
                database_settings.photo_directories = tmp_database_settings;
            }

            chooser.destroy ();
        });

        //process response
        chooser.run ();
    }

    /*public class FolderChooser : Gtk.FileChooserDialog {

        //private Gtk.Window? window;

        public FolderChooser (Gtk.Window? window=null) {
            Object (title: "Folder Chooser", parent: window, action: FileChooserAction.SELECT_FOLDER);
            //this.window = window;

            //settings
            if (window != null) {
                this.set_transient_for (window);
            }

            this.set_resizable (false);
            this.set_deletable (false);
            this.set_modal (true);

            setup ();
        }

        private void setup () {
            //add buttons
            this.add_button ("_Cancel", ResponseType.CANCEL);
            this.add_button ("_Select", ResponseType.ACCEPT).get_style_context ().add_class ("suggested-action");
            this.select_multiple = true;

            //TODO: import filters
            /*var filter = new FileFilter ();
            chooser.set_filter (filter);
            filter.add_mime_type ("inode/directory");

            //setup signals
            this.response.connect ((type) => {
                if (type == ResponseType.ACCEPT) {
                    var tmp_database_settings = database_settings.photo_directories;
                    SList<GLib.File> locations = this.get_files ();
        			foreach (unowned GLib.File file in locations) {
                        if (!(file.get_path () in tmp_database_settings)) {
                            tmp_database_settings += file.get_path ();
                        }
        			}
                    database_settings.photo_directories = tmp_database_settings;
                }

                this.close ();
            });
        }
    }*/
}
