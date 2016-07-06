{%- from "nova/map.jinja" import compute with context %}
{%- if compute.enabled %}
nova_service__compute_services:
  service.{{ compute.service_state }}:
    - names: {{ compute.services }}
    {% if compute.service_state in [ 'running', 'dead' ] %}
    - enable: {{ compute.service_enable }}
    {% endif %}
{%- endif %}
