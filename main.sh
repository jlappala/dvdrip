#!/bin/bash

. ./settings.conf

get_media_loaded() {
  "$powershell" -Command "(Get-CimInstance Win32_CDROMDrive | Where-Object {\$_.Drive -eq 'M:'}).MediaLoaded" 2>/dev/null | tr -d '\r'
}

increment_manualinfo_season() {

    if [[ ! -f "$manualinfofile" ]]; then
        echo "manualinfo.txt not found"
        return
    fi

    showname=$(sed -n '1p' "$manualinfofile")
    seasonnum=$(sed -n '2p' "$manualinfofile")
    next_epnum=$(sed -n '3p' "$manualinfofile")

    seasonnum=$((seasonnum + 1))

    {
        echo "$showname"
        echo "$seasonnum"
        echo "$next_epnum"
    } > "$manualinfofile"

    echo "Season advanced to $seasonnum"
}

wait_for_disc_or_quit() {
  echo "Insert disc to continue (press Q to quit, or S to advance the season count)"

  while true; do
    # non-blocking read (0.5s timeout)
    read -t 0.5 -n 1 key

    if [[ "$key" == "q" || "$key" == "Q" ]]; then
      echo "Exiting... Thanks!"
      exit 0
    fi

    if [[ "$key" == "s" || "$key" == "S" ]]; then
      increment_manualinfo_season
    fi

    if [ "$(get_media_loaded)" = "True" ]; then
      echo "Disc detected"
      return
    fi
  done
}

# start=$(get_media_loaded)
# echo $start
# while [[ $start = "False" ]]; do
#    sleep 2
#    start=$(get_media_loaded)
# done
# prev="False"

skipfirsttitle="${1:-no}"



while true; do
  wait_for_disc_or_quit
  disc_start_time=$(date +%s)
   first=1 
   echo "Starting the rip..."
   #drive=""
   sudo "$mountdvd"
   #drive="m"

   #Create the working dirs if not existing
   mkdir -p "$workdir_video"
   mkdir -p "$workdir_subs"


   "$vlc_executable" dvdsimple:///${drive_win} --run-time=1 --play-and-exit --no-audio --intf dummy --no-video
   echo "Snooping discs for naming stuff" | tee -a "$LOGFILE"
   ${scripts_base}/getNames.sh

   #makemkvcon --robot --decrypt info  file:/mnt/m | grep .mkv >test.txt
   echo "Ripping disc" | tee -a "$LOGFILE"
   makemkvcon --robot --decrypt mkv file:/mnt/${drive} all ${workdir_video}/ >> "$LOGFILE" 2>&1

   let count=1


   showname=$(cat "$titleinfofile" | head -1)
   seasonnum=$(cat "$titleinfofile" | head -2 | tail -1)
   next_epnum=$(cat "$titleinfofile" | tail -1 )


   for i in ${workdir_video}/* ; do
      title_start_time=$(date +%s)
      if [ "$skipfirsttitle" = "yes" ] && [ $first -eq 1 ]; then
        first=0
        echo "Skipping first title due to user argument."
        continue
      fi

      first=0
      #echo "Next ep: ${next_epnum}"
      echo "Processing file: ${i}" | tee -a "$LOGFILE"
      echo "Extracting subtitle streams" | tee -a "$LOGFILE"
      ffmpeg -i "$i" -map 0:s:m:language:eng? -map 0:s:m:language:fin? -c copy "${workdir_video}/subs${count}.mkv" >> "$LOGFILE" 2>&1
      outname=$(echo "$i" | sed 's_'${workdir_video}'/__' )
      outname="${showname}_S${seasonnum}E$(printf "%02d" "$next_epnum")"
      #echo $outname
      echo
      echo "Converting subtitles to .srt" | tee -a "$LOGFILE"
      echo
      tempOutName=temp
      #cmd="SubtitleEdit.exe /convert \"${workdir_video_win}\\subs${count}.mkv\" srt /ocrengine:tesseract /outputfilename=\"${workdir_subs_win}\\${outname}.srt\" && exit" 
      cmd="SubtitleEdit.exe /convert ${workdir_video_win}\\subs${count}.mkv srt /ocrengine:tesseract /outputfilename:${workdir_subs_win}\\${tempOutName}${count}.srt && exit" 
      
      #echo $cmd
      pushd "$workdir_video" > /dev/null
      $command_prompt /c "$cmd"
      popd > /dev/null
      #read cont
      echo "Renaming subtitle file ${outname}.srt" | tee -a "$LOGFILE"
      cd "$workdir_subs"
      mv "$workdir_subs/${tempOutName}${count}.srt" "$workdir_subs/${outname}.srt"
      #read cont
      rename 's/_S/ S/' *.srt
      #read cont
      echo "Converting ${i} to ${outname}.mp4" | tee -a "$LOGFILE"
      cd "$workdir_video"
      HandBrakeCLI --preset-import-file "$handbr_presets_file" --preset "$handbr_preset" --input "$i" --output "${workdir_video}/${outname}.mp4" --audio-lang-list "$langlist"  --all-audio  --subtitle-lang-list "$langlist" --all-subtitles --markers 2>&1| tee -a "$LOGFILE" | tr '\r' '\n' | stdbuf -oL grep -oE "^.* %.*ETA [0-9hms]+" | sed -E 's/(^.*)%.*ETA ([0-9hms]+).*/\1 % | ETA \2/' | while read -r line; do
          echo -ne "\r$line"
      done
      echo
      rename 's/_S/ S/' "${outname}.mp4"
      let count=$((count+1));
      let next_epnum=$((next_epnum+1));
      title_end_time=$(date +%s)
      title_duration=$((title_end_time - title_start_time))
      title_duration_min=$(((title_duration % 3600) / 60))
      title_duration_hr=$((title_duration / 3600))
      title_duration_sec=$((title_duration % 60))
      echo "Title took ${title_duration_hr}h ${title_duration_min}m ${title_duration_sec}s to process."
   done

   #clear working dir
   target_dir="${seriesbase}/${showname}/Season ${seasonnum}/"
   target_subs_dir="${target_dir}subtitles/"

   if [[ ! -d "$target_dir" ]]; then
      echo "Creating target directory: ${target_dir}"
      mkdir -p "$target_dir"
   fi

   if [[ ! -d "$target_subs_dir" ]]; then
      echo "Creating target subtitles directory: ${target_subs_dir}"
      mkdir -p "$target_subs_dir"
   fi


   echo "Starting to move mp4s" | tee -a "$LOGFILE"
   cd "$workdir_video"
   mv *.mp4 "$target_dir"
   echo "Detecting sub languages" | tee -a "$LOGFILE"
   ${scripts_base}/detect_lang.py "$workdir_subs"

   echo "Starting to move subs" | tee -a "$LOGFILE"
   cd "$workdir_subs"
   mv *.srt "$target_subs_dir"
   echo "Removing mkvs" | tee -a "$LOGFILE"
   cd "$workdir_video"
   for i in ${workdir_video}/*.mkv ; do
      outname=$(echo "$i" | sed 's_'${workdir_video}'/__' )
      rm "./${outname}"  
   done;
   cd "${scripts_base}"
   ${scripts_base}/myeject.sh ${drive}:
   disc_end_time=$(date +%s)
   disc_duration=$((disc_end_time - disc_start_time))
   hr=$((disc_duration / 3600))
   min=$(((disc_duration % 3600) / 60))
   sec=$((disc_duration % 60))
   echo "The whole disc took ${hr}h ${min}m ${sec}s to process"

done