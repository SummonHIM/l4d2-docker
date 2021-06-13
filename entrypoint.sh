#!/bin/sh

# if environment variable "VALIDATE" is set and not an empty string
# then we wll validate the L4D2 install (check what is downloaded to
# make sure it isn't corrupt)
if ! [ -z "${VALIDATE}" ]; then 
    VALIDATE="validate"
    echo "Validating Left 4 Dead 2 install before launch..."
fi

# ensure latest L4D2 dedicated server is installed
steamcmd +login anonymous +force_install_dir /srv/l4d2 \
    +app_update 222860 "${VALIDATE}" +quit

# start the dedicated server with the arugments past in from CMD
exec "${WORKDIR}/srcds_run" "$@"
