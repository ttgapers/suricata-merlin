#!/bin/sh
##
#
#  __                            __               
# (_ `     _ o  _  _  _)_ _     (_ ` _)_ _  _)_ _ 
#.__) (_( )  ( (_ (_( (_ (_(   .__)  (_ (_( (_ (  
#                                              _) 
#
## by @juched - Generate Stats for GUI tab
## with credit to @JackYaz for his shared scripts
## v1.0 - initial stats
readonly SCRIPT_VERSION="v1.0"

#define www script names
readonly SCRIPT_WEBPAGE_DIR="$(readlink /www/user)"
readonly SCRIPT_NAME="Suricata_Stats.sh"
readonly LOGSCRIPT_NAME="Suricata_Log.sh"
readonly SCRIPT_NAME_LOWER="suricata_stats.sh"
readonly LOGSCRIPT_NAME_LOWER="suricata_log.sh"
readonly SCRIPT_WEB_DIR="$SCRIPT_WEBPAGE_DIR/$SCRIPT_NAME_LOWER"

readonly SCRIPT_DIR="/jffs/addons/suricata"

#needed for shared jy graph files from @JackYaz
readonly SHARED_DIR="/jffs/addons/shared-jy"
readonly SHARED_REPO="https://raw.githubusercontent.com/jackyaz/shared-jy/master"
readonly SHARED_WEB_DIR="$SCRIPT_WEBPAGE_DIR/shared-jy"



#define data file names
statsTitleFile="$SCRIPT_WEB_DIR/suricatastatstitle.txt"
statsTitleFileJS="$SCRIPT_WEB_DIR/suricatastatstitle.js"
statsThreatsFileJS="$SCRIPT_WEB_DIR/suricatastats.js"
statsThreatsHitsFileJS="$SCRIPT_WEB_DIR/suricatahits.js"

#DB file to hold data for uptime graph
dbLogs="/opt/var/lib/suricata/suricata_log.db"

#save md5 of last installed www ASP file so you can find it again later (in case of www ASP update)
installedMD5File="$SCRIPT_DIR/www-installed.md5"

#get sqlite path
[ -f /opt/bin/sqlite3 ] && SQLITE3_PATH=/opt/bin/sqlite3 || SQLITE3_PATH=/usr/sbin/sqlite3

#function to create JS file with data
WriteStats_ToJS(){
	[ -f $2 ] && rm -f "$2"
	echo "function $3(){" >> "$2"
	html='document.getElementById("'"$4"'").innerHTML="'
	while IFS='' read -r line || [ -n "$line" ]; do
		html="$html""$line""\\r\\n"
	done < "$1"
	html="$html"'"'
	printf "%s\\r\\n}\\r\\n" "$html" >> "$2"
}

WriteData_ToJS(){
	{
	echo "var $3;"
	echo "$3 = [];"; } >> "$2"
	contents="$3"'.unshift( '
	while IFS='' read -r line || [ -n "$line" ]; do
		if echo "$line" | grep -q "NaN"; then continue; fi
		if [ "$4" == "date-day" ]; then
			datapoint="{ x: moment(\"""$(echo "$line" | awk 'BEGIN{FS=","}{ print $1 }' | awk '{$1=$1};1')""\", \"YYYY-MM-DD\"), y: ""$(echo "$line" | awk 'BEGIN{FS=","}{ print $2 }' | awk '{$1=$1};1')"" }"
		else	
			datapoint="{ x: moment.unix(""$(echo "$line" | awk 'BEGIN{FS=","}{ print $1 }' | awk '{$1=$1};1')""), y: ""$(echo "$line" | awk 'BEGIN{FS=","}{ print $2 }' | awk '{$1=$1};1')"" }"
		fi
		contents="$contents""$datapoint"","
	done < "$1"
	contents=$(echo "$contents" | sed 's/.$//')
	contents="$contents"");"
	printf "%s\\r\\n\\r\\n" "$contents" >> "$2"
}


#$1sql table $2 label column $3 count column $4 limit count $5 csv file $6 sql file $7 where clasue if needed
WriteSuricataSqlLog_ToFile(){
	{
		echo ".mode csv"
		echo ".output $5"
	} > "$6"
	echo "SELECT $2, SUM($3) FROM $1 $7 GROUP BY $2 ORDER BY SUM($3) DESC LIMIT $4;" >> "$6"
}

