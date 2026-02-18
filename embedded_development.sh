sudo apt update
sudo apt install gcc-arm-none-eabi cmake ninja-build

cd $HOME
git clone https://github.com/raspberrypi/pico-sdk.git
cd pico-sdk
git submodule update --init


