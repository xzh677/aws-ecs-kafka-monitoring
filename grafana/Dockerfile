FROM grafana/grafana-oss:latest
COPY grafana.ini /etc/grafana/grafana.ini
COPY default.tmp.yml /etc/grafana/provisioning/datasources/default.yaml
COPY dashboards.yml /etc/grafana/provisioning/dashboards/dashboards.yml
COPY ccloud.json /etc/grafana/provisioning/dashboards/ccloud.json
