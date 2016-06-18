{% from "nova/map.jinja" import controller with context %}

{%- if controller.enabled %}

nova_controller__/etc/nova/nova.conf:
  file.managed:
  - name: /etc/nova/nova.conf
  - source: salt://nova/files/{{ controller.version }}/nova-controller.conf.{{ grains.os_family }}
  - template: jinja

nova_controller__/etc/nova/api-paste.ini:
  file.managed:
  - name: /etc/nova/api-paste.ini
  - source: salt://nova/files/{{ controller.version }}/api-paste.ini.{{ grains.os_family }}
  - template: jinja

nova_controller_syncdb:
  cmd.run:
  - names:
    - nova-manage db sync
    {%- if controller.version == "mitaka" %}
    - nova-manage api_db sync
    {%- endif %}
  - require:
    - file: nova_controller__/etc/nova/nova.conf

nova_controller_services:
  service.running:
  - enable: true
  - names: {{ controller.services }}
  - require:
    - cmd: nova_controller_syncdb
  - watch:
    - file: nova_controller__/etc/nova/nova.conf
    - file: nova_controller__/etc/nova/api-paste.ini

{%- endif %}
