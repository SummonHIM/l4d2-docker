FROM ubuntu:focal

ARG DEBIAN_FRONTEND=noninteractive
ARG USER=steam
ARG UID=2000
ARG GID=2000
ARG HOME=/home/${USER}
ARG STEAMCMD_DIR=/home/${USER}/.steam

# this should be an externally mounted volume so you're not
# redownloading ~9GB every run
ARG WORKDIR=/srv/l4d2
ENV WORKDIR=${WORKDIR}

# install steamcmd and srcds prerequisites
RUN echo steam steam/question select "I AGREE" | debconf-set-selections \
  && echo steam steam/license note '' | debconf-set-selections \
  && dpkg --add-architecture i386 \
  && apt-get update \
  && apt-get install -y --no-install-recommends \
    locales \
  && LANG='en_US.UTF-8' LANGUAGE='en_US.UTF-8' LC_ALL='en_US.UTF-8' locale-gen en_US.UTF-8 \
  && apt-get purge -y locales \
  && apt-get install -y --no-install-recommends \
    ca-certificates \
    steamcmd \
    lib32stdc++6 \
    libsdl2-2.0-0:i386 \
  && rm -rf /var/lib/apt/lists/* \
  && ln -s /usr/games/steamcmd /usr/bin/steamcmd \
  && addgroup --gid ${GID} ${USER} \
  && adduser --system --home ${HOME} -u ${UID} -gid ${GID} --gecos '' --shell /bin/bash ${USER}

COPY entrypoint.sh /entrypoint.sh
RUN ["chmod", "+x", "/entrypoint.sh"]

USER ${USER}

WORKDIR ${WORKDIR}

# If you mount the STEAMCMD_DIR using a named volume when running the container,
# you can preserve your updated steamcmd files and not have to redownload steamcmd
# every time you run a new container
VOLUME ["${STEAMCMD_DIR}", "${WORKDIR}"]

# Set default command
ENTRYPOINT ["/entrypoint.sh"]
CMD ["-port", "27015", "-secure"]
