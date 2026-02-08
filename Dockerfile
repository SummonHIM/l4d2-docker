FROM steamcmd/steamcmd:latest

ARG USER=ubuntu
ARG HOME=/home/${USER}
ARG WORKDIR=${HOME}/server

ENV USER=${USER} \
    HOME=${HOME} \
    WORKDIR=${WORKDIR} \
    VALIDATE=false \
    AUTO_RESTART=false \
    SKIP_UPDATE=false \
    ARGS_port=27015 \
    ARGS_secure=1

COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh && \
    mkdir -p ${WORKDIR} %% \
    chown ${USER}:${USER} ${WORKDIR}

USER ${USER}
WORKDIR ${WORKDIR}

RUN steamcmd +quit

ENTRYPOINT ["/entrypoint.sh"]
CMD []
