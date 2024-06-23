#!/bin/bash

# Get user isn't exist
# Param: <User ID>
# Return: Bool
function Get-UserExist() {
    local uid=$1
    getent passwd | awk -F: -v uid="$uid" '$3 == uid {found=1; exit} END {exit !found}'
}

# Get group isn't exist
# Param: <Group ID>
# Return: Bool
function Get-GroupExist() {
    local gid=$1
    getent group | awk -F: -v gid="$gid" '$3 == gid {found=1; exit} END {exit !found}'
}

# Get user isn't exist
# Param: <User Name> <User ID> <Group ID>
# Return: Void
function New-User() {
    local username=$1
    local userid=$2
    local groupid=$2

    if [ -z "$username" ]; then
        echo "[entrypoint.sh][New-User][Error] Variable '$username' must be set."
        return 1
    fi

    if id -u "$username" >/dev/null 2>&1; then
        echo "[entrypoint.sh][New-User][Warn] User '$username' already exists."
        return
    fi

    if [ -n "$userid" ]; then
        if Get-UserExist "$userid"; then
            echo "[entrypoint.sh][New-User][Error] User ID '$userid' is already in use."
            return 1
        fi
        if Get-GroupExist "$groupid"; then
            echo "[entrypoint.sh][New-User][Error] Group ID '$groupid' is already in use."
            return 1
        fi

        groupadd -g "$groupid" "$username"
        useradd -u "$userid" -g "$groupid" -m "$username"
    else
        useradd -m "$username"
    fi

    if id -u "$username" >/dev/null 2>&1; then
        echo "[entrypoint.sh][New-User][Info] User '$userid($username)' created successfully."
    else
        echo "[entrypoint.sh][New-User][Error] Failed to create user '$username'."
        return 1
    fi
}

# Download Steam app
# Param: <Work dir> <App ID> <Validate: bool>
# Return: Void
function Invoke-SteamAppUpdate() {
    local workdir=$1
    local appid=$2
    if [ "$3" == "true" ]; then local validate="validate"; fi

    local command="/home/steam/steamcmd/steamcmd.sh +force_install_dir \"$workdir\" +login anonymous +app_update $appid $validate +quit"
    echo "[entrypoint.sh][Invoke-SteamAppUpdate][Info] Command: $command"
    su - "$USERNAME" -c "$command"
}

# Start Left 4 Dead 2 Dedicated Server
# Param: <Start arguments>
# Return: Void
function start() {
    if [ "$SKIP_UPDATE" == "false" ]; then
        echo "[entrypoint.sh][Info] Starting update Left 4 Dead 2 Dedicated Server..."
        updateTryCount=0
        while [ $updateTryCount -lt 3 ]; do
            if Invoke-SteamAppUpdate "$WORKDIR" 222860 "$VALIDATE"; then break; fi
    
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
    su - "$USERNAME" -c "$srcds_command"
    echo "[entrypoint.sh][Info] Left 4 Dead 2 Dedicated Server stoped..."
}

# Main
# Param: <Start arguments>
# Return: Void
function main() {
    if ! Get-UserExist "$UID"; then
        echo "[entrypoint.sh][Warn] User id \"$UID\" not exist, try create one..."
        USERNAME=${USERNAME_PREFEX}${UID}
        New-User "$USERNAME" "$UID" "$GID" || exit 1
    fi

    USERNAME=$(id -nu $UID)

    echo "[entrypoint.sh][Info] Setting \"$WORKDIR\"'s permissions..."
    chown -R "$UID:$GID" "$WORKDIR" || exit 1

    if [ "$AUTO_RESTART" == "true" ]; then
        while true; do
            start "$@"
        done
    else
        start "$@"
    fi
}

# https://developer.valvesoftware.com/wiki/SteamCMD#ulimit_Linux_startup_error
ulimit -n 2048
main "$@"
