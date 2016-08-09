# This state will build cluster on ZendServer as configured
# in the Pillar. If the bootstrapping of ZendServer wasn't done using
# a formula that stores the API key for admin as a Grain, this state halts.

# Beware: this state will issue a restart every time zs-manage has processed
# all extension-on and extension-off calls. (so at most once every highstate)

# Check if the server has been bootstrapped and the key was saved
{% if salt['grains.get']('zendserver:api:enabled', False) == True and ('cluster' in salt['pillar.get']('zendserver', {})) %}
# Get the key
{% set zend_api_key = salt['grains.get']('zendserver:api:key') %}
# cluster configuration
{%- set zend_main_node_name = salt['pillar.get']('zendserver:cluster:main_node:name') %}
{%- set zend_main_node_ip = salt['pillar.get']('zendserver:cluster:main_node:ip') %}
{%- set zend_blueprint_dbhost = salt['pillar.get']('zendserver:cluster:blueprint:dbhost') %}
{%- set zend_blueprint_dbusername = salt['pillar.get']('zendserver:cluster:blueprint:dbusername') %}
{%- set zend_blueprint_dbpassword = salt['pillar.get']('zendserver:cluster:blueprint:dbpassword') %}
{%- set zend_blueprint_dbschema = salt['pillar.get']('zendserver:cluster:blueprint:dbschema') %}



# Add main node to cluster if set in pillar
{% if salt['pillar.get']('zendserver:cluster', {}) -%}


/etc/zendserver/addServerToCluster.py:
  file.managed:
    - source: salt://zendserver/files/addServerToCluster.py
    - user: root
    - group: adm
    - mode: 740

{% for add_node in salt['pillar.get']('zendserver:cluster:add_nodes') -%}
{%- set node_ip = salt['pillar.get']('zendserver:cluster:add_nodes:' ~ add_node ~ ':ip') -%}
{{ "addServerToZendCluster_" ~ add_node|yaml_encode }}:
  cmd.run:
    - name: /etc/zendserver/addServerToCluster.py {{ add_node }} {{ node_ip }} {{ zend_blueprint_dbhost }} {{ zend_blueprint_dbusername }} {{ zend_blueprint_dbpassword }} {{ zend_blueprint_dbschema  }} admin {{ zend_api_key }}

    - cwd: /
    - stateful: True
    - require:
      - file: /etc/zendserver/addServerToCluster.py
{% endfor -%}
{% endif %}

{% endif %}
