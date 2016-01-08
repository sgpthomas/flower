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

    public struct DataEntry {
        string filepath;
        int width;
        int height;
        int filesize;
        string? comment;
    }

    public interface Backend : Object {

        /* Methods */

        //returns a data entry structure
        public abstract DataEntry[] get_data_list ();

        //refreshes data
        public abstract void refresh ();

        //signal for updating database
        public abstract signal void update_database ();

    }
}
