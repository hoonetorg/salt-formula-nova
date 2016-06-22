{% from "nova/map.jinja" import controller with context %}
{%- from "nova/map.jinja" import compute with context %}

{%- if controller.enabled %}

#nova_controller__/etc/nova/nova.conf:
#  file.managed:
#  - name: /etc/nova/nova.conf
#  - source: salt://nova/files/{{ controller.version }}/nova-controller.conf.{{ grains.os_family }}
#  - template: jinja

nova_configure__/etc/nova/nova.conf:
  file.managed:
  - name: /etc/nova/nova.conf
  - source: salt://nova/files/{{ controller.version }}/nova.conf.{{ grains.os_family }}
  - template: jinja

nova_configure__/etc/nova/api-paste.ini:
  file.managed:
  - name: /etc/nova/api-paste.ini
  - source: salt://nova/files/{{ controller.version }}/api-paste.ini.{{ grains.os_family }}
  - template: jinja

nova_controller__syncdb:
  cmd.run:
  - names:
    - nova-manage db sync
    {%- if controller.version == "mitaka" %}
    - nova-manage api_db sync
    {%- endif %}
  - require:
    - file: nova_configure__/etc/nova/nova.conf
{%- endif %}
{%- if compute.enabled %}

{%- if compute.vm_swappiness is defined %}
vm.swappiness:
  sysctl.present:
  - value: {{ compute.vm_swappiness }}
{%- endif %}

#nova_compute__/etc/nova/nova.conf:
#  file.managed:
#  - name: /etc/nova/nova.conf
#  - source: salt://nova/files/{{ compute.version }}/nova-compute.conf.{{ grains.os_family }}
#  - template: jinja

nova_configure__/var/log/nova:
  file.directory:
  - name: /var/log/nova
  - mode: {{ compute.log_dir_perms|default('0750') }}
  - user: nova
  - group: nova

{%- endif %}
