# suricata-merlin

## Pre-requisites
1.  Currently only supports Asus HND-model routers running [Merlin firmware](https://github.com/RMerl/asuswrt-merlin.ng) - e.g. HND-models (4.x kernel) RT-AC86U,RT-AX88U or RT-AX56U,RT-AX58U
2.	Asus QoS and AiProtection Trend Micro DISABLED
3.  Entware
4.  USB Storage
5.  JFFS Custom Scripts Enabled

## Install/Update Example

1.  Run the installer:
	```sh
	mkdir /jffs/addons 2>/dev/null;mkdir /jffs/addons/suricata 2>/dev/null; curl -kL https://pastebin.com/raw.php?i=XhNumLMU -o /jffs/addons/suricata/suricata_manager.sh  && chmod 755 "/jffs/addons/suricata/suricata_manager.sh" && dos2unix /jffs/addons/suricata/suricata_manager.sh;/jffs/addons/suricata/suricata_manager.sh
	```

## Usage
Usage:    suricata_manager    ['help'|'-h'] | [ 'debug' ]
[ 'install' | 'uninstall' | 'check' | 'stop' | 'start' | 'logs' | 'config[x]' | 'test' ]

suricata_manager    config
					View the suricata.yml file
suricata_manager    configx
					Edit the suricata.yml file
suricata_manager    check
					Syntax check the suricata.yml file
suricata_manager    test
					Generate a spoof HTTPS attack (To see it you will need to enable the http.log)

							uid=0(root) gid=0(root) groups=0(root)
suricata_manager    logs
					View the default three logs for activity

							==> /opt/var/log/suricata/fast.log <==

							==> /opt/var/log/suricata/stats.log <==

							==> /opt/var/log/suricata/eve-2020-05-09-15:38.json <==