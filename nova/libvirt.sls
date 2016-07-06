{%- from "nova/map.jinja" import compute with context %}
{%- if compute.enabled %}

{%- if compute.virtualization == 'kvm' %}

{%- if compute.libvirt_bin is defined %}
{{ compute.libvirt_bin }}:
  file.managed:
    - source: salt://nova/files/{{ compute.version }}/libvirt.{{ grains.os_family }}
    - template: jinja
    - watch_in:
      - service: {{ compute.libvirt_service }}
{%- endif %}

/etc/libvirt/qemu.conf:
  file.managed:
    - source: salt://nova/files/{{ compute.version }}/qemu.conf.{{ grains.os_family }}
    - template: jinja

/etc/libvirt/{{ compute.libvirt_config }}:
  file.managed:
    - source: salt://nova/files/{{ compute.version }}/libvirtd.conf.{{ grains.os_family }}
    - template: jinja

{{ compute.libvirt_service }}:
  service.running:
    - enable: true
    - watch:
      - file: /etc/libvirt/{{ compute.libvirt_config }}
      - file: /etc/libvirt/qemu.conf

virsh net-undefine default:
  cmd.run:
    - name: "virsh net-destroy default"
    - onlyif: "virsh net-list | grep default"
    - require:
      - service: {{ compute.libvirt_service }}

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
      - service: {{ compute.libvirt_service }}

ceph_virsh_secret_set_value:
  cmd.run:
    - name: "virsh secret-set-value --secret {{ compute.ceph.secret_uuid }} --base64 {{ compute.ceph.client_cinder_key }} "
    - unless: "virsh secret-get-value {{ compute.ceph.secret_uuid }} | grep {{ compute.ceph.client_cinder_key }}"
    - require:
      - cmd: ceph_virsh_secret_define

{%- endif %}

{%- endif %}

{%- endif %}
