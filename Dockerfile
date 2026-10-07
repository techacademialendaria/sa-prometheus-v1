FROM prom/prometheus:v3.5.0

COPY prometheus.yml /etc/prometheus/prometheus.yml
COPY entrypoint.sh /etc/prometheus/entrypoint.sh

ENTRYPOINT ["/bin/sh", "/etc/prometheus/entrypoint.sh"]
