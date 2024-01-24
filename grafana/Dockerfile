FROM grafana/grafana-oss:latest

USER root

RUN mkdir /etc/grafana/conf-templates

COPY grafana.ini /etc/grafana/conf-templates/grafana.tmp.ini
COPY default.yml /etc/grafana/conf-templates/default.tmp.yaml

COPY dashboards.yml /etc/grafana/provisioning/dashboards/dashboards.yml
COPY ccloud.json /etc/grafana/provisioning/dashboards/ccloud.json

COPY start.sh /start.sh
RUN chmod 0755 /start.sh

ENTRYPOINT [ "/bin/sh", "/start.sh" ]