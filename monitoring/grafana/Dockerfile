FROM grafana/grafana:5.0.0
COPY dashboards-providers/providers.yml /etc/grafana/provisioning/dashboards/
COPY datasources/datasources.yml /etc/grafana/provisioning/datasources/
COPY dashboards/* /var/lib/grafana/dashboards/
