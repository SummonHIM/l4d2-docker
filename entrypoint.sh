#!/usr/bin/env bash
set -uo pipefail

# Get steam password
# Return: string of password
function get_steam_password() {
    local password=""

    if [[ -n "${STEAM_PASSWORD_FILE:-}" && -f "$STEAM_PASSWORD_FILE" ]]; then
        password="$(<"$STEAM_PASSWORD_FILE")"
        password="${password%%$'\n'}"
    elif [[ -n "${STEAM_PASSWORD:-}" ]]; then
        password="$STEAM_PASSWORD"
    else
        password=""
    fi

    printf '%s' "$password"
}


# Download Steam app
# Param: <Install dir> <App ID> <Validate: bool> <Platform type> <Steam username> <Steam password>
# Return: number of execution result
function steam_app_update() {
    local install_dir="$1"
    local appid="$2"
    local validate="$3"
    local platform_type="$4"
    local steam_username="$5"
    local steam_password="$6"

    # optional validate
    local validate_arg=""
    [[ $validate == "true" ]] && validate_arg="validate"

    # login args (array, no word splitting)
    local login_args=("anonymous")
    [[ -n $steam_username ]] && login_args=("$steam_username" "$steam_password")

    # build command safely
    local command=(
        "/usr/bin/steamcmd"
        "+@sSteamCmdForcePlatformType" "${platform_type:-linux}"
        "+force_install_dir" "$install_dir"
        "+login" "${login_args[@]}"
        "+app_update" "$appid" "$validate_arg"
        "+quit"
    )

    # log
    if [[ ${login_args[0]} == "anonymous" ]]; then
        echo "[entrypoint.sh][steam_app_update][INFO] Using anonymous login"
    else
        echo "[entrypoint.sh][steam_app_update][INFO] Using Steam account login"
    fi

    if [[ ${DEBUG:-} == "true" ]]; then
        echo "[entrypoint.sh][steam_app_update][DEBUG] Command:"
        printf '%b ' "${command[@]}"
        echo
    fi

    echo "[entrypoint.sh][steam_app_update][INFO] Running steamcmd..."
    if "${command[@]}"; then
        echo "[entrypoint.sh][steam_app_update][INFO] steamcmd finished successfully (appid=$appid)"
    else
        local rc=$?
        echo "[entrypoint.sh][steam_app_update][ERROR] steamcmd failed with exit code $rc (appid=$appid)" >&2
        return "$rc"
    fi
}

# Update Steam app with retry
# Param: none, all from system variables
function update_l4d2() {
    # Required system variables
    : "${WORKDIR:?WORKDIR not set}"

    local appid=222860  # L4D2
    local platform_type="${STEAM_PLATFORM_TYPE:-linux}"
    local validate="${STEAM_VALIDATE:-false}"
    local steam_username="${STEAM_USERNAME:-}"
    local steam_password
    steam_password="$(get_steam_password)"

    local try=0

    while (( try < 3 )); do
        echo "[entrypoint.sh][INFO] Running Steam update (attempt $((try+1))/3)..."

        if steam_app_update \
            "$WORKDIR" \
            "$appid" \
            "$validate" \
            "$platform_type" \
            "$steam_username" \
            "$steam_password"; then
            echo "[entrypoint.sh][INFO] Steam update finished successfully."
            return 0
        fi

        ((try++))
        echo "[entrypoint.sh][ERROR] Steam update failed (attempt $try/3). Retrying..."
        sleep 1
    done

    echo "[entrypoint.sh][ERROR] Steam update failed after 3 attempts. Exiting." >&2
    return 1
}


# Build startup parameters
# Return: string of startup parameters
function build_srcds_args() {
    local args=()

    while IFS='=' read -r name value; do
        case "$name" in
            ARGS_*)
                args+=("-${name#ARGS_}" "$value")
                ;;
            CVAR_*)
                args+=("+${name#CVAR_}" "$value")
                ;;
        esac
    done < <(env)

    printf '%s\0' "${args[@]}"
}

# Start Source Dedicated Server
# Param: <Start arguments>
function start_srcds() {
    local workdir="$1"; shift

    local srcds_command=(
        "$workdir/srcds_run"
        "$@"
    )

    if [[ ${DEBUG:-} == "true" ]]; then
        echo "[entrypoint.sh][DEBUG] srcds command:"
        printf '%q ' "${srcds_command[@]}"
        echo
    fi

    "${srcds_command[@]}"
}

# https://developer.valvesoftware.com/wiki/SteamCMD#ulimit_Linux_startup_error
ulimit -n 2048

# Build extra startup args from environment
mapfile -d '' -t extra_args < <(build_srcds_args)

# Add -debug if DEBUG=true
if [[ ${DEBUG:-} == "true" ]]; then
    extra_args+=("-debug")
fi

# Determine AUTO_RESTART behavior
auto_restart="${AUTO_RESTART:-internal}"

# Internal restart: let srcds handle it
if [[ "$auto_restart" == "internal" ]]; then
    # Update first (unless skipped)
    if [[ ${SKIP_UPDATE:-false} != "true" ]]; then
        update_l4d2 || exit 1
    fi

    echo "[entrypoint.sh][INFO] Starting srcds with internal restart handling..."
    start_srcds "$WORKDIR" "${extra_args[@]}" "$@"

# Script-managed restart: true or false
else
    # Add -norestart so srcds won't auto-restart
    extra_args+=("-norestart")

    while true; do
        # Update if not skipped
        if [[ ${SKIP_UPDATE:-false} != "true" ]]; then
            update_l4d2 || exit 1
        fi

        echo "[entrypoint.sh][INFO] Starting srcds (script-managed restart)..."
        start_srcds "$WORKDIR" "${extra_args[@]}" "$@"
        rc=$?

        echo "[entrypoint.sh][INFO] srcds exited with code $rc"

        if [[ "$auto_restart" == "false" ]]; then
            echo "[entrypoint.sh][INFO] AUTO_RESTART=false, exiting script."
            exit "$rc"
        fi

        echo "[entrypoint.sh][INFO] AUTO_RESTART=true, restarting srcds..."
        sleep 1
    done
fi