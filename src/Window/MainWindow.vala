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
using Granite.Widgets;
using Flower.Window.Dialog;
using Flower.Window.View;
using Flower.Services;
using Flower.Core;

namespace Flower.Window {

    public class MainWindow : Gtk.Window {

        //Widgets
        private Stack main_stack;
        private Stack view_stack;
        private StackSwitcher stack_switcher;
        private HeaderBar headerbar;
        private AppMenu app_menu;
        private Gtk.MenuItem edit_directories;

        private Button back; //back button
        //private Scale zoom; //zoom slider

        //Views
        private GenericView[] views;
        private PhotoView photo_view;
        private WelcomeView welcome_view;

        private Revealer progress_revealer;
        private ProgressBar progress_bar;

        //signals
        public signal void loaded_views ();
        public signal void key_pressed (Gdk.EventKey event);

        //constructor
        public MainWindow () {
            //set some variables of gtk.window
            this.title = Constants.APP_NAME;
            //this.set_border_width (12);
            this.set_position (WindowPosition.CENTER);
            this.set_size_request (1080, 700);
            this.set_default_size (state.width, state.height);
            this.destroy.connect (Gtk.main_quit);
            Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = true;

            //initialize style sheet
            StyleManager.add_stylesheet ("style/photo.css");

            //Stack switcher
            view_stack = new Stack (); //create stack object
            view_stack.set_transition_type (StackTransitionType.SLIDE_LEFT_RIGHT);
            stack_switcher = new StackSwitcher (); //create stack switcher
            stack_switcher.set_stack (view_stack); //assign stack to stack switcher
            stack_switcher.set_halign (Align.CENTER); //center the stack switcher

            main_stack = new Stack ();
            main_stack.set_transition_type (StackTransitionType.SLIDE_LEFT_RIGHT);

            //populate views array
            views = {};
            views += new ListView (this);

            photo_view = new PhotoView (this, null);
            welcome_view = new WelcomeView (this);

            setup_app_menu ();

            setup_headerbar ();

            setup_layout ();

            connect_signals ();

            show_all ();

            main_stack.set_visible_child_name ("view-stack");

            loaded_views ();
        }

        private void setup_app_menu () {
            var menu = new Gtk.Menu (); //create menu object
            edit_directories = new Gtk.MenuItem.with_label (_("Edit Photo Directories") + "…");
            menu.append (edit_directories);
            app_menu = new AppMenu (menu);
        }

        private void setup_headerbar () {
            headerbar = new HeaderBar (); //create headerbar
            headerbar.set_show_close_button (true); //show close button
            this.set_titlebar (headerbar); //set titlebar of this window to headerbar
            headerbar.spacing = 6;
            headerbar.set_custom_title (stack_switcher);
            headerbar.pack_end (app_menu);

            var left_box = new Box (Orientation.HORIZONTAL, 6);
            left_box.expand = true;

            back = new Button.with_label (_("Back"));
            back.set_tooltip_text (_("Back"));
            back.get_style_context ().add_class ("back-button");
            back.valign = Align.CENTER;
            left_box.pack_start (back, false, false, 0);

            /*zoom = new Scale.with_range (Orientation.HORIZONTAL, 0.0, 100.0, 1.0);
            zoom.draw_value = true;
            zoom.set_value_pos (PositionType.RIGHT);
            zoom.valign = Align.CENTER;
            zoom.hexpand = true;
            left_box.pack_start (zoom);*/

            headerbar.pack_start (left_box);
        }

