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
using Gdk;

namespace Flower.Window.Dialog {

    public class ModifyDirectoryDialog : Gtk.Dialog {

        private Gtk.Window? window;

        private Stack stack; //stack
        //things in first stack
        private ScrolledWindow scrolled_window;
        private ListBox list_box;
        //things in second stack
        private Label label;

        private signal void changed ();

        public ModifyDirectoryDialog (Gtk.Window? window) {
            this.window = window;

            if (window != null) {
                this.set_transient_for (window);
            }

            this.set_size_request (450, 300);
            this.set_resizable (false);
            this.set_deletable (false);
            this.set_modal (true);

            setup_layout ();

            connect_signals ();

            show_all ();
        }

        private void setup_layout () {
            var content = this.get_content_area ();
            //var frame = new Frame (null);
            stack = new Stack ();

            scrolled_window = new ScrolledWindow (null, null);
            list_box = new ListBox ();
            list_box.expand = true;
            list_box.set_selection_mode (SelectionMode.NONE);
            scrolled_window.add (list_box);

            label = new Label (_("No Photo Directories"));
            label.get_style_context ().add_class ("no-photo-directories");
            label.expand = true;

            stack.add_named (scrolled_window, "list");
            stack.add_named (label, "none");
            content.add (stack);

            refresh ();

            //add action buttons
            this.add_button (_("Exit"), ResponseType.CANCEL);
            this.add_button (_("Add"), ResponseType.ACCEPT).get_style_context ().add_class ("suggested-action");
        }

        private void connect_signals () {
            this.response.connect ((type) => {
                if (type == ResponseType.CANCEL) {
                    this.close ();
                } else if (type == ResponseType.ACCEPT) {
                    Dialog.show_file_chooser ();
                    refresh ();
                }
            });

            this.changed.connect (() => {
                if (list_box.get_children ().length () > 0) {
                    stack.set_visible_child_name ("list");
                } else {
                    stack.set_visible_child_name ("none");
                }
            });
        }

        private void refresh () {
            foreach (Widget w in list_box.get_children ()) {
                w.destroy ();
            }

            foreach (string name in database_settings.photo_directories) {
                message (name);
                var row = new DirectoryRow (name);
                row.remove_row.connect ((i) => {
                    list_box.get_row_at_index (i).destroy ();
                    changed ();
                });
                list_box.prepend (row);
            }

            show_all ();
            changed ();
        }
    }

    private class DirectoryRow : Gtk.ListBoxRow {

        private string filename;
        private string icon_name;

        private EventBox event_box;
        private Box content;
        private Label label;
        private Button delete_button;
        private Image icon;

        public signal void remove_row (int index);

        public DirectoryRow (string filename, string icon_name = "folder") {
            this.filename = filename;
            this.icon_name = icon_name;

            setup_layout ();

            connect_signals ();
        }

        private void setup_layout () {
            //content widgets
            content = new Box (Orientation.HORIZONTAL, 0);

            icon = new Image.from_icon_name (icon_name, IconSize.BUTTON);

            label = new Label (filename);
            label.set_halign (Align.START);

            delete_button = new Button.from_icon_name ("process-stop-symbolic");
            delete_button.set_relief (ReliefStyle.NONE);
            delete_button.set_valign (Align.CENTER);

            //event catching
            event_box = new EventBox ();
            this.add_events (EventMask.POINTER_MOTION_MASK);

            content.pack_start (icon, false, false);
            content.pack_start (label, true, true);
            content.pack_end (delete_button, false, false);

            event_box.add (content);
            this.add (event_box);
        }

        private void connect_signals () {
            delete_button.event.connect ((e) => {
                if (e.type == EventType.ENTER_NOTIFY) {
                    delete_button.get_style_context ().add_class ("destructive-action");
                } else if (e.type == EventType.LEAVE_NOTIFY) {
                    delete_button.get_style_context ().remove_class ("destructive-action");
                }
                return false;
            });

            event_box.event.connect ((e) => {
                if (e.type == EventType.ENTER_NOTIFY) {
                    delete_button.get_style_context ().add_class ("destructive-action");
                } else if (e.type == EventType.LEAVE_NOTIFY) {
                    delete_button.get_style_context ().remove_class ("destructive-action");
                }

                return true;
            });

            delete_button.clicked.connect (() => {
                string[] tmp_database_settings = {};
                foreach (var name in database_settings.photo_directories) {
                    if (name != filename) {
                        tmp_database_settings += name;
                    }
                }
                database_settings.photo_directories = tmp_database_settings;
                this.remove_row (this.get_index ());
            });
        }
    }
}
