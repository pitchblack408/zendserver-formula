# Include :download:`map file <map.jinja>` of OS-specific package names and
# file paths. Values can be overridden using Pillar.
{%- from "zendserver/map.jinja" import zendserver with context %}
{%- set zend_admin_pass = salt['pillar.get']('zendserver:admin_password', 'changeme') %}
{%- set php_version = salt['pillar.get']('zendserver:version:php', '5.5') %}
{%- set webserver = salt['pillar.get']('zendserver:webserver', 'apache') %}
{%- set enable_itk = salt['pillar.get']('zendserver:enable_itk', False) %}
{%- set enable_firewall = salt['pillar.get']('zendserver:enable_firewall', False) %}
{%- set bootstrap = salt['pillar.get']('zendserver:bootstrap', False) %}
{%- set zend_license_order = salt['pillar.get']('zendserver:license:order') %}
{%- set zend_license_serial = salt['pillar.get']('zendserver:license:serial') %}

# Include APT repositories
include:
  - .repo.zendserver
{%- if webserver == 'nginx' %}
  - .repo.nginx

# Install nginx and ensure its running
nginx:
  pkg:
    - installed
  service.running:
    - enable: True
    - reload: True
    - watch:
      - pkg: nginx
      - pkg: zendserver
    - require:
      - pkg: nginx
      - pkg: zendserver
{%- else %}
# Install apache2 ensure its running
apache2:
  pkg:
    - installed
  service.running:
    - enable: True
    - reload: True
    - watch:
      - pkg: apache2
      - pkg: zendserver
    - require:
      - pkg: zendserver
      - pkg: apache2
{%- endif %}

# Enable MPM-ITM in case Apache is used and set to enabled
# This will ensure websites run under the configured user.
{%- if webserver == 'apache' and enable_itk %}
apache2-mpm-itk:
  pkg.installed:
    - require:
      - pkg: apache2
{%- endif %}

# Install Zendserver for NGINX or Apache
zendserver:
  pkg.installed:
{%- if webserver == 'nginx' %}
    - name: zend-server-nginx-php-{{ php_version }}
    - require:
      - pkg: nginx
{%- else %}
    - name: zend-server-php-{{ php_version }}
{%- endif %}

# Open port 80 in the firewall
{%- if enable_firewall %}
firewall_port_80:
  iptables.append:
    - table: filter
    - chain: INPUT
    - jump: ACCEPT
    - match: state
    - connstate: NEW
    - dport: 80
    - proto: tcp
    - sport: 1025:65535
    - save: True
{%- endif %}

# Set alternative to PHP since Zend Server uses a differnet folder
alternative-php:
  cmd.run:
    - name: update-alternatives --install /usr/bin/php php /usr/local/zend/bin/php 1
    - require:
      - pkg: zendserver
    - unless: test -L /usr/bin/php

# Bootstrap Zend-Server to prevent first-run wizard while accessing the admin panel
{%- if bootstrap %}
bootstrap-zs:
  cmd.run:
    - name: /usr/local/zend/bin/zs-manage bootstrap-single-server -p {{ zend_admin_pass }} -o {{ zend_license_order }} -l {{ zend_license_serial }} -a TRUE -r FALSE
    - require:
      - cmd: alternative-php
      - file: zs-admin
    - unless: test -e /etc/zendserver/zs-admin.txt
{%- endif %}

/etc/zendserver:
  file.directory:
    - makedirs: True
    - user: root
    - group: adm
    - mode: 750
    - require:
      - pkg: zendserver

zs-admin:
  file.managed:
    - name: /etc/zendserver/zs-admin.txt
    - contents: {{ zend_admin_pass }}
    - require:
      - file: /etc/zendserver
    - unless: test -e /etc/zendserver/zs-admin.txt