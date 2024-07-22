#!/bin/bash

XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}

if [ -d "/opt/system/Tools/PortMaster/" ]; then
  controlfolder="/opt/system/Tools/PortMaster"
elif [ -d "/opt/tools/PortMaster/" ]; then
  controlfolder="/opt/tools/PortMaster"
elif [ -d "$XDG_DATA_HOME/PortMaster/" ]; then
  controlfolder="$XDG_DATA_HOME/PortMaster"
else
  controlfolder="/roms/ports/PortMaster"
fi

source $controlfolder/control.txt
source $controlfolder/device_info.txt
export PORT_32BIT="Y"
[ -f "${controlfolder}/mod_${CFW_NAME}.txt" ] && source "${controlfolder}/mod_${CFW_NAME}.txt"
get_controls

$ESUDO chmod 666 /dev/tty0

GAMEDIR="/$directory/ports/sonictimetwisted"

export LD_LIBRARY_PATH="/usr/lib32:$GAMEDIR/libs:$GAMEDIR/utils/libs":$LD_LIBRARY_PATH
export GMLOADER_DEPTH_DISABLE=1
export GMLOADER_SAVEDIR="$GAMEDIR/gamedata/"
export GMLOADER_PLATFORM="os_linux"

cd "$GAMEDIR"
> "$GAMEDIR/log.txt" && exec > >(tee "$GAMEDIR/log.txt") 2>&1

printf "\033c" > /dev/tty0
install() {
    $ESUDO mkdir -p tmp/
    $ESUDO utils/unzip "sonictimetwisted-1.1.2-windows.zip" -d tmp/ || return 1
    $ESUDO rm -rf tmp/*.exe tmp/*.dll tmp/options.ini tmp/gamecontrollerdb.txt
    mv tmp/translations ./gamedata/translations
    mv tmp/data.win ./gamedata/game.droid
    mv tmp/translations.txt ./gamedata/translations.txt
    cd tmp
    mkdir assets/
    mv *.ogg assets/
    $ESUDO ../utils/zip -r -0 ../game.apk * || return 1
    cd $GAMEDIR
    $ESUDO rm -r tmp *.zip
    touch installed
}

if [ ! -f installed ]; then
    echo "Performing first-time setup, please wait..." > /dev/tty0
    install
    if [ $? -ne 0 ]; then
        echo "An error occurred during the installation process. Exiting." > /dev/tty0
        exit 1
    fi
fi

$GPTOKEYB "gmloader" -c "sonic.gptk" &
echo "Loading, please wait... " > /dev/tty0

$ESUDO chmod +x "$GAMEDIR/gmloader"

./gmloader game.apk

$ESUDO kill -9 "$(pidof gptokeyb)"
$ESUDO systemctl restart oga_events &
printf "\033c" >> /dev/tty1
printf "\033c" > /dev/tty0