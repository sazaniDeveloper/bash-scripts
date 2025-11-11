# NGINX SSL Automation Script
This Bash script monitors the NGINX configuration directory for newly added domain files. It verifies their syntax, and automatically issues SSL certificates via acme.sh. In addition, the script creates corresponding renewal scripts and adds scheduled crontab entries for certificate maintenance.
