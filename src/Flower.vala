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

using Granite.Services;
using Flower.Window;
using Flower.Services;

namespace Flower {

    /* Global Variables */
    public DBusManager dbus_manager;
    public PhotoManager photo_manager;
    private bool selection_mode;

    /* Settings Objects*/
    public SavedState state;
    public Preferences preferences;
    public DatabaseSettings database_settings;

    public class FlowerApp : Granite.Application {

        construct {
            program_name = Constants.APP_NAME;
            exec_name = Constants.EXEC_NAME;
            build_version = Constants.VERSION;

            app_years = "2015";
            app_icon = Constants.ICON_NAME;
            app_launcher = "model.desktop";
            application_id = "net.launchpad.model";

            about_authors = {"Sam Thomas <sgpthomas@gmail.com>"};
            about_license_type = Gtk.License.GPL_3_0;
            about_artists = {"Sam Thomas <sgpthomas@gmail.com>"};
            about_translators = "Launchpad Translators";
        }

        public MainWindow window;

        //constructor
        public FlowerApp () {
            /* Logger initilization */
            Logger.initialize (Constants.APP_NAME);
            Logger.DisplayLevel = LogLevel.DEBUG;

            /* Managers */
            dbus_manager = new DBusManager ();
            photo_manager = new PhotoManager ();
            state = new SavedState ();
            preferences = new Preferences ();
            database_settings = new DatabaseSettings ();

            /* Translation support */
            Intl.setlocale (LocaleCategory.ALL, "");
            string langpack_dir = Path.build_filename (Constants.DATADIR, "locale");
            Intl.bindtextdomain (Constants.GETTEXT_PACKAGE, langpack_dir);
            Intl.bind_textdomain_codeset (Constants.GETTEXT_PACKAGE, "UTF-8");
            Intl.textdomain (Constants.GETTEXT_PACKAGE);
        }

        public override void activate () {
            if (window == null) {
                window = new MainWindow ();
                //connect_signals ();
                Gtk.main ();
            } else {
                message ("There is an instance of flower already open.");
                window.present ();
            }
        }
    }

    public static void main(string[] args) {

        Gtk.init (ref args);

        FlowerApp app = new FlowerApp ();
        app.run (args);
    }
}
