{%- from "nova/map.jinja" import controller with context %}
{%- if controller.enabled %}
nova_service__controller_services:
  service.{{ controller.service_state }}:
    - names: {{ controller.services }}
    {% if controller.service_state in [ 'running', 'dead' ] %}
    - enable: {{ controller.service_enable }}
    {% endif %}
{%- endif %}
