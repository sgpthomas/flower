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

namespace Flower.Daemon {

    public class DatabaseSettings : Granite.Services.Settings {

        //variables
        public int refresh_rate {get; set;}
        public string[] photo_directories {get; set;}

        //constructor
        public DatabaseSettings () {
            base ("net.launchpad.flower.database");
        }

    }
}
