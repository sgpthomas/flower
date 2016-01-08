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

namespace Flower.Window.View {

    public class WelcomeView : Gtk.Box, Flower.Window.View.GenericView {

        private MainWindow window;
        private Welcome welcome; //granite welcome view

        public WelcomeView (MainWindow window) {
            this.window = window;
            welcome = new Welcome (_("You don't have any photos!"), _("Select a photos directory."));

            welcome.append ("document-open", _("Add Directory"), _("Select a directory with photos."));
            welcome.expand = true;

            connect_signals ();

            this.add (welcome); //add welcome view to box
        }

        private void connect_signals () {
            welcome.activated.connect ((i) => {
                switch (i) {
                    case 0:
                        //new FolderChooser (window).run ();
                        Dialog.show_file_chooser ();
                        break;
                }
            });
        }

        public string get_id () {
            return "welcome-view";
        }

        public string get_display_name () {
            return _("Welcome");
        }
    }
}
