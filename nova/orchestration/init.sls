#!jinja|yaml
{%- set controller_node_ids = salt['pillar.get']('nova:server:pcs:controller_node_ids') -%}
{%- set controller_admin_node_id = salt['pillar.get']('nova:server:pcs:controller_admin_node_id') -%}
{%- set compute_node_ids = salt['pillar.get']('nova:server:pcs:compute_node_ids') -%}
{%- set compute_admin_node_id = salt['pillar.get']('nova:server:pcs:compute_admin_node_id') -%}
{%- set node_ids = [] %}
{%- set dup_node_ids = controller_node_ids + compute_node_ids %}
{%- for node_id in dup_node_ids %}
# probably appending {{node_id}}
{%- if node_id not in node_ids %}
# appending {{node_id}}
{%- do node_ids.append(node_id) %}
# node_ids: {{node_ids}}
{%- endif %}
{%- endfor %}

# controller_node_ids: {{controller_node_ids|json}}
# controller_admin_node_id: {{controller_admin_node_id}}
# compute_node_ids: {{compute_node_ids|json}}
# compute_admin_node_id: {{compute_admin_node_id}}
# dup_node_ids: {{dup_node_ids}}
# node_ids: {{node_ids}}

{%- for node_id in node_ids %}
nova_orchestration__install_{{node_id}}:
  salt.state:
    - tgt: {{node_id}}
    - expect_minions: True
    - sls: nova.clusterpre
    - require_in:
      - salt: nova_orchestration__pcs_controller
{%- endfor %}

{%- for controller_node_id in controller_node_ids %}
nova_orchestration__service_controller_{{controller_node_id}}:
  salt.state:
    - tgt: {{controller_node_id}}
    - expect_minions: True
    - sls: nova.service_controller
    - timeout: 60
    - require_in:
      - salt: nova_orchestration__pcs_controller
{%- endfor %}

nova_orchestration__pcs_controller:
  salt.state:
    - tgt: {{controller_admin_node_id}}
    - expect_minions: True
    - sls: nova.pcs
    - pillar:
        nova_type: controller

{%- for compute_node_id in compute_node_ids %}
nova_orchestration__service_compute_{{compute_node_id}}:
  salt.state:
    - tgt: {{compute_node_id}}
    - expect_minions: True
    - sls: nova.service_compute
    - timeout: 60
    - require:
      - salt: nova_orchestration__pcs_controller
    - require_in:
      - salt: nova_orchestration__pcs_compute
{%- endfor %}

nova_orchestration__pcs_compute:
  salt.state:
    - tgt: {{compute_admin_node_id}}
    - expect_minions: True
    - sls: nova.pcs
    - pillar:
        nova_type: compute
