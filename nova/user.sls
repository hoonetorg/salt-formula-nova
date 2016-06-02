{% from "nova/map.jinja" import controller with context %}
{%- if controller.enabled %}
{%- if not salt['user.info']('nova') %}
nova_controller__user_nova:
  user.present:
  - name: nova
  - home: /var/lib/nova
  - shell: /bin/false
  - uid: 303
  - gid: 303
  - system: True
  - require_in:
    - pkg: nova_controller_packages
nova_controller__group_nova:
  group.present:
    - name: nova
    - gid: 303
    - system: True
    - require_in:
      - user: nova_controller__user_nova
{%- endif %}
{%- endif %}
{%- from "nova/map.jinja" import compute with context %}
{%- if compute.enabled %}
{%- if not salt['user.info']('nova') %}
nova_compute__user_nova:
  user.present:
  - name: nova
  - home: /var/lib/nova
  {%- if compute.user is defined %}
  - shell: /bin/bash
  {%- else %}
  - shell: /bin/false
  {%- endif %}
  - uid: 303
  - gid: 303
  - system: True
  - groups:
    {%- if salt['group.info']('libvirtd') %}
    - libvirtd
    {%- endif %}
    - nova
  - require_in:
    - pkg: nova_compute_packages
    {%- if compute.user is defined %}
    - file: /var/lib/nova/.ssh/id_rsa
    {%- endif %}
nova_compute__group_nova:
  group.present:
    - name: nova
    - gid: 303
    - system: True
    - require_in:
      - user: nova_compute__user_nova
{%- endif %}

{%- if compute.user is defined %}

nova_auth_keys:
  ssh_auth.present:
  - user: nova
  - names:
    - {{ compute.user.public_key }}

user_nova_bash:
  user.present:
  - name: nova
  - home: /var/lib/nova
  - shell: /bin/bash
  - groups:
    - libvirtd

/var/lib/nova/.ssh/id_rsa:
  file.managed:
  - user: nova
  - contents_pillar: nova:compute:user:private_key
  - mode: 400
  - require:
    - pkg: nova_compute_packages

/var/lib/nova/.ssh/config:
  file.managed:
  - user: nova
  - contents: StrictHostKeyChecking no
  - mode: 400
  - require:
    - pkg: nova_compute_packages
{%- endif %}
{%- endif %}

