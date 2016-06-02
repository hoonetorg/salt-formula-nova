{%- from "nova/map.jinja" import compute with context %}
{%- if compute.enabled %}

nova_compute_packages:
  pkg.installed:
  - names: {{ compute.pkgs }}

/var/log/nova:
  file.directory:
  {%- if compute.log_dir_perms is defined %}
  - mode: {{ compute.log_dir_perms }}
  {%- else %}
  - mode: 750
  {%- endif %}
  - user: nova
  - group: nova
  - require:
     - pkg: nova_compute_packages
  - require_in:
     - service: nova_compute_services

{%- if compute.vm_swappiness is defined %}
vm.swappiness:
  sysctl.present:
  - value: {{ compute.vm_swappiness }}
  - require:
    - pkg: nova_compute_packages
  - require_in:
    - service: nova_compute_services
{%- endif %}

{#- if pillar.nova.controller is not defined #}

nova_compute__/etc/nova/nova.conf:
  file.managed:
  - source: salt://nova/files/{{ compute.version }}/nova-compute.conf.{{ grains.os_family }}
  - template: jinja
  - require:
    - pkg: nova_compute_packages

nova_compute_services:
  service.running:
  - enable: true
  - names: {{ compute.services }}
  - watch:
    - file: nova_compute__/etc/nova/nova.conf

{%- if compute.virtualization == 'kvm' %}

{% if compute.ceph is defined %}

ceph_package:
  pkg.installed:
  - name: ceph-common

/etc/secret.xml:
  file.managed:
  - source: salt://nova/files/secret.xml
  - template: jinja

ceph_virsh_secret_define:
  cmd.run:
  - name: "virsh secret-define --file /etc/secret.xml"
  - unless: "virsh secret-list | grep {{ compute.ceph.secret_uuid }}"
  - require:
    - file: /etc/secret.xml

ceph_virsh_secret_set_value:
  cmd.run:
  - name: "virsh secret-set-value --secret {{ compute.ceph.secret_uuid }} --base64 {{ compute.ceph.client_cinder_key }} "
  - unless: "virsh secret-get-value {{ compute.ceph.secret_uuid }} | grep {{ compute.ceph.client_cinder_key }}"
  - require:
    - cmd: ceph_virsh_secret_define

{% endif %}

{%- if compute.libvirt_bin is defined %}
{{ compute.libvirt_bin }}:
  file.managed:
  - source: salt://nova/files/{{ compute.version }}/libvirt.{{ grains.os_family }}
  - template: jinja
  - require:
    - pkg: nova_compute_packages
  - watch_in:
    - service: {{ compute.libvirt_service }}
{%- endif %}

/etc/libvirt/qemu.conf:
  file.managed:
  - source: salt://nova/files/{{ compute.version }}/qemu.conf.{{ grains.os_family }}
  - template: jinja
  - require:
    - pkg: nova_compute_packages

/etc/libvirt/{{ compute.libvirt_config }}:
  file.managed:
  - source: salt://nova/files/{{ compute.version }}/libvirtd.conf.{{ grains.os_family }}
  - template: jinja
  - require:
    - pkg: nova_compute_packages

virsh net-undefine default:
  cmd.run:
  - name: "virsh net-destroy default"
  - require:
    - pkg: nova_compute_packages
  - onlyif: "virsh net-list | grep default"

{{ compute.libvirt_service }}:
  service.running:
  - enable: true
  - require:
    - pkg: nova_compute_packages
    - cmd: virsh net-undefine default
  - watch:
    - file: /etc/libvirt/{{ compute.libvirt_config }}

{%- endif %}

{#- endif #}

{%- endif %}