#$1 csv file $2 JS file $3 JS func name $4 html tag
WriteSuricataCSV_ToJS_Table() {
	#clean up any null (or "") strings with null string
	sed -i 's/""/null/g' "$1"
	sed -i 's/"//g' "$1"

	[ -f $2 ] && rm -f "$2"
	echo "function $3(){" >> "$2"
	html='document.getElementById("'"$4"'").outerHTML="'
	numLines="$(wc -l < $1)"
	if [ "$numLines" -lt 1 ]; then
		html="$html""<tr><td colspan="4" class="nodata">No data to display</td></tr>"
	else
		html="$html""$(cat "$1" | awk 'BEGIN{FS=","}{ print "<tr><td>" $1 "</td><td>" $2 "</td><td>"$3 "</td><td>" $4 "</td><td>" $5 "</td><td>" $6 "</td><td>" $7 "</td><td>" $8 "</td></tr> \\" }' | awk '{$1=$1};1')"
	fi
	html=${html%?}
	html="$html"'"'
	printf "%s}" "$html" >> "$2"
} 

#$1 fieldname $2 tablename $3 frequency (hours) $4 length (days) $5 outputfile $6 sqlfile
WriteSql_ToFile(){
	{
		echo ".mode csv"
		echo ".output $5"
	} >> "$6"
	COUNTER=0
	timenow="$(date '+%s')"
	until [ $COUNTER -gt "$((24*$4/$3))" ]; do
		echo "select $timenow - ((60*60*$3)*($COUNTER)),IFNULL(avg([$1]),'NaN') from $2 WHERE ([Timestamp] >= $timenow - ((60*60*$3)*($COUNTER+1))) AND ([Timestamp] <= $timenow - ((60*60*$3)*$COUNTER));" >> "$6"
		COUNTER=$((COUNTER + 1))
	done
}

Generate_SuricataStats () {

	echo "Suricata Stats generated on $(date +"%c")" > $statsTitleFile
	WriteStats_ToJS "$statsTitleFile" "$statsTitleFileJS" "SetSuricataStatsTitle" "suricatastatstitle"

	#generate Threat Events
	echo "Calculating Threats data..."
	{
		echo ".mode csv"
		echo ".output /tmp/suricata-threats-monthly.csv"
		echo "select [date],SUM(count) from threat_log GROUP BY date ORDER BY date;"
	} > /tmp/suricata-threats-monthly.sql
	
	"$SQLITE3_PATH" "$dbLogs" < /tmp/suricata-threats-monthly.sql
	[ -f $statsThreatsFileJS ] && rm -f "$statsThreatsFileJS"
	WriteData_ToJS "/tmp/suricata-threats-monthly.csv" "$statsThreatsFileJS" "DatadivLineChartThreatsMonthly" "date-day"

	#generate table data for all known Threats
	echo "Outputting Threats ..."
	[ -f $statsThreatsHitsFileJS ] && rm -f $statsThreatsHitsFileJS
	whereString=""
	WriteSuricataSqlLog_ToFile "threat_log" "date, threat_id, threat_desc, threat_class, threat_priority, threat_src_ip, threat_dst_ip" "count" "250" "/tmp/suricata-threats.csv" "/tmp/suricata-threats.sql" "$whereString"
	"$SQLITE3_PATH" "$dbLogs" < /tmp/suricata-threats.sql
	dos2unix "/tmp/suricata-threats.csv"
	WriteSuricataCSV_ToJS_Table "/tmp/suricata-threats.csv" $statsThreatsHitsFileJS "LoadThreatsTable" "DatadivTableThreats"

	#cleanup temp files
#	rm -f "/tmp/suricata-"*".csv"
#	rm -f "/tmp/suricata-"*".sql"
	[ -f $statsTitleFile ] && rm -f $statsTitleFile
}

