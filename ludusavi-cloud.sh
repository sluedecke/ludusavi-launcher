#!/bin/sh

# This file comes without warranty, use at your own risk!
#
# License: MIT License
# Author: Sascha Lüdecke <sascha@meta-x.de>
#
# Version: 0.1 - 2022-09-27

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
LOGFILE=$SCRIPT_DIR/ludusavi-cloud.log
GAMENAME=`head -1 "$3/gameinfo"`

# Linux installation
LUDUSAVI=/usr/bin/ludusavi

# Path on steam deck if installed via flatpack
if [ $USER == deck ]
then
    LUDUSAVI=/home/.steamos/offload/var/lib/flatpak/exports/bin/com.github.mtkennerly.ludusavi
fi

{
    echo ==================================================
    echo
    echo Gamename is: $GAMENAME
    
    # restore savegame
    echo Restore savegame
    echo $LUDUSAVI restore --force "$GAMENAME"
    $LUDUSAVI restore --force "$GAMENAME"
    
    # run game
    echo Game run command:
    echo $@
    "$@"
    
    # backup savegame
    echo Backup savegame
    echo $LUDUSAVI backup --merge --force "$GAMENAME"
    $LUDUSAVI backup --merge --force "$GAMENAME"

    echo
    echo ==================================================
} >> $LOGFILE 2>&1