        private void setup_layout () {
            //loop through views array
            foreach (var v in views) {
                view_stack.add_titled (v, v.get_id (), v.get_display_name ());
            }

            main_stack.add_named (welcome_view, welcome_view.get_id ());
            main_stack.add_named (view_stack, "view-stack");
            main_stack.add_named (photo_view, photo_view.get_id ());

            var main_box = new Box (Orientation.VERTICAL, 0);
            main_box.pack_start (main_stack, true, true, 0);

            progress_revealer = new Revealer ();
            progress_bar = new ProgressBar ();
            progress_bar.set_text (_("Importing Photos"));
            progress_bar.set_show_text (true);
            progress_revealer.add (progress_bar);
            progress_revealer.set_transition_type (RevealerTransitionType.SLIDE_UP);

            Timeout.add (500, () => {
                progress_bar.pulse ();
                return true;
            });

            main_box.pack_end (progress_revealer, false, false, 0);

            this.add (main_box);
        }

        public void show_image (PhotoDetail detail) {
            photo_view.set_photo (detail);
            main_stack.set_visible_child_name (photo_view.get_id ());
        }

        public void show_next_image () {
            var v = (ListView) views[0];
            if (v.has_next_image ()) {
                v.show_next_image ();
            }
        }

        public void show_previous_image () {
            var v = (ListView) views[0];
            if (v.has_previous_image ()) {
                v.show_previous_image ();
            }
        }

        public void show_welcome () {
            main_stack.set_visible_child_name (welcome_view.get_id ());
        }

        public void show_photos () {
            main_stack.set_visible_child_name ("view-stack");
        }

        private void connect_signals () {
            this.configure_event.connect ((e) => {
                state.width = e.width;
                state.height = e.height;
                return false;
            });

            main_stack.notify["visible-child"].connect ((s) => {
                if (main_stack.get_visible_child_name () == photo_view.get_id ()) {
                    back.show ();
                } else {
                    back.hide ();
                }
            });

            back.clicked.connect (() => {
                main_stack.set_visible_child_name ("view-stack");
            });

            edit_directories.activate.connect (() => {
                new ModifyDirectoryDialog (this).run ();
            });

            dbus_manager.client.database_changed.connect ((id) => {
                ChangeEvent e = (ChangeEvent) id;
                message (e.to_string ());

                switch (id) {
                    case ChangeEvent.START_ADD:
                        progress_revealer.set_reveal_child (true);
                        progress_bar.set_text (_("Importing Photos"));
                        break;

                    case ChangeEvent.ADD:
                        progress_bar.pulse ();
                        break;

                    case ChangeEvent.END_ADD:
                        progress_revealer.set_reveal_child (false);
                        var v = (ListView) views[0];
                        v.update ();
                        break;

                    case ChangeEvent.START_REMOVE:
                        progress_revealer.set_reveal_child (true);
                        progress_bar.set_text (_("Removing Photos"));

                        message (database_settings.photo_directories.length.to_string ());
                        message ((database_settings.photo_directories.length > 0).to_string ());
                        if (database_settings.photo_directories.length > 0) {
                            if (main_stack.get_visible_child_name () != "view-stack") {
                                main_stack.set_visible_child_name ("view-stack");
                            }
                        } else {
                            main_stack.set_visible_child_name (welcome_view.get_name ());
                        }

                        break;

                    case ChangeEvent.REMOVE:
                        progress_bar.pulse ();
                        break;

                    case ChangeEvent.END_REMOVE:
                        progress_revealer.set_reveal_child (false);
                        var v = (ListView) views[0];
                        v.update ();
                        break;

                    //case ChangeEvent.GENERIC:
                    //    var v = (ListView) views[0];
                    //    v.update ();
                    //    break;
                }


            });

            this.key_press_event.connect ((key) => {

                if (key.keyval == Gdk.Key.Escape) {
                    ((ListView) views[0]).clear_selected ();
                    selection_mode = false;
                }

                key_pressed (key);
                return false;
            });

            this.button_press_event.connect ((button) => {
                ((ListView) views[0]).clear_selected ();
                return false;
            });
        }

        public int get_height () {
            int height;
            int width;
            this.get_size (out width, out height);
            return height;
        }

        public int get_width () {
            int height;
            int width;
            this.get_size (out width, out height);
            return width;
        }
    }
}