Auto_Startup(){
	case $1 in
		create)
			if [ -f /jffs/scripts/post-mount ]; then
				STARTUPLINECOUNTEX=$(grep -cx "$SCRIPT_DIR/$SCRIPT_NAME_LOWER startup"' # '"$SCRIPT_NAME" /jffs/scripts/post-mount)
				
				if [ "$STARTUPLINECOUNTEX" -eq 0 ]; then
					echo "$SCRIPT_DIR/$SCRIPT_NAME_LOWER startup"' # '"$SCRIPT_NAME" >> /jffs/scripts/post-mount
				fi
			else
				echo "#!/bin/sh" > /jffs/scripts/post-mount
				echo "" >> /jffs/scripts/post-mount
				echo "$SCRIPT_DIR/$SCRIPT_NAME_LOWER startup"' # '"$SCRIPT_NAME" >> /jffs/scripts/post-mount
				chmod 0755 /jffs/scripts/post-mount
			fi
		;;
		delete)
			if [ -f /jffs/scripts/post-mount ]; then
				STARTUPLINECOUNT=$(grep -c '# '"$SCRIPT_NAME" /jffs/scripts/post-mount)
				
				if [ "$STARTUPLINECOUNT" -gt 0 ]; then
					sed -i -e '/# '"$SCRIPT_NAME"'/d' /jffs/scripts/post-mount
				fi
			fi
		;;
	esac
}

Auto_Cron(){
	case $1 in
		create)
			STARTUPLINECOUNT=$(cru l | grep -c "$SCRIPT_NAME")
			
			if [ "$STARTUPLINECOUNT" -eq 0 ]; then
				cru a "$SCRIPT_NAME" "14 * * * * $SCRIPT_DIR/$SCRIPT_NAME_LOWER generate"
			fi
			STARTUPLINECOUNT=$(cru l | grep -c "$LOGSCRIPT_NAME")
			
			if [ "$STARTUPLINECOUNT" -eq 0 ]; then
				cru a "$LOGSCRIPT_NAME" "13 * * * * $SCRIPT_DIR/$LOGSCRIPT_NAME_LOWER"
			fi
		;;
		delete)
			STARTUPLINECOUNT=$(cru l | grep -c "$SCRIPT_NAME")
			
			if [ "$STARTUPLINECOUNT" -gt 0 ]; then
				cru d "$SCRIPT_NAME"
			fi
			STARTUPLINECOUNT=$(cru l | grep -c "$LOGSCRIPT_NAME")
			
			if [ "$STARTUPLINECOUNT" -gt 0 ]; then
				cru d "$LOGSCRIPT_NAME"
			fi
		;;
	esac
}

Auto_ServiceEvent(){
	case $1 in
		create)
			if [ -f /jffs/scripts/service-event ]; then
				# shellcheck disable=SC2016
				STARTUPLINECOUNTEX=$(grep -cx "$SCRIPT_DIR/$SCRIPT_NAME_LOWER generate"' "$1" "$2" &'' # '"$SCRIPT_NAME" /jffs/scripts/service-event)
				
				if [ "$STARTUPLINECOUNTEX" -eq 0 ]; then
					# shellcheck disable=SC2016
					echo "$SCRIPT_DIR/$SCRIPT_NAME_LOWER generate"' "$1" "$2" &'' # '"$SCRIPT_NAME" >> /jffs/scripts/service-event
			fi
			else
				echo "#!/bin/sh" > /jffs/scripts/service-event
				echo "" >> /jffs/scripts/service-event
				# shellcheck disable=SC2016
				echo "/jffs/scripts/$SCRIPT_NAME_LOWER generate"' "$1" "$2" &'' # '"$SCRIPT_NAME" >> /jffs/scripts/service-event
				chmod 0755 /jffs/scripts/service-event
			fi
		;;
		delete)
			if [ -f /jffs/scripts/service-event ]; then
				STARTUPLINECOUNT=$(grep -c '# '"$SCRIPT_NAME" /jffs/scripts/service-event)
				
				if [ "$STARTUPLINECOUNT" -gt 0 ]; then
					sed -i -e '/# '"$SCRIPT_NAME"'/d' /jffs/scripts/service-event
				fi
			fi
		;;
	esac
}


