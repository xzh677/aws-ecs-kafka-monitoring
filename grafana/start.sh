#!/bin/bash

sed -e "s#{{GRAFANA_ADMIN_PASSWORD}}#$GRAFANA_ADMIN_PASSWORD#g" \
	/etc/grafana/conf-templates/grafana.tmp.ini > /etc/grafana/grafana.ini

sed -e "s#{{GRAFANA_PROMETHEUS_URL}}#$GRAFANA_PROMETHEUS_URL#g" \
	/etc/grafana/conf-templates/default.tmp.yaml > \
    /etc/grafana/provisioning/datasources/default.yaml

# run grafana
/run.sh
