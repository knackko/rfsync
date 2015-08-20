#! /bin/bash

# Copyright (C) 2014  Cedric hertault, knackko@gmail.com

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>. 

VERSION="rfsync v1.02dev"
DIALOG="dialog "
RSYNC="rsync --timeout=300 --info=name,progress --stats -ztrh "
RSYNC_SIG="rsync --timeout=300 -ztrh "
LOG_FILE="logs/rfsync.log"
LOG_RSYNC="logs/rsync.log"
tempfile=`tempfile 2>/dev/null` || tempfile=/tmp/test$$
trap "rm -f $tempfile" 0 1 2 5 15
CURPATH=`pwd`
INFO=2
ERROR=1
LOG_LEVEL=2

cd ../
RFACTOR_PATH=`pwd`
cd ../
INSTALL_PATH=`pwd`
cd "$CURPATH"

sync_state1="OFF"
sync_state2="OFF"
ui_state1="ON"
ui_state2="OFF"
lang=EN
MD5_UPDATE=""
UPDATE_ENABLE=1 # set to 0 in params file if needed by dev
UI="HD"

export RSYNC_PASSWORD="na"
export LOGNAME="syncuser"
export DIALOGRC="$CURPATH/dialogrc"
		
# DEBUT FONCTIONS
if [ -f "$CURPATH/params" ]
then
	. "$CURPATH/params"
fi
if [ -f "$CURPATH/conf/server.conf" ]
then
	. "$CURPATH/conf/server.conf"
fi

# recuperation du pilote actif dans l'installation
# TO FINISH
#trap 'rapporter_erreur 4 $LINENO $?' ERR
#plrfiles=`/bin/find.exe "$RFACTOR_PATH/UserData/" -type f -name "*.plr" -o -name "*.PLR"`
#if [ -n "$plrfiles" ]
#then
#	last_plr=`ls -1rt "$plrfiles" | tail -n 1 | tr -d '\r'`
#	plr_filename=`echo ${last_plr##*/}`
#	drivername=`echo ${plr_filename%%.*}`
#	last_multiplayer="$RFACTOR_PATH/UserData/$drivername/Multiplayer.ini"
#fi
#trap - ERR  
realfeel=""

rapporter_erreur(){
	code_erreur=$1
	ligne=$2
	code=$3
	

	case $code_erreur in
	1)# echec de synchronisation
		error "erreur 1: echec synchronisation, code $code, ligne $ligne"
		message="$message_erreur1, code:$code l:$ligne"
		creer_ziplog
	;;
	2)# echec de verification d'une signature
		error "erreur 2: echec de verification de signature, code $code, ligne $ligne"
		message="$message_erreur2, code:$code l:$ligne"
		creer_ziplog
	;;
	3)# erreur durant l'installation du mod
		error "erreur 3: erreur durant l'installation du mod,  code $code, ligne $ligne"
		message="$message_erreur3, code:$code l:$ligne"
		creer_ziplog
	;;
	4)# erreur durant la detection du profil actif
		error "erreur 4: la detection du profil actif,  code $code, ligne $ligne"
		message="$message_erreur4, code:$code l:$ligne"
		creer_ziplog
	;;
	11)# installation sous C:
		error "erreur 11: installation sous C:"
		message="$message_erreur11"
	;;
	12)# rfactor lance
		error "erreur 12: rfactor lance"
		message="$message_erreur12"
	;;
	13)# installation sous C:Program Files
		error "erreur 13: installation sous C:Program Files"
		message="$message_erreur11"
	;;
	esac
	
	$DIALOG --backtitle "$backtitle | $VERSION" \
	--title "\Z1$erreur_title\Zn" --clear --trim --cr-wrap\
	--colors  --ok-label "$quitter" \
	--msgbox "\n\Zb\Z1! $message !\Zn" 12 70 2> $tempfile
	sortir
}

