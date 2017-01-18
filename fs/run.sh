#!/usr/bin/env bash

# fail on any failed command
set -e -x

# Start supervisord and services
/usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf