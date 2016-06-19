{%- from "nova/map.jinja" import controller with context %}
{%- from "nova/map.jinja" import compute with context %}
{%- if controller.enabled %}
nova_service__controller_services:
  service.{{ controller.service_state }}:
    - names: {{ controller.services }}
    {% if controller.service_state in [ 'running', 'dead' ] %}
    - enable: {{ controller.service_enable }}
    {% endif %}
{%- endif %}
{%- if compute.enabled %}
nova_service__compute_services:
  service.{{ compute.service_state }}:
    - names: {{ compute.services }}
    {% if compute.service_state in [ 'running', 'dead' ] %}
    - enable: {{ compute.service_enable }}
    {% endif %}
{%- endif %}