creer_ziplog(){
	zipname=rfsync_${drivername}_`date +"%Y%m%d-%H%M%S"`.zip
	zip -q "ziplogs/$zipname" logs/*
	
	$DIALOG --backtitle "$backtitle | $VERSION" \
	--title "\Z1$ziplog_title\Zn" --clear --trim --cr-wrap\
	--colors   \
	--msgbox "$message_logs$zipname" 12 70 2> $tempfile
	
}

info(){
   if [ "$LOG_LEVEL" -eq $INFO ]
	then
		echo "$(date +"%Y/%m/%d %H:%M:%S") [INFO] $@" >> $LOG_FILE
	fi
}

error(){
	echo "$(date +"%Y/%m/%d %H:%M:%S") [ERROR] $@" >> $LOG_FILE
}

charger_langue(){
    if [ "$lang" = "FR" ]
    then
        . "$CURPATH/FR"
    fi
    if [ "$lang" = "EN" ]
    then
        . "$CURPATH/EN"
    fi
	info "Langue $lang chargee"
}

about(){
	$DIALOG --backtitle "$backtitle | $VERSION" \
		--title "$intro_title" --clear --trim --cr-wrap\
		--msgbox "$about" 28 95 2> $tempfile
		
				#--no-cancel  \
		#--exit-label "OK" \
		#--textbox "$CURPATH/$about" 15 95 2> $tempfile
}

verifier_mdp(){	
	info "Verification du mot de passe"
	$DIALOG --backtitle "$backtitle | $VERSION" \
	--title "$patience" \
	--infobox "\n$mdp1" 5 61 2> $tempfile
	
	rsync -q rsync://$rsyncd_host:/$rsyncd_module
	retval=$?
	if [ $retval -eq 5 ]
	then
		error "Mot de passe errone"
		if [ "$RSYNC_PASSWORD"="na" ]
		then
			choisir_langue
		fi
		$DIALOG --backtitle "$backtitle | $VERSION" \
			--title "$mdp_title" --clear \
			--cancel-label "$quitter" \
			--inputbox "\n\n$mdp_text  " 20 61 2> $tempfile
		retval=$?

		case $retval in
		  0)
			RSYNC_PASSWORD=`cat $tempfile`
			verifier_mdp;;
		  1)
			sortir;;
		  255)
			sortir;;
		esac
	else
		info "Mot de passe accepte"
	fi
}

changer_realfeel(){
	case $1 in
	0) 
		info "Activation REALFEEL"
		$DIALOG --backtitle "$backtitle | $VERSION" \
		--title "$realfeel_title" \
		--infobox "\n$realfeel1" 5 61 2> $tempfile
		mv "$RFACTOR_PATH/Plugins/RealFeelPlugin.dll.bak" "$RFACTOR_PATH/Plugins/RealFeelPlugin.dll"
	;;
	1)	
		info "Desactivation REALFEEL"
		$DIALOG --backtitle "$backtitle | $VERSION" \
		--title "$realfeel_title" \
		--infobox "\n$realfeel2" 5 61 2> $tempfile
		mv "$RFACTOR_PATH/Plugins/RealFeelPlugin.dll" "$RFACTOR_PATH/Plugins/RealFeelPlugin.dll.bak"
	;;
	[8-9])
		info "Installation REALFEEL"
		$DIALOG --backtitle "$backtitle | $VERSION" \
		--title "$realfeel_title" \
		--infobox "\n$realfeel3" 5 61 2> $tempfile
		$RSYNC_SIG --log-file=$LOG_RSYNC --files-from=:Packs/realfeel.addon rsync://$rsyncd_host:/$rsyncd_module/addons/realfeel "$RFACTOR_PATH"
	;;
	esac
	realfeel=`realfeel_etat;echo $?`
	menu_principal
}
realfeel_etat(){
	#verifier_signature '4.md5'
	if [ -f "$RFACTOR_PATH/Plugins/RealFeelPlugin.dll"  ]
	then
		is_realfeel=`verifier_signature '10.md5'; echo $? `
		if [ "$is_realfeel" -eq 0 ]
		then
			info "realfeel actif"
			return 1
		else
			error "realfeel mauvaise version"
			return 8
		fi
	else
		if [ -f "$RFACTOR_PATH/Plugins/RealFeelPlugin.dll.bak"  ]
		then
			info "realfeel inactif"
			return 0
		else
			info "realfeel non installe"
			return 9
		fi
	fi
}

menu_principal(){
charger_langue


case $realfeel in
0)realfeel_action="$realfeel_etat0 ($realfeel_action0)";;
1)realfeel_action="$realfeel_etat1 ($realfeel_action1)";;
8)realfeel_action="$realfeel_etat8 ($realfeel_action8)";;
9)realfeel_action="$realfeel_etat9 ($realfeel_action9)";;
esac

# BEGIN CUSTON MENU
menu_array=('Sync' "$menu_item1")

if [ "$enable_menu_join" = "true" ]
then

	menu_array[${#menu_array[*]}]='Join'
	menu_array[${#menu_array[*]}]="$menu_join"
fi

if [ "$enable_menu_addons" = "true" ]
then
	menu_array[${#menu_array[*]}]='Addons'
	menu_array[${#menu_array[*]}]="$menu_item2"
fi
if [ "$enable_menu_rfe" = "true" ]
then

	menu_array[${#menu_array[*]}]='RFE'
	menu_array[${#menu_array[*]}]="$rfe_action"
fi
if [ "$enable_menu_realfeel" = "true" ]
then

	menu_array[${#menu_array[*]}]='RealFeel'
	menu_array[${#menu_array[*]}]="$realfeel_action"
fi
if [ "$enable_menu_tools" = "true" ]
then
	menu_array[${#menu_array[*]}]='Tools'
	menu_array[${#menu_array[*]}]="$menu_item3"
fi

# END CUSTOM MENU


$DIALOG --cancel-label "$quitter" --backtitle "$backtitle | $VERSION" \
    --colors --title "$menu_principal_title" --clear \
        --menu "\n\n$menu_principal1" 20 65 9 \
        "${menu_array[@]}" \
        "Changelog"    "$menu_item4" \
        "Lang"    "$menu_item5"       \
		"About" "$menu_item6" 2> $tempfile

retval=$?

choice=`cat $tempfile`
case $retval in
  0)
    case "$choice" in
    "Sync")
        synchroniser;;
	"Join")
        joindre;;
    "Addons")
        installer_addons;;
    "RealFeel")
        changer_realfeel $realfeel;;
	"Tools")
		menu_outils;;
    "Changelog")
        afficher_changelog;;
    "Lang")
        changer_langue	
		menu_principal;;
	"About")
		about
		menu_principal;;
    esac;;
  1)
    sortir;;
  255)
    sortir;;
esac

}

menu_outils(){

$DIALOG --cancel-label "$retour" --backtitle "$backtitle | $VERSION" \
    --colors --title "$menu_outil_title" --clear \
        --menu "\n\n$menu_outil1" 20 61 7 \
        "Ziplog"  "$menuoutil_item1" \
        "Plr"    "$menuoutil_item2" \
		"Multiplayer" "$menuoutil_item3" \
		"UI" "$menuoutil_item4" 2> $tempfile

retval=$?

choice=`cat $tempfile`
case $retval in
  0)
    case "$choice" in
    "Ziplog")
		creer_ziplog
		menu_principal
        ;;
    "Plr")
		dialog --backtitle "$backtitle | $VERSION" \
		--cancel-label "$retour" --title "$menu_outil_title" --colors \
		--form "\n$menu_outil_plr \Zr\Z0$drivername\Zn" 25 80 15 \
		"Headlights On Cars (1 to activate) :" 1 1 "`gawk -F '=' '/Headlights On Cars/ { print $2 }' "$last_plr" | gawk -F '"' '{ print $2 }'`" 1 50 2 1  \
		"Max Headlights (min=2, <8):" 2 1 "`gawk -F '=' '/Max Headlights/ { print $2 }' "$last_plr" | gawk -F '"' '{ print $2 }'`" 2 50 3 2 \
		"Virtual Mirror In Cockpit (1 to activate) :" 4 1 "`gawk -F '=' '/Virtual Rearview In Cockpit/ { print $2 }' "$last_plr" | gawk -F '"' '{ print $2 }'`" 4 50 2 1 \
		"Mirrors (1=center&side,2=center,3=sides) :" 5 1 "`gawk -F '=' '/Rearview/ { print $2 }' "$last_plr" | gawk -F '"' '{ print $2 }'`" 5 50 2 1 2>/tmp/form.1
		
		retval=$?

		choice=`cat $tempfile`
		case $retval in
		  0)
			value1=`head -1 /tmp/form.1 | tail -1`
			value2=`head -2 /tmp/form.1 | tail -1`
			value3=`head -3 /tmp/form.1 | tail -1`
			value4=`head -4 /tmp/form.1 | tail -1`

			gawk -F '"'  -v val="$value1" '/Headlights On Cars=/ { sub($2, val); print; next}1' "$last_plr" > "tmp/$plr_filename.1"
			gawk -F '"'  -v val="$value2" '/Max Headlights=/ { sub($2, val); print; next}1' "tmp/$plr_filename.1" > "tmp/$plr_filename.2"
			gawk -F '"'  -v val="$value3" '/Virtual Rearview In Cockpit=/ { sub($2, val); print; next}1' "tmp/$plr_filename.2" > "tmp/$plr_filename.3"
			gawk -F '"'  -v val="$value4" '/Rearview=/ { sub($2, val); print; next}1' "tmp/$plr_filename.3" > "tmp/$plr_filename.4"
			mv "tmp/$plr_filename.4" "$last_plr"
			menu_outils;;
		  1)
			menu_outils;;
		  255)
			menu_outils;;
		esac	
		;;
    "Multiplayer")
        dialog --backtitle "$backtitle | $VERSION" \
		--cancel-label "$retour" --title "$menu_outil_title" \
		--form "\n$menu_outil_multiplayer" 25 80 16 \
		"Concurrent Server Updates (1000):" 1 1 "`gawk -F '=' '/Concurrent Server Updates/ { print $2 }' "$last_multiplayer" | gawk -F '"' '{ print $2 }'`" 1 35 5 4 2>/tmp/form.1
		
		retval=$?

		choice=`cat $tempfile`
		case $retval in
		  0)
			value1=`head -1 /tmp/form.1 | tail -1`

			gawk -F '"'  -v val="$value1" '/Concurrent Server Updates/ { sub($2, val); print; next}1' "$last_multiplayer" > "tmp/$drivername_multi.1"
			mv "tmp/$drivername_multi.1" "$last_multiplayer"
			menu_outils;;
		  1)
			menu_outils;;
		  255)
			menu_outils;;
		esac	
		;;
	"UI")
		$DIALOG --ok-label "Synchroniser" --backtitle "$backtitle | $VERSION" \
		--title "$ui_title" --clear \
		--cancel-label "$annuler" \
			--radiolist "\n\n$ui" 20 61 5 \
			"1" "$ui_item2" "ON" \
		2> $tempfile
			retval=$?
		#"1" "$ui_item1" "$ui_state1" \
		
		choice=(`cat $tempfile`)
		case $retval in
		0)
			trap 'rapporter_erreur 1 $LINENO $?' ERR
			ui_state1="OFF"
			ui_state2="OFF"
			for item in ${choice[*]}
			do
				case $item in
				1)
					info "Choix UI rfactor"
					ui_state2="ON"
					UI="RFACTOR"
					$RSYNC --log-file=$LOG_RSYNC --files-from=:Addons/ui_rfactor.addons rsync://$rsyncd_host:/$rsyncd_module/addons/ui_rfactor "$RFACTOR_PATH"				
					;;
			#	2)
			#		info "Choix UI HD"
			#		ui_state1="ON"
			#		UI="HD"
			#		# UI sur 1: HD
			#		$RSYNC --log-file=$LOG_RSYNC --files-from=:Addons/ui_hd.addons rsync://$rsyncd_host:/$rsyncd_module/addons/ui_hd "$RFACTOR_PATH"
			#		;;

				esac
			done
			menu_outils;;
		  1)
			menu_outils;;
		  255)
			menu_outils;;
		esac	
		;;
    esac;;
  1)
    menu_principal;;
  255)
    sortir;;
esac
}

choisir_langue(){
charger_langue

$DIALOG --cancel-label "$quitter" --backtitle "$backtitle | $VERSION" \
		--ok-label "$changer" \
		--extra-button --extra-label "$continuer"\
    --title "$choisir_langue_title" --clear \
        --menu "\n\n$choisir_langue1" 20 61 2 \
        "Lang"    "$menu_item5"        2> $tempfile

retval=$?

choice=`cat $tempfile`
case $retval in
  0)
    case "$choice" in
      
    "Lang")
        changer_langue
		choisir_langue
    esac;;
  1)
    sortir;;
  255)
    sortir;;
esac

}

joindre(){
	info "Recuperation de la liste des serveurs"
	serverslist=""
	n=0
	games_exes_array=()
	server_names_array=()
	server_ips_array=()
	server_ports_array=()
	server_pwds_array=()
	for lineserver in $(cat "$CURPATH/conf/serverslist.conf")
	do
		n=$[n+1]
		server=`echo $lineserver |  gawk -F':' '{print $2}'`
		games_exes_array[${#games_exes_array[*]}]=`echo $lineserver |  gawk -F':' '{print $1}'`
		server_names_array[${#server_names_array[*]}]=$server
		server_ips_array[${#server_ips_array[*]}]=`echo $lineserver |  gawk -F':' '{print $3}'`
		server_ports_array[${#server_ports_array[*]}]=`echo $lineserver |  gawk -F':' '{print $4}'`
		server_pwds_array[${#server_pwds_array[*]}]=`echo $lineserver |  gawk -F':' '{print $5}'`
		serverslist="$serverslist $n $server"
	done
	servernum=$n

    $DIALOG --ok-label "Joindre" --backtitle "$backtitle | $VERSION" \
    --title "$joindre_title" --clear \
	--cancel-label "$annuler" \
        --menu "\n\n$joindre1" 20 61 7 $serverslist \
	2> $tempfile
        retval=$?

    choice=(`cat $tempfile`)
    case $retval in
    0)
		cd $RFACTOR_PATH
		if [ "${server_pwds_array[${choice[0]}-1]}" = "" ]
		then
			echo "start /b ${games_exes_array[${choice[0]}-1]} +connect ${server_ips_array[${choice[0]}-1]}:${server_ports_array[${choice[0]}-1]} +fullproc" > "join.bat"
		else
			echo "start /b ${games_exes_array[${choice[0]}-1]} +connect ${server_ips_array[${choice[0]}-1]}:${server_ports_array[${choice[0]}-1]} +password \"${server_pwds_array[${choice[0]}-1]}\" +fullproc" > "join.bat"
		fi
		echo "exit" >> "join.bat"
		cmd /C "join.bat"
		sortir
    ;;
  1)
    menu_principal;;
  255)
    menu_principal;;
	esac
}



synchroniser(){

# Si premier lancement de loutil de synchro
if ! [ -f "$CURPATH/tmp/seasonssync" ]
then
	n=0
	# On initialise tous les choix a "off"
	for lineseason in $(cat "$CURPATH/conf/seasons.conf")
	do
		n=$[n+1]
		seasonlist_sync[$n]="off"
	done
	seasonnum_sync=$n
	info "Mise a jour premier lancement seasonssync"
	md5sum "$CURPATH/conf/seasons.conf" > "$CURPATH/tmp/seasonslist.md5"

else
	besoin_maj_seasonslist=`md5sum -c "$CURPATH/tmp/seasonslist.md5" --strict --status; echo $? `
	if [ "$besoin_maj_seasonslist" -eq 0 ]
	then
		info "Mise a jour seasonslist non necessaire"
		# On charge les choix precedents
		seasonlist_sync=""
		n=0
		for lineseason_sync in $(cat "$CURPATH/tmp/seasonssync")
		do
			n=$[n+1]
			seasonlist_sync[$n]="$lineseason_sync"
		done
		seasonnum_sync=$n
	else
		# On initialise tous les choix a "off"
		info "Mise a jour seasonslist necessaire"
		n=0

		for lineseason in $(cat "$CURPATH/conf/seasons.conf")
		do
			n=$[n+1]
			seasonlist_sync[$n]="off"
		done
		seasonnum_sync=$n
		info "Mise a jour seasonssync"
		md5sum "$CURPATH/conf/seasons.conf" > "$CURPATH/tmp/seasonslist.md5"
	fi

fi

seasonlist=""
n=0
for lineseason in $(cat "$CURPATH/conf/seasons.conf")
do
    n=$[n+1]
	season=`echo $lineseason |  gawk -F':' '{print $1}'`
	seasonlist="$seasonlist $n $season ${seasonlist_sync[$n]}"
done
seasonnum=$n

    $DIALOG --ok-label "Synchroniser" --backtitle "$backtitle | $VERSION" \
    --title "$synchroniser_title" --clear \
	--cancel-label "$annuler" \
        --checklist "\n\n$synchroniser1" 20 61 7 $seasonlist \
	2> $tempfile
        retval=$?

    choice=(`cat $tempfile`)
    case $retval in
    0)
		trap 'rapporter_erreur 1 $LINENO $?' ERR
		
		seasonlist_postsync=""
		n=0
		for lineseason in $(cat "$CURPATH/conf/seasons.conf")
		do
			n=$[n+1]
			seasonlist_postsync[$n]="off"
		done
		

        for item in ${choice[*]}
        do
			seasonlist_postsync[$item]="on"
			info "Synchronisation choix $item"
			seasonline=`gawk -v line="$item" 'NR == line' "$CURPATH/conf/seasons.conf"`
			moddir=`echo $seasonline | gawk -F':' '{print $2}'`
			modfile=`echo $seasonline | gawk -F':' '{print $3}'`
			tracksfile=`echo $seasonline | gawk -F':' '{print $4}'`
			addonfiles=`echo $seasonline | gawk -F':' '{print $5}'`
			addondir=`echo $addonfiles | gawk -F'.addon' '{print $1}'`
			info "modfile: $modfile , moddir: $moddir, tracksfile: $tracksfile, addonfiles: $addonfiles"
			$RSYNC --delete-during --log-file=$LOG_RSYNC --files-from=:Packs/$tracksfile rsync://$rsyncd_host:/$rsyncd_module/tracks "$RFACTOR_PATH/Gamedata/Locations/"
			$RSYNC --delete-during --log-file=$LOG_RSYNC --files-from=:Packs/$modfile rsync://$rsyncd_host:/$rsyncd_module/mods/$moddir "$RFACTOR_PATH"
			if [ "$addonfiles" != "" ]
			then
				$RSYNC --log-file=$LOG_RSYNC --files-from=:Addons/$addonfiles rsync://$rsyncd_host:/$rsyncd_module/addons/$addondir "$RFACTOR_PATH"
			fi
        done
		
	
		for n in ${seasonlist_postsync[@]:1}
		do
			echo $n
		done > "$CURPATH/tmp/seasonssync"
		trap - ERR  

    ;;
  1)
    menu_principal;;
  255)
    menu_principal;;
	esac

	if [ ${#choice[*]} -ne 0 ]
	then
		info "Synchronisation reussie"	
		$DIALOG --backtitle "$backtitle | $VERSION" \
			--title "$synchro_title" --clear \
			--msgbox "\n\n$synchro_reussie_text" 9 40 2> $tempfile
	else
		info "Aucun choix de synchronisation"	
		$DIALOG --backtitle "$backtitle | $VERSION" \
			--title "$synchro_title" --clear \
			--msgbox "\n\n$synchro_manquechoix_text" 9 40 2> $tempfile	
	fi
	menu_principal
}

sauver_prefs(){
	info "Sauvegarde des prefs"
	declare -p sync_state1 > "$CURPATH/params"
	declare -p sync_state2 >> "$CURPATH/params"
	declare -p ui_state1 >> "$CURPATH/params"
	declare -p ui_state2 >> "$CURPATH/params"
	declare -p lang >> "$CURPATH/params"
	declare -p RSYNC_PASSWORD >> "$CURPATH/params"
	declare -p LOGNAME >> "$CURPATH/params"
	declare -p MD5_UPDATE >> "$CURPATH/params"
	declare -p UPDATE_ENABLE >> "$CURPATH/params"
	declare -p UI >> "$CURPATH/params"
}
    
installer_addons(){
    # DIALOG, afficher liste des addons installable (indiquer état installé?)
    echo TODO addons
	menu_principal
}
    
afficher_changelog(){
	info "Affichage changelog"
	$DIALOG --backtitle "$backtitle | $VERSION" \
	--title "$changelog_title" \
	--infobox "\n$changelog1" 5 61 2> $tempfile
	$RSYNC_SIG --log-file=$LOG_RSYNC rsync://$rsyncd_host:/$rsyncd_module/Changelog-rfsync.txt "$CURPATH/tmp/Changelog.txt"
	$DIALOG --backtitle "$backtitle | $VERSION" \
	--title "$changelog_title" --scrollbar \
	--exit-label "OK" \
	--textbox "$CURPATH/tmp/Changelog.txt" 35 90 2> $tempfile
	menu_principal
}

changer_langue(){
	
    if [ "$lang" = "FR" ]
    then
        lang="EN"
    else
        if [ "$lang" = "EN" ]
        then
            lang="FR"
        fi
    fi
	info "Changement de langue pour $lang"
    sauver_prefs
}

sortir(){
    sauver_prefs
	info "Sortie"
	exit
}

verifier_signature(){
	# $1: fichier signature
	trap 'rapporter_erreur 2 $LINENO $?' ERR
	$RSYNC_SIG --log-file=$LOG_RSYNC rsync://$rsyncd_host:/$rsyncd_module/signatures/$1 tmp/
	trap - ERR	
	cd "$RFACTOR_PATH"
	md5sum -c "$CURPATH/tmp/$1" --strict --status
	is_nok=$?
	cd "$CURPATH"
	rm -f tmp/$1
	info "Verification signature fichier $1=$1"
	return $is_nok
}
mise_a_jour()
{
	if [ $UPDATE_ENABLE -eq 1 ]
	then
		info "Debut mise a jour"
		$DIALOG --backtitle "$backtitle | $VERSION" \
		--title "$patience" \
		--infobox "\n$maj1" 5 61 2> $tempfile

	retval=$?

		if [ -f  "$CURPATH/tmp/script.md5" ]
		then
			$RSYNC_SIG --log-file=$LOG_RSYNC rsync://$rsyncd_host:/$rsyncd_module/rfsync/script.sh ./script.sh
			besoin_maj_script=`md5sum -c "$CURPATH/tmp/script.md5" --strict --status; echo $? `
			$RSYNC_SIG --log-file=$LOG_RSYNC rsync://$rsyncd_host:/$rsyncd_module/rfsync/conf/seasons.conf ./conf/seasons.conf
			besoin_maj_seasons=`md5sum -c "$CURPATH/tmp/seasons.md5" --strict --status; echo $? `
			$RSYNC_SIG --log-file=$LOG_RSYNC rsync://$rsyncd_host:/$rsyncd_module/rfsync/conf/server.conf ./conf/server.conf
			besoin_maj_server=`md5sum -c "$CURPATH/tmp/server.md5" --strict --status; echo $? `
			if [ "$besoin_maj_script" -eq 0 ]  && [ "$besoin_maj_seasons" -eq 0 ] && [ "$besoin_maj_server" -eq 0 ]
			then
				info "Mise a jour non necessaire"
			else
				info "Mise a jour necessaire"
				$DIALOG --backtitle "$backtitle | $VERSION" \
				--title "$patience" \
				--infobox "\n$maj2" 5 61 2> $tempfile
					
				$RSYNC_SIG --log-file=$LOG_RSYNC --files-from=:Packs/rfsync.sync rsync://$rsyncd_host:/$rsyncd_module/rfsync/ "$RFACTOR_PATH/rfsync/"
				md5sum "$CURPATH/script.sh" > "$CURPATH/tmp/script.md5"
				md5sum "$CURPATH/conf/seasons.conf" > "$CURPATH/tmp/seasons.md5"
				md5sum "$CURPATH/conf/server.conf" > "$CURPATH/tmp/server.md5"
				sauver_prefs
				"$RFACTOR_PATH/rfsync/script.sh"
				exit
			fi			
			
		else
			# premier lancement, on force la maj, puis on fait le md5 du fichier update
			info "Mise a jour premier lancement"
			$RSYNC_SIG --log-file=$LOG_RSYNC --files-from=:Packs/rfsync.sync rsync://$rsyncd_host:/$rsyncd_module/rfsync/ "$RFACTOR_PATH/rfsync/"
			md5sum "$CURPATH/script.sh" > "$CURPATH/tmp/script.md5"
			md5sum "$CURPATH/conf/seasons.conf" > "$CURPATH/tmp/seasons.md5"
			md5sum "$CURPATH/conf/server.conf" > "$CURPATH/tmp/server.md5"
			sauver_prefs
			"$RFACTOR_PATH/rfsync/script.sh"
			exit
			#sortie
		fi
		info "Fin mise a jour"
	else
		info "Mise a jour desactivee"
	fi
		

}

# MAIN
info "Lancement version $VERSION, rfactor installe dans $RFACTOR_PATH"
charger_langue
if [ "$rsyncd_password_needed" != "0" ]
	then verifier_mdp
else
	echo TODO
	# verifier_sansmdp
fi
mise_a_jour

ps -aW | grep rFactor.exe 1>/dev/null
is_rfactor_running=`echo $?`
if [ $is_rfactor_running -eq 0 ]
	then rapporter_erreur 12
fi
realfeel=`realfeel_etat;echo $?`
menu_principal "firsttime"
