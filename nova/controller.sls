{% from "nova/map.jinja" import controller with context %}

{%- if controller.enabled %}

{%- if grains.os_family == 'Debian' %}
nova_consoleproxy_debconf:
  debconf.set:
  - name: nova-consoleproxy
  - data:
      'nova-consoleproxy/daemon_type':
        type: 'string'
        value: 'novnc'
  - require_in:
    - pkg: nova_controller_packages
{%- endif %}

nova_controller_packages:
  pkg.installed:
  - names: {{ controller.pkgs }}

{%- if controller.get('networking', 'default') == "contrail" and controller.version == "juno" %}

contrail_nova_packages:
  pkg.installed:
  - names:
    - contrail-nova-driver
    - contrail-nova-networkapi

{%- endif %}

nova_controller__/etc/nova/nova.conf:
  file.managed:
  - name: /etc/nova/nova.conf
  - source: salt://nova/files/{{ controller.version }}/nova-controller.conf.{{ grains.os_family }}
  - template: jinja
  - require:
    - pkg: nova_controller_packages

/etc/nova/api-paste.ini:
  file.managed:
  - source: salt://nova/files/{{ controller.version }}/api-paste.ini.{{ grains.os_family }}
  - template: jinja
  - require:
    - pkg: nova_controller_packages

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
    - file: /etc/nova/api-paste.ini

{%- endif %}
