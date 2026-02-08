# Dockerized Left 4 Dead 2 Dedicated Server

This Docker image provides a **Left 4 Dead 2 dedicated server** using SteamCMD. It supports:

* Automatic updates via SteamCMD
* Flexible startup arguments and CVAR configuration
* Optional script-managed server restarts
* Debug mode for development and troubleshooting

---

## Environment Variables

| Variable              | Default               | Description                                                                                                                                                                                                            |
| --------------------- | --------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `WORKDIR`             | `/home/l4d2ds/server` | Server installation directory. **Do not modify** unless you know what you are doing.                                                                                                                                   |
| `AUTO_RESTART`        | `false`               | Controls server auto-restart behavior: <br>• `internal` → server handles restarts internally (default) <br>• `true` → script loops and restarts server automatically <br>• `false` → script runs server once and exits |
| `SKIP_UPDATE`         | `false`               | Skip SteamCMD app update. Set to `true` to disable automatic updates.                                                                                                                                                  |
| `STEAM_USERNAME`      | (empty)               | SteamCMD login username. If empty, anonymous login is used.                                                                                                                                                            |
| `STEAM_PASSWORD`      | (empty)               | SteamCMD plain text password. Only used if `STEAM_PASSWORD_FILE` is not set.                                                                                                                                           |
| `STEAM_PASSWORD_FILE` | (empty)               | Path to a file containing the SteamCMD password. Recommended for Docker secrets. Overrides `STEAM_PASSWORD`.                                                                                                           |
| `STEAM_VALIDATE`      | `false`               | SteamCMD **validate** option. Set to `true` to verify game files before starting.                                                                                                                                      |
| `STEAM_PLATFORM_TYPE` | `linux`               | Platform type for SteamCMD (`linux` or `windows`).                                                                                                                                                                     |
| `DEBUG`               | `false`               | Enable debug mode. Prints SteamCMD and `srcds` commands, and automatically adds `-debug` to `srcds` startup.                                                                                                           |

---

## Startup Arguments

The server supports **dynamic startup arguments** via environment variables:

1. **`ARGS_<name>`** → maps to `-<name> <value>` in `srcds_run`.
   Example:

   ```bash
   export ARGS_port=27015
   export ARGS_ip=0.0.0.0
   ```

   Produces:

   ```text
   -port 27015 -ip 0.0.0.0
   ```

2. **`CVAR_<name>`** → maps to `+<name> <value>` in `srcds_run`.
   Example:

   ```bash
   export CVAR_maxplayers=8
   export CVAR_sv_lan=0
   ```

   Produces:

   ```text
   +maxplayers 8 +sv_lan 0
   ```

3. **Debug Mode**

   * Setting `DEBUG=true` prints the full SteamCMD and `srcds` commands.
   * Automatically appends `-debug` to `srcds_run`.

---

## Example Usage

Run the server with anonymous login, debug mode, and automatic script-managed restart:

```bash
docker run -itd --net=host --name l4d2ds \
  -e DEBUG=true \
  -e AUTO_RESTART=true \
  ghcr.io/summonhim/l4d2-docker:latest
```

Run with custom ports and CVARs:

```bash
docker run -itd --net=host --name l4d2ds \
  -e ARGS_port=27015 \
  -e ARGS_ip=0.0.0.0 \
  -e CVAR_maxplayers=8 \
  -e CVAR_sv_lan=0 \
  ghcr.io/summonhim/l4d2-docker:latest
```

To persist your server data between container restarts, mount a host directory:

```bash
docker run -itd --net=host --name l4d2ds \
  -v /path/to/your/l4d2ds:/home/steam/l4d2ds \
  ghcr.io/summonhim/l4d2-docker:latest
```
