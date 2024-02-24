#!/bin/bash

set -e

# https://developer.valvesoftware.com/wiki/SteamCMD#ulimit_Linux_startup_error
ulimit -n 2048

if [ ! -d "${HOMEDIR}/.steam/sdk32" ]; then
    echo "[entrypoint.sh][WARNING] ${HOMEDIR}/.steam/sdk32 not exist, creating..."
    mkdir -p "${HOMEDIR}/.steam/sdk32"
fi

# fix permissions of the working directory so that our unprivileged user
# (by default the user name is 'l4d2') is the owner of it
echo "[entrypoint.sh][INFO] Setting ${WORKDIR}'s permissions..."
chown -R "${USER_ID}:${GROUP_ID}" "${WORKDIR}"

# if environment variable "VALIDATE" is set and not an empty string
# then we wll validate the L4D2 install (check what is downloaded to
# make sure it isn't corrupt)
if [ -n "${VALIDATE}" ]; then
    VALIDATE="validate"
    echo "[entrypoint.sh][INFO] Validating Left 4 Dead 2 Dedicated Server install before launch..."
fi

# if steamcmd hasn't been run yet, we'll run it real quick right now
if [ ! -d "${HOMEDIR}/.steam/steamcmd" ]; then
    echo "[entrypoint.sh][INFO] Initializing SteamCMD..."
    steamcmd +quit
fi

set +e

# on some platforms, steamcmd runs out of memory when downloading
# game files. This forces it to retry up to 5 times.
# Usually once the initial download has finished, this is no longer an issue.
n=0
echo "[entrypoint.sh][INFO] Updating Left 4 Dead 2 Dedicated Server..."
until [ "$n" -ge 5 ]; do
    # Generating update script.
    cat <<EOF >"${HOMEDIR}/.upgrade.steamcmd"
force_install_dir ${WORKDIR}
login anonymous
app_update 222860 ${VALIDATE}
EOF
    # ensure latest L4D2 dedicated server is installed
    steamcmd +runscript "${HOMEDIR}/.upgrade.steamcmd" \
        +quit && break || echo "[entrypoint.sh][WARNING] Retrying update $n time"
    ((n++))
done

if [ "$n" -ge 5 ]; then
    echo "[entrypoint.sh][ERROR] Failed to update."
    exit 1
fi

set -e

# https://developer.valvesoftware.com/wiki/SteamCMD#SteamCMD_startup_errors
echo "[entrypoint.sh][INFO] Force making a softlink for steamclient.so..."
ln -sf "../steamcmd/linux32/steamclient.so" \
    "${HOMEDIR}/.steam/sdk32/steamclient.so"

echo "[entrypoint.sh][INFO] Starting Left 4 Dead 2 Dedicated Server..."

# start the dedicated server with the arugments passed in from CMD
"${WORKDIR}/srcds_run" "$@"

echo "[entrypoint.sh][INFO] Left 4 Dead 2 Dedicated Server stoped..."
