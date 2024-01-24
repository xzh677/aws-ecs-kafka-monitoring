#!/bin/bash

sed -e "s#{{CONFLUENT_CLOUD_API_KEY}}#$CONFLUENT_CLOUD_API_KEY#g" \
	-e "s#{{CONFLUENT_CLOUD_API_SECRET}}#$CONFLUENT_CLOUD_API_SECRET#g" \
	-e "s#{{PROMETHEUS_ALERTMANAGER_URL}}#$PROMETHEUS_ALERTMANAGER_URL#g" \
	/etc/prometheus/conf-templates/prometheus.tmp.yml > /etc/prometheus/prometheus.yml

sed -e "s#{{PROMETHEUS_ADMIN_PASSWORD}}#$PROMETHEUS_ADMIN_PASSWORD#g" \
	/etc/prometheus/conf-templates/web.tmp.yml > /etc/prometheus/web.yml

if [ "$PROMETHEUS_DEBUG" = "true" ]; then
    env
    cat /etc/prometheus/prometheus.yml
    cat /etc/prometheus/web.yml
fi

/bin/prometheus \
    --config.file=/etc/prometheus/prometheus.yml \
    --storage.tsdb.path=/prometheus \
    --web.console.libraries=/usr/share/prometheus/console_libraries \
    --web.console.templates=/usr/share/prometheus/consoles \
    --web.config.file=/etc/prometheus/web.yml
