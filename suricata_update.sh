#! /bin/sh
curl -o /opt/etc/suricata/classification.config https://rules.emergingthreats.net/open/suricata-4.0/rules/classification.config
curl -SL https://rules.emergingthreats.net/open/suricata-4.0/emerging.rules.tar.gz | tar -zxC /opt/var/lib/suricata/
sleep 2s
/opt/etc/init.d/S82suricata stop
sleep 2s
/opt/etc/init.d/S82suricata start
