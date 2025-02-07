# Dockerized Left 4 Dead 2 Dedicated Server

## Usage
```Shell
docker run -itd --net=host --name l4d2ds ghcr.io/summonhim/l4d2-docker:latest
```

### Persistent Storage
```Shell
docker run -itd --net=host --name l4d2ds -v /path/to/your/l4d2ds:/home/steam/l4d2ds ghcr.io/summonhim/l4d2-docker:latest
```

### Docker Composer
[Composerize](https://www.composerize.com/)

### Environment variables
```Shell
VALIDATE=false                 # Validate, set true to enable.
AUTO_RESTART=false             # Auto restart, set true to enable.
SKIP_UPDATE=false              # Skip update, set true to skip steamcmd app update.
WORKDIR=/home/steam/l4d2ds     # Not recommend to modify this.
STEAM_USERNAME=                # Steam CMD login username. if empty, script will use anonymous
STEAM_PASSWORD=                # Plain text password
STEAM_PASSWORD_FILE=           # A path to password file. Used for docker secret.
```

### Default start arguments
```
-port 27015 -secure
```

## Temporary Download L4D2
```Shell
docker run -it -v /path/to/your/l4d2ds:/home/steam/l4d2ds cm2network/steamcmd \
    $STEAMCMDDIR/steamcmd.sh +force_install_dir /home/steam/l4d2ds +login USERNAME PASSWORD 2FA-IF-EXIST +app_update 222860 validate +quit
```