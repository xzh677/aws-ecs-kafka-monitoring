#!/bin/bash

sed -e "s#{{ALERTMANAGER_WEBHOOK_URL}}#$ALERTMANAGER_WEBHOOK_URL#g" \
	/etc/alertmanager/alertmanager.tmp.yml > \
    /etc/alertmanager/alertmanager.yml

# start alertmanager
/bin/alertmanager --config.file=/etc/alertmanager/alertmanager.yml