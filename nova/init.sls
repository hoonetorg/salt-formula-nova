
include:
- nova.user
{%- if pillar.nova.controller is defined %}
- nova.controller
{%- endif %}
{%- if pillar.nova.compute is defined %}
- nova.compute
{%- endif %}


extend:
{%- if pillar.nova.controller is defined %}
  nova_controller_packages:
    pkg:
      - require:
        - user: nova_user__user_nova
        - group: nova_user__group_nova
{%- endif %}
{%- if pillar.nova.compute is defined %}
  nova_compute_packages:
    pkg:
      - require:
        - user: nova_user__user_nova
        - group: nova_user__group_nova
{%- endif %}
