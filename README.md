# suricata-merlin

This repo includes support files used by suricata_manager.sh maintained by juched78.
https://github.com/juched78/suricata-merlin

Includes scripts to support features like:
- Install and Uninstall Suricata
- Auto update rules nightly at 3AM
- Collect Logs
- Display stats on UI

## Pre-requisites
1.  Currently only supports Asus routers running [Merlin firmware](https://github.com/RMerl/asuswrt-merlin.ng)
2.	Asus QoS and AiProtection Trend Micro DISABLED
3.  Entware
4.  USB Storage
5.  JFFS Custom Scripts Enabled

## Install/Update Example

1.  Run the installer:
	```sh
	mkdir /jffs/addons 2>/dev/null;mkdir /jffs/addons/suricata 2>/dev/null; curl --retry 3 "https://raw.githubusercontent.com/juched78/suricata-merlin/master/suricata_manager.sh" -o "/jffs/addons/suricata/suricata_manager.sh" && chmod 755 "/jffs/addons/suricata/suricata_manager.sh" && /jffs/addons/suricata/suricata_manager.sh install
	```

## Usage
Usage:    suricata_manager    ['help'|'-h'] | [ 'debug' ]
[ 'install' | 'uninstall' | 'check' | 'stop' | 'start' | 'logs' | 'config[x]' | 'test' ]

suricata_manager config: View the suricata.yml file

suricata_manager configx: Edit the suricata.yml file

suricata_manager check: Syntax check the suricata.yml file

suricata_manager test: Generate a spoof HTTPS attack (To see it you will need to enable the http.log) uid=0(root) gid=0(root) groups=0(root)

suricata_manager logs: View the logs for activity

	/opt/var/log/suricata/fast.log

	/opt/var/log/suricata/stats.log
	