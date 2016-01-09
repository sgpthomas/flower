
Building and Installing
-----------------------

Dependencies
------------
In order to build and install flower, you need the following dependencies:

    libgtk-3-dev
    libgranite-dev
    libglib2.0-dev
    sqlite3

To install these (in Debian based systems), run the following command:
    `sudo apt-get install libgtk-3-dev libgranite-dev libglib2.0-dev sqlite3`


Install
-------
Run the following commands in succession in order to build and install flower

    mkdir build
    cd build
    cmake CMAKE_INSTALL_PREFIX=/usr ../
    make
    sudo make install #Installs app system wide. If you don't do this, you can run the app with 'src/flower'

    -- or --

    sudo ./build.sh #ignore any warning messages that appear


Uninstall
---------
In order to uninstall, run the following command:

    sudo make uninstall
