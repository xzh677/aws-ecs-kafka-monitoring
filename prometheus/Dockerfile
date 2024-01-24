FROM prom/prometheus:latest

USER root

RUN mkdir /etc/prometheus/conf-templates

COPY prometheus.yml /etc/prometheus/conf-templates/prometheus.tmp.yml
COPY web.yml /etc/prometheus/conf-templates/web.tmp.yml
COPY prometheus-alerts.yml /etc/prometheus/prometheus-alerts.yml

COPY start.sh /start.sh
RUN chmod 0755 /start.sh

ENTRYPOINT ["/bin/sh", "/start.sh"]
