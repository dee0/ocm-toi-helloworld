FROM docker.io/bitnami/kubectl:1.31.4 

USER root
RUN mkdir -p /toi/outputs; mkdir -p /toi/inputs; chown -R 1001:1001 /toi

#USER 1001 # See https://github.com/open-component-model/ocm-project/issues/359
COPY ./scripts/entrypoint.sh /toi/run

ENTRYPOINT [ "/bin/bash", "/toi/run" ]

