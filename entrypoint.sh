#!/bin/bash

# Download Steam app
# Param: <Work dir> <App ID> <Validate: bool>
# Return: Void
function steam_app_update() {
    local workdir=$1
    local appid=$2
    if [ "$3" == "true" ]; then local validate="validate"; fi

    if [ -n "$STEAM_USERNAME" ] && [ -n "$STEAM_PASSWORD_FILE" ]; then
        if [ -f "$STEAM_PASSWORD_FILE" ]; then
            STEAM_PASSWORD=$(cat "$STEAM_PASSWORD_FILE")
            local login="$STEAM_USERNAME $STEAM_PASSWORD"
        else
            echo "[entrypoint.sh][steam_app_update][Info] Password file not found. or the path is not a file."
            exit 1
        fi
    elif [ -n "$STEAM_USERNAME" ] && [ -n "$STEAM_PASSWORD" ]; then
        local login="$STEAM_USERNAME $STEAM_PASSWORD"
    else
        local login="anonymous"
    fi

    local command="$STEAMCMDDIR/steamcmd.sh +@sSteamCmdForcePlatformType linux +force_install_dir \"$workdir\" +login $login +app_update $appid $validate +quit"

    if [ "$login" = "anonymous" ]; then
        echo "[entrypoint.sh][steam_app_update][Info] Command: $command"
    fi

    $command
}

# Start Left 4 Dead 2 Dedicated Server
# Param: <Start arguments>
# Return: Void
function start() {
    if [ "$SKIP_UPDATE" == "false" ]; then
        echo "[entrypoint.sh][Info] Starting update Left 4 Dead 2 Dedicated Server..."
        updateTryCount=0
        while [ $updateTryCount -lt 3 ]; do
            steam_app_update "$WORKDIR" 222860 "$VALIDATE" && break

            updateTryCount=$((updateTryCount + 1))
            echo "[entrypoint.sh][Error] Update failed! Retrying $updateTryCount/3 times..."
            sleep 1

            if [ $updateTryCount -ge 3 ]; then
                echo "[entrypoint.sh][Error] Update failed!"
                exit 1
            fi
        done
        echo "[entrypoint.sh][Info] Left 4 Dead 2 Dedicated Server update successfully."
    fi

    echo "[entrypoint.sh][Info] Starting Left 4 Dead 2 Dedicated Server..."
    local srcds_command="$WORKDIR/srcds_run $*"
    echo "[entrypoint.sh][Info] Command: $srcds_command"
    $srcds_command
    echo "[entrypoint.sh][Info] Left 4 Dead 2 Dedicated Server stoped..."
}

# Main
# Param: <Start arguments>
# Return: Void
function main() {
    if [ "$AUTO_RESTART" == "true" ]; then
        while true; do
            start "$@" || exit $?
        done
    else
        start "$@" || exit $?
    fi
}

# https://developer.valvesoftware.com/wiki/SteamCMD#ulimit_Linux_startup_error
ulimit -n 2048
main "$@"
