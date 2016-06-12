{%- from "nova/map.jinja" import controller with context -%}
{%- from "nova/map.jinja" import compute with context -%}
{%- from "nova/map.jinja" import user with context -%}

{% set groups = user.user.groups_common %}

{%- if compute.get('enabled', False) %}
nova_user__group_virt:
  group.present:
    - name: {{user.group.name_virt}}
{%- if user.group.gid_virt %}
    - gid: {{user.group.gid_virt}}
{%- endif %}
    - system: True
    - require_in:
      - user: nova_user__user_nova
{% do groups.append(user.group.name_virt) %}
{%- endif %}

nova_user__group_nova:
  group.present:
    - name: {{user.group.name}}
    - gid: {{user.group.gid}}
    - system: True
    - require_in:
      - user: nova_user__user_nova
nova_user__user_nova:
  user.present:
    - name: {{user.user.name}}
    - home: {{user.user.home}}
    - uid: {{user.user.uid}}
    - gid: {{user.group.gid}}
    - groups: {{groups|json}}
    {%- if compute.user is defined %}
    - shell: /bin/bash
    {%- else %}
    - shell: {{user.user.shell}}
    {%- endif %}
    - fullname: {{user.user.fullname}}
    - system: True

{%- if compute.user is defined %}
nova_auth_keys:
  ssh_auth.present:
  - user: {{user.user.name}}
  - names:
    - {{ compute.user.public_key }}

{{user.user.home}}/.ssh/id_rsa:
  file.managed:
  - user: {{user.user.name}}
  - contents_pillar: nova:compute:user:private_key
  - mode: 400
  - require:
    - user: nova_user__user_nova
    - ssh_auth: nova_auth_keys

{{user.user.home}}/.ssh/config:
  file.managed:
  - user: {{user.user.name}}
  - contents: StrictHostKeyChecking no
  - mode: 400
  - require:
    - user: nova_user__user_nova
    - ssh_auth: nova_auth_keys
{%- endif %}
