RCol='\033[0m' # Text Reset
Cya='\033[1;34m' #Cyan

name="Flower"

cd build
{
    cmake -DCMAKE_INSTALL_PREFIX=/usr ../ > /dev/null
    make > /dev/null
    sudo make install > /dev/null
} &

pid=$!

#if this script is killed, kill the background process as well
trap "kill $pid 2> /dev/null" EXIT

echo -n "${Cya}Building and Installing ${name}${RCol}"
while kill -0 $pid 2> /dev/null; do
    echo -n "${Cya}.${Cya}"
    sleep 0.2
done

echo -e "\r\033[K${Cya}Finished building and installing ${name}${RCol}"
