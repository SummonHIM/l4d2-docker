FROM steamcmd/steamcmd:latest

ARG HOMEDIR=/home/l4d2ds
ARG WORKDIR=${HOMEDIR}/server

ENV WORKDIR=${WORKDIR} \
    VALIDATE=false \
    AUTO_RESTART=false \
    SKIP_UPDATE=false \
    ARGS_port=27015 \
    ARGS_secure=1

COPY entrypoint.sh /bin/entrypoint.sh

RUN chmod +x /bin/entrypoint.sh && \
    mkdir -p ${HOMEDIR} && \
    mkdir -p ${WORKDIR} && \
    chmod 700 ${HOMEDIR} && \
    useradd -m -d ${HOMEDIR} -s /bin/bash l4d2ds && \
    chown -R l4d2ds:l4d2ds ${HOMEDIR}

USER l4d2ds
WORKDIR ${WORKDIR}

ENTRYPOINT ["/bin/entrypoint.sh"]
CMD []
