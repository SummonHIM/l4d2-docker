FROM cm2network/steamcmd

ARG WORKDIR=${HOMEDIR}/l4d2ds
ENV WORKDIR=${WORKDIR} \
    VALIDATE=false \
    AUTO_RESTART=false \
    SKIP_UPDATE=false
WORKDIR ${WORKDIR}

USER root
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
USER steam

# Set default command
ENTRYPOINT ["/entrypoint.sh"]
CMD ["-port", "27015", "-secure"]
