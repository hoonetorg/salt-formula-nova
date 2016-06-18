{%- from "nova/map.jinja" import controller with context %}
{%- from "nova/map.jinja" import compute with context %}

{%- set pkgs = [] %}

{%- if controller.enabled %}
  {%- set pkgs = pkgs + controller.pkgs %}
  {%- if controller.get('networking', 'default') == "contrail" and controller.version == "juno" %}
    {%- set pkgs = pkgs + ['contrail-nova-driver', 'contrail-nova-networkapi'] %}
  {%- endif %}

{%- if grains.os_family == 'Debian' %}
nova_packages__consoleproxy_debconf:
  debconf.set:
  - name: nova-consoleproxy
  - data:
      'nova-consoleproxy/daemon_type':
        type: 'string'
        value: 'novnc'
  - require_in:
    - pkg: nova_packages__pkgs
{%- endif %}

{%- endif %}

{%- if compute.enabled %}
  {%- set pkgs = pkgs + compute.pkgs %}
  {%- if compute.ceph is defined %}
    {%- set pkgs = pkgs + [ 'ceph-common' ] %}
  {%- endif %}
{%- endif %}

nova_packages__pkgs:
  pkg.installed:
  - names: {{ pkgs }}
