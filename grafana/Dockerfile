FROM grafana/grafana-oss:latest

USER root

RUN mkdir /etc/grafana/conf-templates

COPY grafana.ini /etc/grafana/conf-templates/grafana.tmp.ini
COPY default.yml /etc/grafana/conf-templates/default.tmp.yaml

COPY dashboards.yml /etc/grafana/provisioning/dashboards/dashboards.yml
COPY cccluster.json /etc/grafana/provisioning/dashboards/cccluster.json
COPY ccconnector.json /etc/grafana/provisioning/dashboards/ccconnector.json
COPY ccksql.json /etc/grafana/provisioning/dashboards/ccksql.json
COPY cctopic.json /etc/grafana/provisioning/dashboards/cctopic.json

COPY start.sh /start.sh
RUN chmod 0755 /start.sh

ENTRYPOINT [ "/bin/sh", "/start.sh" ]