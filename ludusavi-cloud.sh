#!/bin/sh

# -- ABOUT --
#
# Wrapper script to use ludusavi for savegame backup / restoration.
#
# Assumes that $3 is the directory with the game install which contains the file
# `gameinfo`.
#
# This file comes without warranty, use at your own risk!
#
# License: MIT License
# Author: Sascha Lüdecke <sascha@meta-x.de>

# -- HISTORY --
#
# Version: 0.2 - 2022-09-29
#
# . use zenity to tell user that we back up / restore
#
# Version: 0.1 - 2022-09-27

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
LOGFILE=$SCRIPT_DIR/ludusavi-cloud.log
GAMENAME=`head -1 "$3/gameinfo"`

# Standard paths
LUDUSAVI=/usr/bin/ludusavi
ZENITY=/usr/bin/zenity
TEE=/usr/bin/tee

# Path on steam deck if installed via flatpack
if [ $USER == deck ]
then
    LUDUSAVI=/home/.steamos/offload/var/lib/flatpak/exports/bin/com.github.mtkennerly.ludusavi
fi

{
    echo ==================================================
    echo
    echo Gamename is: $GAMENAME
    echo Start time: `date`

    # restore savegame
    echo $LUDUSAVI restore --force "$GAMENAME"
    (
        echo "# Restoring savegame for $GAMENAME"
        # bypass STDOUT and explicitely redirect output to LOGFILE
        $LUDUSAVI restore --force "$GAMENAME" 1>&2 | $TEE -a $LOGFILE
    ) | $ZENITY --progress \
               --title="Savegame restore" \
               --no-cancel \
               --auto-close \
               --pulsate

    # run game
    echo Game run command:
    echo $@
    "$@"

    # backup savegame
    echo $LUDUSAVI backup --merge --force "$GAMENAME"
    (
        echo "# Backing up savegames for $GAMENAME"
        # bypass STDOUT and explicitely redirect output to LOGFILE
        $LUDUSAVI backup --merge --force "$GAMENAME" 1>&2 | $TEE -a $LOGFILE
    ) | $ZENITY --progress \
               --title="Savegame backup" \
               --no-cancel \
               --auto-close \
               --pulsate

    echo End time: `date`
    echo
    echo ==================================================
}  2>&1 | $TEE -a $LOGFILE
