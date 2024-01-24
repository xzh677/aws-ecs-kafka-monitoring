FROM prom/alertmanager:latest

COPY config.yml /etc/alertmanager/alertmanager.tmp.yml

USER root

COPY start.sh /start.sh
RUN chmod 0755 /start.sh

ENTRYPOINT [ "/bin/sh", "/start.sh" ]