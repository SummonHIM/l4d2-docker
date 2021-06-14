FROM ubuntu:focal

ARG DEBIAN_FRONTEND=noninteractive

ARG USERNAME=l4d2
ARG USER_ID=2000
ARG GROUP_ID=2000

# this should be an externally mounted volume so you're not
# redownloading ~9GB every run
ARG WORKDIR=/l4d2

ENV USERNAME=${USERNAME}
ENV USER_ID=${USER_ID}
ENV GROUP_ID=${GROUP_ID}
ENV WORKDIR=${WORKDIR}

# install steamcmd and srcds prerequisites
RUN echo steam steam/question select "I AGREE" | debconf-set-selections \
  && echo steam steam/license note '' | debconf-set-selections \
  && dpkg --add-architecture i386 \
  && apt-get update \
  && apt-get install -y --no-install-recommends \
    locales \
    ca-certificates \
    steamcmd \
    lib32stdc++6 \
  && LANG='en_US.UTF-8' LANGUAGE='en_US.UTF-8' LC_ALL='en_US.UTF-8' \
        locale-gen en_US.UTF-8 \
  && rm -rf /var/lib/apt/lists/* \
  && ln -s /usr/games/steamcmd /usr/bin/steamcmd \
  && addgroup --gid ${GROUP_ID} ${USERNAME} \
  && adduser --system --home ${WORKDIR} -u ${USER_ID} -gid ${GROUP_ID} \
        --gecos '' --shell /bin/bash ${USERNAME}

COPY entrypoint.sh /entrypoint.sh
RUN ["chmod", "+x", "/entrypoint.sh"]

WORKDIR ${WORKDIR}

# Set default command
ENTRYPOINT ["/entrypoint.sh"]
CMD ["-port", "27015", "-secure"]
