#!/bin/bash

set -e

# https://developer.valvesoftware.com/wiki/SteamCMD#ulimit_Linux_startup_error
ulimit -n 2048

mkdir -p "${WORKDIR}/.steam/sdk32"

# fix permissions of the working directory so that our unprivileged user
# (by default the user name is 'l4d2') is the owner of it
chown -R ${USER_ID}:${GROUP_ID} "${WORKDIR}"

# if environment variable "VALIDATE" is set and not an empty string
# then we wll validate the L4D2 install (check what is downloaded to
# make sure it isn't corrupt)
if ! [ -z "${VALIDATE}" ]; then 
    VALIDATE="validate"
    echo "/entrypoint.sh: Validating Left 4 Dead 2 install before launch..."
fi

# if steamcmd hasn't been run yet, we'll run it real quick right now
if [ ! -d "${WORKDIR}/.steam/steamcmd" ]
then
    runuser -u ${USERNAME} -- steamcmd +quit
fi

set +e

# on some platforms, steamcmd runs out of memory when downloading
# game files. This forces it to retry up to 5 times.
# Usually once the initial download has finished, this is no longer an issue.
n=0
until [ "$n" -ge 5 ]; do
    # ensure latest L4D2 dedicated server is installed
    runuser -u ${USERNAME} -- steamcmd \
        +login anonymous \
        +force_install_dir "${WORKDIR}" \
        +app_update 222860 "${VALIDATE}" \
        +quit \
    && break || echo "/entrypoint.sh: Retrying update"
done

if [ "$n" -ge 5 ]; then
    echo "/entrypoint.sh: Failed to update."
    exit 1
fi

set -e

# https://developer.valvesoftware.com/wiki/SteamCMD#SteamCMD_startup_errors
ln -f -s "../steamcmd/linux32/steamclient.so" \
    "${WORKDIR}/.steam/sdk32/steamclient.so"


echo "Starting Left 4 Dead 2 server..."

# start the dedicated server with the arugments passed in from CMD
exec runuser -u ${USERNAME} -- "${WORKDIR}/srcds_run" "$@"
