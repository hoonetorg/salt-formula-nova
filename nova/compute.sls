{%- from "nova/map.jinja" import compute with context %}
{%- if compute.enabled %}

{%- if compute.vm_swappiness is defined %}
vm.swappiness:
  sysctl.present:
  - value: {{ compute.vm_swappiness }}
  - require_in:
    - service: nova_compute_services
{%- endif %}

nova_compute__/etc/nova/nova.conf:
  file.managed:
  - name: /etc/nova/nova.conf
  - source: salt://nova/files/{{ compute.version }}/nova-compute.conf.{{ grains.os_family }}
  - template: jinja

/var/log/nova:
  file.directory:
  - mode: {{ compute.log_dir_perms|default('0750') }}
  - user: nova
  - group: nova
  - require:
     - file: nova_compute__/etc/nova/nova.conf
  - require_in:
     - service: nova_compute_services

nova_compute_services:
  service.running:
  - enable: true
  - names: {{ compute.services }}
  - watch:
    - file: nova_compute__/etc/nova/nova.conf

{%- if compute.virtualization == 'kvm' %}

{% if compute.ceph is defined %}

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
    - file: nova_compute__/etc/nova/nova.conf
  - watch_in:
    - service: {{ compute.libvirt_service }}
{%- endif %}

/etc/libvirt/qemu.conf:
  file.managed:
  - source: salt://nova/files/{{ compute.version }}/qemu.conf.{{ grains.os_family }}
  - template: jinja
  - require:
    - file: nova_compute__/etc/nova/nova.conf

/etc/libvirt/{{ compute.libvirt_config }}:
  file.managed:
  - source: salt://nova/files/{{ compute.version }}/libvirtd.conf.{{ grains.os_family }}
  - template: jinja
  - require:
    - file: nova_compute__/etc/nova/nova.conf

virsh net-undefine default:
  cmd.run:
  - name: "virsh net-destroy default"
  - require:
    - file: nova_compute__/etc/nova/nova.conf
  - onlyif: "virsh net-list | grep default"

{{ compute.libvirt_service }}:
  service.running:
  - enable: true
  - require:
    - file: nova_compute__/etc/nova/nova.conf
    - cmd: virsh net-undefine default
  - watch:
    - file: /etc/libvirt/{{ compute.libvirt_config }}

{%- endif %}

{%- endif %}
