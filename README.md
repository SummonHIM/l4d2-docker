# Dockerized Left 4 Dead 2 Dedicated Server

## Usage
```Shell
docker run -itd --net=host --name l4d2ds ghcr.io/summonhim/l4d2-docker:latest
```

### Persistent Storage
```Shell
docker run -itd --net=host --name l4d2ds -v /path/to/your/l4d2ds:/srv/l4d2ds ghcr.io/summonhim/l4d2-docker:latest
```

### Environment variables
```Shell
USERNAME_PREFEX=l4d2    # Username prefex when uid not exist.
UID=1000                # Runtime user id.
GID=1000                # Runtime group id.
VALIDATE=false          # Validate, set true to enable.
AUTO_RESTART=false      # Auto restart, set true to enable.
WORKDIR=/srv/l4d2ds     # Not recommend to modify this.
```

### Default start arguments
```
-port 27015 -secure
```

## Compatibility with TrueNAS k3s
Yes