FROM grafana/grafana:latest

COPY configs/grafana.ini /etc/grafana/grafana.ini
COPY configs/provisioning /etc/grafana/provisioning
COPY configs/dashboards /var/lib/grafana/dashboards

USER root
RUN mkdir -p /etc/grafana /var/lib/grafana && \
    chown -R 472:472 /etc/grafana /var/lib/grafana
USER 472
