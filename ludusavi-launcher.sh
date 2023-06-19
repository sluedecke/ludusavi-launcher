#!/bin/bash

# -- ABOUT --
#
# Wrapper script to use ludusavi for savegame backup/restoration.
#
# Assumes that $5 is the directory with the game install which contains the file
# `gameinfo`.
#
# This file comes without warranty, use at your own risk!
#
# License: MIT License
# Author: Sascha Lüdecke <sascha@meta-x.de>

# -- BUGS/TODO --
#
# - does not work if mangohud and/or gamemode is used
# - error checking if backup/restore or game fails

# -- HISTORY --
#
# Version: 0.3 - 2023-06-17
#
# - search for gogdl in parameter list to handle calls with mangohud and alike
# - adapted to gogdl parameter list
#
# Version: 0.2 - 2022-09-29
#
# . use zenity to tell user that we back up / restore
#
# Version: 0.1 - 2022-09-27


SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
LOGFILE=$SCRIPT_DIR/ludusavi-launcher.log

# Standard paths
## LUDUSAVI=/usr/bin/ludusavi
LUDUSAVI=$HOME/Projekte/contributing/ludusavi/target/debug/ludusavi
ZENITY=/usr/bin/zenity
TEE=/usr/bin/tee
JQ=/usr/bin/jq
HEAD=/usr/bin/head
DATE=/usr/bin/date
ECHO=/usr/bin/echo

# Path on steam deck if installed via flatpack
if [ $USER == deck ]
then
    LUDUSAVI=/home/.steamos/offload/var/lib/flatpak/exports/bin/com.github.mtkennerly.ludusavi
fi

{
    #
    # determine game name and id from positional parameters
    #
    found=0
    pos=0
    for x
    do
        pos=$(( $pos+1 ))
        $ECHO x: $pos - $x
        if [ "`basename -- \"$x\"`" == "gogdl" ]
        then
            $ECHO gogdl found at position $pos
            found=1
            break
        fi
    done


    $ECHO pos is: $pos, found: $found
    GAME_DIR=""
    GAME_ID=""

    if [ $found == 1 ]
    then
        X=("$@")
        GAME_DIR="${X[ $(( $pos+3 ))]}"
        GAME_ID=${X[ $(( $pos+4 ))]}
        $ECHO GAME_DIR: $GAME_DIR
        $ECHO GAME_ID: $GAME_ID
    else
        $ECHO No gogdl found, doing nothing.
        exit 1
    fi


    #
    # Restoring, launching, backup
    #

    GAMENAME=""
    if [ -r "$GAME_DIR/gameinfo" ]
    then
        GAMENAME=`$HEAD -1 "$GAME_DIR/gameinfo"`
    else
        GAMENAME=`$JQ -r .name "$GAME_DIR/goggame-$GAME_ID.info"`
    fi



    $ECHO ==================================================
    $ECHO
    $ECHO Gamename is: $GAMENAME
    $ECHO Start time: `$DATE`
    $ECHO Parameters: $@
    
    # restore savegame
    $ECHO $LUDUSAVI restore --force "$GAMENAME"
    (
        $ECHO "# Restoring savegame for $GAMENAME"
        # bypass STDOUT 
        $LUDUSAVI restore --force "$GAMENAME" 1>&2
    ) | $ZENITY --progress \
                --title="Savegame restore" \
                --no-cancel \
                --auto-close \
                --pulsate

    # run game
    $ECHO Game run command:
    $ECHO $@
    "$@"

    # backup savegame
    $ECHO $LUDUSAVI backup --force "$GAMENAME"
    (
        $ECHO "# Backing up savegames for $GAMENAME"
        # bypass STDOUT
        $LUDUSAVI backup --force "$GAMENAME" 1>&2
    ) | $ZENITY --progress \
                --title="Savegame backup" \
                --no-cancel \
                --auto-close \
                --pulsate

    $ECHO End time: `$DATE`
    $ECHO
    $ECHO ==================================================
}  2>&1 | $TEE -a $LOGFILE
