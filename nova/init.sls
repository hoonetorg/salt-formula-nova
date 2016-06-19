{%- from "nova/map.jinja" import controller with context %}
{%- from "nova/map.jinja" import compute with context %}

include:
- nova.libvirt
- nova.user
- nova.packages
- nova.configure
- nova.service

extend:
  nova_packages__pkgs:
    pkg:
      - require:
        - user: nova_user__user_nova
        - group: nova_user__group_nova

#really only if pillar is defined
# controller dict is always there if imported
{%- if pillar.nova.controller is defined %}
  nova_controller__/etc/nova/nova.conf:
    file:
      - require:
        - pkg: nova_packages__pkgs
  nova_controller__/etc/nova/api-paste.ini:
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
        - file: nova_controller__/etc/nova/nova.conf
        - file: nova_controller__/etc/nova/api-paste.ini
{%- endif %}

#really only if pillar is defined
# compute dict is always there if imported
{%- if pillar.nova.compute is defined %}
  nova_compute__/etc/nova/nova.conf:
    file:
      - require:
        - pkg: nova_packages__pkgs
  nova_compute__/var/log/nova:
    file:
      - require:
         - file: nova_compute__/etc/nova/nova.conf
      - require_in:
         - service: nova_service__compute_services
  nova_service__compute_services:
    service:
      {% if compute.service_state in [ 'running', 'dead' ] %}
      - watch:
      {% else %}
      - require:
      {% endif %}
        - file: nova_compute__/etc/nova/nova.conf
{%- endif %}
