# This state enables and disables ZendServer plugin  as configured
# in the Pillar. If the bootstrapping of ZendServer wasn't done using
# a formula that stores the API key for admin as a Grain, this state halts.

# Beware: this state will issue a restart every time zs-manage has processed
# all extension-on and extension-off calls. (so at most once every highstate)

# Check if the server has been bootstrapped and the key was saved
{% if salt['grains.get']('zendserver:api:enabled', False) == True %}

# Get the key
{% set zend_api_key = salt['grains.get']('zendserver:api:key') %}


#Add deploy_plugins if is set in pillar
{% if salt['pillar.get']('zendserver:deploy_plugins', {}) -%}

/etc/zendserver/deployPlugins.sh:
  file.managed:
    - source: salt://zendserver/files/deployPlugins.sh
    - user: root
    - group: adm
    - mode: 740

#Create plugin folder
/etc/zendserver/plugins:
  file.directory:
    - makedirs: True
    - user: root
    - group: adm
    - mode: 750

# Copy Plugins to /etc/zendserver/plugins
{% for deploy_plugin in salt['pillar.get']('zendserver:deploy_plugins') -%}
zendserver.copy_plugin_{{ deploy_plugin }}:
  file.managed:
    - name: /etc/zendserver/plugins/{{ deploy_plugin }}.zip
    - source: salt://zendserver/plugins/{{ deploy_plugin }}.zip
    - require:
      - file: /etc/zendserver/plugins
{% endfor -%}

# Deploy plugins if set
{% for plugin_deploy in salt['pillar.get']('zendserver:deploy_plugins') -%}
{{ "depoly_plugin_" ~ plugin_deploy|yaml_encode }}:
  cmd.run:
    - name: /etc/zendserver/deployPlugins.sh {{ zend_api_key }} {{ plugin_deploy }}
    - cwd: /
    - stateful: True
    - require:
      - file: /etc/zendserver/deployPlugins.sh
{% endfor -%}
{% endif %}





# Remove  plugins if remove_plugins  set in pillar
{% if salt['pillar.get']('zendserver:remove_plugins', {}) -%}

/etc/zendserver/removePlugins.sh:
  file.managed:
    - source: salt://zendserver/files/removePlugins.sh
    - user: root
    - group: adm
    - mode: 740

{% for plugin_remove in salt['pillar.get']('zendserver:remove_plugins') -%}
{{ "remove_plugin_" ~ plugin_remove|yaml_encode }}:
  cmd.run:
    - name: /etc/zendserver/removePlugins.sh {{ zend_api_key }} {{ plugin_remove }}
    - cwd: /
    - stateful: True
    - require:
      - file: /etc/zendserver/removePlugins.sh
{% endfor -%}
{% endif %}




{% endif %}
