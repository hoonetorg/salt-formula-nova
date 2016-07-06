{%- from "nova/map.jinja" import controller with context %}
{%- from "nova/map.jinja" import compute with context %}

include:
- nova.user
- nova.packages
- nova.libvirt
- nova.configure
- nova.service_controller
- nova.service_compute

extend:
  nova_packages__pkgs:
    pkg:
      - require:
        - user: nova_user__user_nova
        - group: nova_user__group_nova
  nova_configure__/etc/nova/nova.conf:
    file:
      - require:
        - pkg: nova_packages__pkgs

#really only if pillar is defined
# controller dict is always there if imported
{%- if pillar.nova.controller is defined %}
  nova_configure__/etc/nova/api-paste.ini:
    file:
      - require:
        - pkg: nova_packages__pkgs
  nova_service__controller_services:
    service:
      - require:
        - cmd: nova_controller__syncdb
      {% if controller.service_state in [ 'running', 'dead' ] %}
      - watch:
      {% else %}
      - require:
      {% endif %}
        - file: nova_configure__/etc/nova/nova.conf
        - file: nova_configure__/etc/nova/api-paste.ini
{%- endif %}

#really only if pillar is defined
# compute dict is always there if imported
{%- if pillar.nova.compute is defined %}
#  nova_configure__/var/log/nova:
#    file:
#      - require:
#         - file: nova_configure__/etc/nova/nova.conf
#      - require_in:
#         - service: nova_service__compute_services
  nova_service__compute_services:
    service:
      {% if compute.service_state in [ 'running', 'dead' ] %}
      - watch:
      {% else %}
      - require:
      {% endif %}
        - file: nova_configure__/etc/nova/nova.conf
{%- endif %}
