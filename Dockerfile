FROM cm2network/steamcmd:root
ARG WORKDIR=/srv/l4d2ds
ENV USERNAME_PREFEX=l4d2 \
    UID=1000 \
    GID=1000 \
    WORKDIR=${WORKDIR} \
    VALIDATE=false \
    AUTO_RESTART=false \
    SKIP_UPDATE=false

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
WORKDIR ${WORKDIR}

# Set default command
ENTRYPOINT ["/entrypoint.sh"]
CMD ["-port", "27015", "-secure"]