Create_Dirs(){

	if [ ! -d "$SCRIPT_WEBPAGE_DIR" ]; then
		mkdir -p "$SCRIPT_WEBPAGE_DIR"
	fi
	
	if [ ! -d "$SCRIPT_WEB_DIR" ]; then
		mkdir -p "$SCRIPT_WEB_DIR"
	fi
}

Get_WebUI_Installed () {
	md5_installed="0"
	if [ -f $installedMD5File ]; then
		md5_installed="$(cat $installedMD5File)"
	fi
}

Get_WebUI_Page () {
	for i in 1 2 3 4 5 6 7 8 9 10; do
		page="$SCRIPT_WEBPAGE_DIR/user$i.asp"
		if [ ! -f "$page" ] || [ "$(md5sum < "$1")" = "$(md5sum < "$page")" ] || [ "$2" = "$(md5sum < "$page")" ]; then
			MyPage="user$i.asp"
			return
		fi
	done
	MyPage="none"
}

Mount_WebUI(){
	if nvram get rc_support | grep -qF "am_addons"; then
		Get_WebUI_Installed
		Get_WebUI_Page "$SCRIPT_DIR/suricatastats_www.asp" "$md5_installed"
		if [ "$MyPage" = "none" ]; then
			echo "Unable to mount $SCRIPT_NAME WebUI page, exiting"
			exit 1
		fi
		echo "Mounting $SCRIPT_NAME WebUI page as $MyPage"
		cp -f "$SCRIPT_DIR/suricatastats_www.asp" "$SCRIPT_WEBPAGE_DIR/$MyPage"
		echo "Saving MD5 of installed file $SCRIPT_DIR/suricatastats_www.asp to $installedMD5File"
		md5sum < "$SCRIPT_DIR/suricatastats_www.asp" > $installedMD5File
		
		if [ ! -f "/tmp/index_style.css" ]; then
			cp -f "/www/index_style.css" "/tmp/"
		fi
		
		if ! grep -q '.menu_Addons' /tmp/index_style.css ; then
			echo ".menu_Addons { background: url(ext/shared-jy/addons.png); }" >> /tmp/index_style.css
		fi
		
		umount /www/index_style.css 2>/dev/null
		mount -o bind /tmp/index_style.css /www/index_style.css
		
		if [ ! -f "/tmp/menuTree.js" ]; then
			cp -f "/www/require/modules/menuTree.js" "/tmp/"
		fi
		
		sed -i "\\~$MyPage~d" /tmp/menuTree.js
		
		if ! grep -q 'menuName: "Addons"' /tmp/menuTree.js ; then
			lineinsbefore="$(( $(grep -n "exclude:" /tmp/menuTree.js | cut -f1 -d':') - 1))"
			sed -i "$lineinsbefore"'i,\n{\nmenuName: "Addons",\nindex: "menu_Addons",\ntab: [\n{url: "ext/shared-jy/redirect.htm", tabName: "Help & Support"},\n{url: "NULL", tabName: "__INHERIT__"}\n]\n}' /tmp/menuTree.js
		fi
		
		if ! grep -q "javascript:window.open('/ext/shared-jy/redirect.htm'" /tmp/menuTree.js ; then
			sed -i "s~ext/shared-jy/redirect.htm~javascript:window.open('/ext/shared-jy/redirect.htm','_blank')~" /tmp/menuTree.js
		fi
		sed -i "/url: \"javascript:window.open('\/ext\/shared-jy\/redirect.htm'/i {url: \"$MyPage\", tabName: \"Suricata\"}," /tmp/menuTree.js
		
		umount /www/require/modules/menuTree.js 2>/dev/null
		mount -o bind /tmp/menuTree.js /www/require/modules/menuTree.js
	fi
}

Unmount_WebUI(){
	Get_WebUI_Installed
	Get_WebUI_Page "$SCRIPT_DIR/suricatastats_www.asp" "$md5_installed" 
	echo "$MyPage"
	if [ -n "$MyPage" ] && [ "$MyPage" != "none" ] && [ -f "/tmp/menuTree.js" ]; then
		sed -i "\\~$MyPage~d" /tmp/menuTree.js
		umount /www/require/modules/menuTree.js
		mount -o bind /tmp/menuTree.js /www/require/modules/menuTree.js
		rm -rf "$SCRIPT_WEBPAGE_DIR/$MyPage"
		rm -rf "$SCRIPT_WEB_DIR"
	fi
}

