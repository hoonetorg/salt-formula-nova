include:
- nova.user
- nova.packages
{%- if pillar.nova.controller is defined %}
- nova.controller
{%- endif %}
{%- if pillar.nova.compute is defined %}
- nova.compute
{%- endif %}

extend:
  nova_packages__pkgs:
    pkg:
      - require:
        - user: nova_user__user_nova
        - group: nova_user__group_nova

{%- if pillar.nova.controller is defined %}
  nova_controller__/etc/nova/nova.conf:
    #file.managed:
    file:
      - require:
        - pkg: nova_packages__pkgs

  nova_controller__/etc/nova/api-paste.ini:
    #file.managed:
    file:
      - require:
        - pkg: nova_packages__pkgs
{%- endif %}

{%- if pillar.nova.compute is defined %}
  nova_compute__/etc/nova/nova.conf:
    #file.managed:
    file:
      - require:
        - pkg: nova_packages__pkgs
{%- endif %}
