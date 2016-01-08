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

namespace Flower.Services {

    public class SavedState : Granite.Services.Settings {

        //variables
        public int width {get; set;}
        public int height {get; set;}
        //public int pos_x {get; set;}
        //public int pos_y {get; set;}

        //constructor
        public SavedState () {
            base ("net.launchpad.flower.saved");
        }
    }

    public class Preferences : Granite.Services.Settings {

        //variables
        public int spacing {get; set;}
        public int photos_per_row {get; set;}
        public int zoom_increment {get; set;}

        //constructor
        public Preferences () {
            base ("net.launchpad.flower.preferences");
        }
    }

    public class DatabaseSettings : Granite.Services.Settings {

        public string[] photo_directories {get; set;}

        public DatabaseSettings () {
            base ("net.launchpad.flower.database");
        }
    }
}
