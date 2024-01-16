FROM prom/prometheus:latest
COPY prometheus.tmp.yml /etc/prometheus/prometheus.yml
COPY web.yml /etc/prometheus/web.yml
COPY prometheus-alerts.yml /etc/prometheus/prometheus-alerts.yml
ENTRYPOINT ["/bin/prometheus", "--config.file=/etc/prometheus/prometheus.yml", "--storage.tsdb.path=/prometheus", "--web.console.libraries=/usr/share/prometheus/console_libraries", "--web.console.templates=/usr/share/prometheus/consoles", "--web.config.file=/etc/prometheus/web.yml"]
