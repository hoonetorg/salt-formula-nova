# -*- coding: utf-8 -*-
# vim: ft=sls

{%- set server = {} %}
{%- if salt['pillar.get']('nova_type', False) in ['controller'] %}
{%- from "nova/map.jinja" import controller with context %}
{%- set server = controller %}
{%- endif %}
{%- if salt['pillar.get']('nova_type', False) in ['compute'] %}
{%- from "nova/map.jinja" import compute with context %}
{%- set server = compute %}
{%- endif %}

{% set pcs = server.get('pcs', {}) %}

{# set pcs = salt['pillar.get']('nova:server:pcs', {}) #}

{% if pcs.nova_cib is defined and pcs.nova_cib %}
nova_pcs__cib_present_{{pcs.nova_cib}}:
  pcs.cib_present:
    - cibname: {{pcs.nova_cib}}
{% endif %}

{% if 'resources' in pcs %}
{% for resource, resource_data in pcs.resources.items()|sort %}
nova_pcs__resource_present_{{resource}}:
  pcs.resource_present:
    - resource_id: {{resource}}
    - resource_type: "{{resource_data.resource_type}}"
    - resource_options: {{resource_data.resource_options|json}}
{% if pcs.nova_cib is defined and pcs.nova_cib %}
    - require:
      - pcs: nova_pcs__cib_present_{{pcs.nova_cib}}
    - require_in:
      - pcs: nova_pcs__cib_pushed_{{pcs.nova_cib}}
    - cibname: {{pcs.nova_cib}}
{% endif %}
{% endfor %}
{% endif %}

{% if 'constraints' in pcs %}
{% for constraint, constraint_data in pcs.constraints.items()|sort %}
nova_pcs__constraint_present_{{constraint}}:
  pcs.constraint_present:
    - constraint_id: {{constraint}}
    - constraint_type: "{{constraint_data.constraint_type}}"
    - constraint_options: {{constraint_data.constraint_options|json}}
{% if pcs.nova_cib is defined and pcs.nova_cib %}
    - require:
      - pcs: nova_pcs__cib_present_{{pcs.nova_cib}}
    - require_in:
      - pcs: nova_pcs__cib_pushed_{{pcs.nova_cib}}
    - cibname: {{pcs.nova_cib}}
{% endif %}
{% endfor %}
{% endif %}

{% if pcs.nova_cib is defined and pcs.nova_cib %}
nova_pcs__cib_pushed_{{pcs.nova_cib}}:
  pcs.cib_pushed:
    - cibname: {{pcs.nova_cib}}
{% endif %}

nova_pcs__empty_sls_prevent_error:
  cmd.run:
    - name: true
    - unless: true

