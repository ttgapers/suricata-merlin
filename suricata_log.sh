#!/bin/sh 
##
#
#   _____            _            __           __               
#  / ___/__  _______(_)________ _/ /_____ _   / /   ____  ____ _
#  \__ \/ / / / ___/ / ___/ __ `/ __/ __ `/  / /   / __ \/ __ `/
# ___/ / /_/ / /  / / /__/ /_/ / /_/ /_/ /  / /___/ /_/ / /_/ / 
#/____/\__,_/_/  /_/\___/\__,_/\__/\__,_/  /_____/\____/\__, /  
#                                                      /____/   
#
## @juched - Process logs into SQLite3 for stats generation
##suricata_log.sh
## - v1.0 - March 24 2020 - Initial version
readonly SCRIPT_VERSION="v1.0"

Say(){
   echo -e $$ $@ | logger -st "($(basename $0))"
}

ScriptHeader(){
	printf "\\n"
	printf "##\\n"
	printf "##Suricata Log\\n"
	printf "## by @juched - Process logs into SQLite3 for stats generation - %s                      \\n" "$SCRIPT_VERSION"
	printf "\\n"
	printf "suricata_log.sh\\n"
}

ScriptHeader

# default to non-syslog location and variable positions
suricata_logfile="/opt/var/log/suricata/fast.log"
n_threat_id=3
n_threat_desc=4
n_threat_class=6
n_threat_priority=8
n_threat_connection=9
n_threat_connection_src=2
n_threat_connection_dst=4

echo "Logfile used is $suricata_logfile"

#other variables
tmpSQL="/tmp/suricata_log.sql"
dbLogFile="/opt/var/lib/suricata/suricata_log.db"
dateString=$(date '+%F')
olddateString30=$(date -D %s -d $(( $(date +%s) - 30*86400)) '+%F')
echo "Date used is $dateString (30 days ago is $olddateString30)"

#create table to track threats detected from fast.log
echo "Creating threat_log table if needed..."
printf "CREATE TABLE IF NOT EXISTS [threat_log] ([threat_id] VARCHAR(32) NOT NULL,[threat_desc] VARCHAR(255) NOT NULL,[threat_class] VARCHAR(255) NOT NULL, [threat_priority] VARCHAR(32) NOT NULL, [threat_src_ip] VARCHAR(16) NOT NULL, [threat_dst_ip] VARCHAR(16) NOT NULL, [date] DATE NOT NULL, [count] INTEGER NOT NULL, PRIMARY KEY(threat_id,date));" | sqlite3 $dbLogFile

#delete old records > 30 days ago
echo "Deleting old threat_log records older than 30 days..."
printf "DELETE FROM threat_log WHERE date < '$olddateString30';" | sqlite3 $dbLogFile


# Add to SQLite all reply domains (log-replies must be yes)
if [ -f "$suricata_logfile" ]; then # only if log exists

  # process reply logs - for top daily replies table
  echo "BEGIN;" > $tmpSQL
  cat $suricata_logfile | awk -v vardate="$dateString" -v varthreatid="$n_threat_id" -v varthreatdesc="$n_threat_desc" -v varthreatclass="$n_threat_class" -v varthreatpriority="$n_threat_priority" -v varthreatconnect="$n_threat_connection" -v vartheatconnection_src="$n_threat_connection_src" -v varthreatconnection_dst="$n_threat_connection_dst" -F' \\[\\*\\*\\] |\\[|\\] ' '/\[\*\*\]/{split($varthreatconnect,a_conn,"\\{*\\} | -> |:");print "INSERT OR IGNORE INTO threat_log ([threat_id],[threat_desc],[threat_class],[threat_priority],[threat_src_ip],[threat_dst_ip],[date],[count]) VALUES (\x27" $varthreatid "\x27, \x27" $varthreatdesc "\x27, \x27" $varthreatclass "\x27, \x27" $varthreatpriority "\x27, \x27" a_conn[vartheatconnection_src] "\x27, \x27" a_conn[varthreatconnection_dst] "\x27, \x27" vardate "\x27, 0);\nUPDATE threat_log SET count = count + 1 WHERE threat_id = \x27" $varthreatid "\x27 AND threat_src_ip = \x27" a_conn[vartheatconnection_src] "\x27 AND threat_dst_ip = \x27" a_conn[varthreatconnection_dst] "\x27 AND date = \x27" vardate "\x27;"}' >> $tmpSQL
  echo "COMMIT;" >> $tmpSQL

##cat fast.log | awk -F'\\[\\*\\*\\]|\\[|\\] ' '{print $3;print $4;print $6;print $8;split($9,a_conn,"\\{*\\} | -> |:");print a_conn[2];print a_conn[4]}'
##cat fast.log | awk -F' \\[\\*\\*\\] |\\[|\\] ' '/\[\*\*\]/{split($9,a_conn,"\\{*\\} | -> |:");print "INSERT OR IGNORE INTO threat_log ([threat_id],[threat_desc],[threat_class],[threat_priority],[threat_src_ip],[threat_dst_ip],[date],[count]) VALUES (\x27" $3 "\x27, \x27" $4 "\x27, \x27" $6 "\x27, \x27" $8 "\x27, \x27" a_conn[2] "\x27, \x27" a_conn[4]"\x27, 0);"}'
##cat fast.log | awk -F' \\[\\*\\*\\] |\\[|\\] ' '/\[\*\*\]/{split($9,a_conn,"\\{*\\} | -> |:");print "INSERT OR IGNORE INTO threat_log ([threat_id],[threat_desc],[threat_class],[threat_priority],[threat_src_ip],[threat_dst_ip],[date],[count]) VALUES (\x27" $3 "\x27, \x27" $4 "\x27, \x27" $6 "\x27, \x27" $8 "\x27, \x27" a_conn[2] "\x27, \x27" a_conn[4]"\x27, 0);\nUPDATE threat_log SET count = count + 1 WHERE threat_id = \x27" $3 "\x27 AND threat_src_ip = \x27" a_conn[2] "\x27 AND threat_dst_ip = \x27" a_conn[4] AND date = \x27" $1 "\x27;"}'
##cat fast.log | awk -F' \\[\\*\\*\\] |\\[|\\] ' '/\[\*\*\]/{split($9,a_conn,"\\{*\\} | -> |:");print "INSERT OR IGNORE INTO threat_log ([threat_id],[threat_desc],[threat_class],[threat_priority],[threat_src_ip],[threat_dst_ip],[date],[count]) VALUES (\x27" $3 "\x27, \x27" $4 "\x27, \x27" $6 "\x27, \x27" $8 "\x27, \x27" a_conn[2] "\x27, \x27" a_conn[4] "\x27, 0);\nUPDATE threat_log SET count = count + 1 WHERE threat_id = \x27" $3 "\x27 AND threat_src_ip = \x27" a_conn[2] "\x27 AND threat_dst_ip = \x27" a_conn[4] "\x27 AND date = \x27" $1  "\x27;"}'

  # log out the processed nodes
  threat_count=$(grep -c "\[\*\*\]" $suricata_logfile)
  Say "Processed $threat_count threat records..." 

  #echo "Removing threat lines from log file..."
  sed -i '\~\[\*\*\]~d' $suricata_logfile

  # HUP to restart logs
  /bin/kill -HUP `cat /opt/var/run/suricata.pid 2>/dev/null` 2>/dev/null

  echo "Running SQLite to import new reply records..."
  sqlite3 $dbLogFile < $tmpSQL

  #cleanup
  if [ -f $tmpSQL ]; then rm $tmpSQL; fi

fi

echo "All done!"
