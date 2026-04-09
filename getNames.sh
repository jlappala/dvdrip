#!/bin/bash
. ./settings.conf

drive=""
sudo "$mountdvd"
drive=m

showname="default"
season=0
epname=""
epnum=0

if [[ -f "$manualinfofile" ]]; then
      showname=$(cat "$manualinfofile" | head -1)
      seasonnum=$(cat "$manualinfofile" | head -2 | tail -1)
      next_epnum=$(cat "$manualinfofile" | tail -1 )
else
   "$vlc_executable" dvdsimple:///M: --run-time=2 --play-and-exit --no-audio --intf dummy --no-video

   makemkvcon --robot --decrypt info  file:"$mountpoint" > "$discinfofile"

   showname=$(cat "$discinfofile" | grep [TC]INFO | grep -o \".*\" | sed 's/\"//g' | head -2 | tail -1 | sed 's/Season.*$//' | sed 's/Disc.[[:digit:]]*.*$//' | sed 's/[[:punct:]]*//g')


   #echo Is this ok as a show name: $showname
   #read ok
   ok="y"
   read -t 5 -p "Is this ok as a show name (y/n): $showname " ok
   echo

   if [[ $ok == "k" || $ok == "y" || $ok == "" ]]; then
      showname=$showname
   else
      showname=$(cat "$discinfofile" | grep mkv | grep -o \".*\" | sed 's/\"//g' | sed 's/.mkv$//' | head -1)
      ok="y"
      read -t 5 -p "Is this a better show name (y/n): $showname " ok
      echo
      if [[ $ok == "k" || $ok == "y" || $ok == "" ]]; then
        showname=$showname
      else
        echo Enter show name:
        read showname
        echo
      fi
   fi

   showname=$(echo $showname | sed 's/[[:space:]]*//g')


   season=$(cat "$discinfofile" | grep -o -e  'Season[[:space:]]*[[:digit:]]*' | head -1 | grep -o [[:digit:]]* | sed 's/[[:space:]]*//g')

   #echo Is this the correct season: $season
   #read ok
   ok="y"
   read -t 5 -p "Is this the correct season (y/n): $season " ok
   echo
   if [[ $ok == "k" || $ok == "y" || $ok == "" ]]; then
      seasonnum=$season
   else
      echo Enter season: 
      read seasonnum
      season="Season\ ${seasonnum}"
   fi

   #echo $seasonnum

fi
max_epnum=0

for i in ${seriesbase}/${showname}/Season\ ${seasonnum}/*; do
  curepnum=$( echo "$i" | grep -o -e 'S[[:digit:]]*E[[:digit:]]*' | sed 's/S[[:digit:]]E[0]*//')
  if [[ -n "$curepnum" && "$curepnum" -gt "$max_epnum" ]]; then
     max_epnum="$curepnum"
  fi
done

next_epnum=$((max_epnum + 1))
echo
echo Show: $showname 
echo Season: $seasonnum 
echo Next episode: $next_epnum

echo $showname >"$titleinfofile"
echo $seasonnum >> "$titleinfofile"
echo $next_epnum >> "$titleinfofile"