# $1 show commands
ScriptHeader() { 
	printf "\\n"
	printf "##\\n"
	printf "##Suricata Stats\\n"
	printf "## by @juched - Generate Stats for GUI tab - %s                                         \\n" "$SCRIPT_VERSION"
	printf "## with credit to @JackYaz for his shared scripts                                       \\n"
	printf "\\n"
	if [ ! -z $1 ]; then
		printf "suricata_stats.sh\\n"
		printf "		install   - Installs the needed files to show UI and update stats\\n"
		printf "		generate  - enerates statistics now for UI\\n"
		printf "		uninstall - Removes files needed for UI and stops stats update\\n"
	fi
}

Download_File(){
	/usr/sbin/curl -fsL --retry 3 "$1" -o "$2"
}

Install_Dependancies(){
	#install SQLite if not installed
	if [ ! -f /opt/bin/sqlite3 ]; then
		echo "Installing required version of sqlite3 from Entware"
		opkg update
		opkg install sqlite3-cli
	fi

	# make shared JY charts directory, and download if needed
	if [ ! -d "$SHARED_DIR" ]; then
		echo "Shared JY directory doesn't exist, let's make it..."
		mkdir "$SHARED_DIR"
	fi
	if [ ! -f "$SHARED_DIR/shared-jy.tar.gz.md5" ]; then
		Download_File "$SHARED_REPO/shared-jy.tar.gz" "$SHARED_DIR/shared-jy.tar.gz"
		Download_File "$SHARED_REPO/shared-jy.tar.gz.md5" "$SHARED_DIR/shared-jy.tar.gz.md5"
		tar -xzf "$SHARED_DIR/shared-jy.tar.gz" -C "$SHARED_DIR"
		rm -f "$SHARED_DIR/shared-jy.tar.gz"
		echo "New version of shared-jy.tar.gz downloaded"
	else
		localmd5="$(cat "$SHARED_DIR/shared-jy.tar.gz.md5")"
		remotemd5="$(curl -fsL --retry 3 "$SHARED_REPO/shared-jy.tar.gz.md5")"
		if [ "$localmd5" != "$remotemd5" ]; then
			Download_File "$SHARED_REPO/shared-jy.tar.gz" "$SHARED_DIR/shared-jy.tar.gz"
			Download_File "$SHARED_REPO/shared-jy.tar.gz.md5" "$SHARED_DIR/shared-jy.tar.gz.md5"
			tar -xzf "$SHARED_DIR/shared-jy.tar.gz" -C "$SHARED_DIR"
			rm -f "$SHARED_DIR/shared-jy.tar.gz"
			echo "New version of shared-jy.tar.gz downloaded"
		fi
	fi

	#Symlink the shared jy folder if it doesn't exist
	if [ ! -d "$SHARED_WEB_DIR" ]; then
		ln -s "$SHARED_DIR" "$SHARED_WEB_DIR" 2>/dev/null
	fi
}

#Main loop
if [ -z "$1" ]; then
	ScriptHeader show_commands
	exit 0
fi

ScriptHeader
case "$1" in
	install)
		Install_Dependancies
		Auto_Startup create
		Auto_ServiceEvent create
		Auto_Cron create
		Mount_WebUI
		Create_Dirs
		sh /jffs/addons/suricata/suricata_log.sh
		Generate_SuricataStats
		exit 0
	;;
	startup)
		Auto_Cron create
		Mount_WebUI
		Create_Dirs
		Generate_SuricataStats
		exit 0
	;;
	generate)
		if [ -z "$2" ] && [ -z "$3" ]; then
			Generate_SuricataStats
		elif [ "$2" = "start" ] && [ "$3" = "$SCRIPT_NAME_LOWER" ]; then
			Generate_SuricataStats
		fi
		exit 0
	;;
	uninstall)
		Auto_Startup delete
		Auto_ServiceEvent delete
		Auto_Cron delete
		Unmount_WebUI
		[ -f $installedMD5File ] && rm -f $installedMD5File
		[ -f $dbLogs ] &&  rm -f $dbLogs
		exit 0
	;;
esac
