#!/bin/bash
#set -x
# toDo fix names with spaces (tmp cp ) for f in *\ *; do mv "$f" "${f// /_}"; done
red=$(tput setaf 1)
green=$(tput setaf 2)
reset=$(tput sgr0)
timestamp=$(date +"%d-%m-%Y_%T")
workdir=$(pwd)
destDir="$workdir"/transcodes_"$timestamp"
if [ -z "$1" ]
  then
    echo "${red}Usage:${green} -t transcode QUALITY -T transcode QUALITY (-a optional to set aspect), default framerate is 25 -r to change"
    echo "${red}-T${green}     To choose a folder for transcode files -t will make ${destDir} automagically" ${reset}
    echo "The script can remove spaces from filenames if dir is given and will also autodetect extention of all possible video files"
    echo "Usage $0 -t quality -T quality -a aspect -r framerate"
    echo "This script needs bash >=4 ffmpeg with none free codecs like faac libfdk_aac, tested on Debian jessie and Gentoo"
    echo "Writen by Tina Cochet"
    exit 1
fi
declare -a i
echo
read -p "${green}Give me some filenames or a directory, no spaces in names allowed!${reset}: " i
if [ -d "$i" ]; then 
 read -p "Remove spaces with _ ? y/n :" s
 if [[ $s == y ]] ; then
   cd "$i"
  for j in *; do n="${j// /_}"; [ -f "$n" ] || mv -- "$j" "$n"; done
 fi
 declare -a k=( $(find "$i" \( -name "*mp4" -o -name "*mpeg" -o -name "*mkv"   -o -name "*mov"  -o -name "*m4v" -o -name "*wmv" -o -name "*mxf" \)) )
  eval $(typeset -A -p k|sed 's/ k=/ i=/')
 fi
for f in ${i[@]}
  do
  while getopts 't:T:a:r:' OPTION
    do
    case $OPTION in

	  t) tflag=1
                tval="$OPTARG"
                if [[ ! -d "$destDir" ]]; then
                  mkdir "$destDir"
                fi
                cd $destDir
                ;;
          T) Tflag=1
                Tval="$OPTARG"
		read -p "full path to dir with files to transcode:" destDir
                ;;

          a) aflag=1
                aval="$OPTARG"
                ;;
          r) rflag=1
                rval="$OPTARG"
                ;;    
	  ?) printf "Usage: %s: [-d] [-t quality ]  [-T quality ]\n"  >&2
                exit 2
                ;;
    esac
  done
  shift $(($OPTIND - 1))

if [ "$Tflag" ]; then
  cd $destDir
  tval=$Tval
  tflag=1
fi
if [ "$tflag" ]
   then
   echo "${green}Starting transcode of ${f}, hold your horses and ${red}wait ....${reset}"
   quality="$tval"
   fullname=$(basename $f)
   ext=$(echo "${fullname##*.}")
   tmpname="${f##*/}"
   name=$(echo "${tmpname%.*}")

   ## cmd="pv ${f} | ffmpeg -loglevel warning -i pipe:0" # this causes issues if file has metadata at end like *.mov 
   function vtranscode {
       if [ "$aflag" ]; then
         aspect="-aspect ${aval}"
       fi
       if [ "$rflag" ]; then
         rate="-r ${rval}"
       else rate="-r 25"
       fi       
       startTime=${SECONDS}
       scale="trunc(oh*a/2)*2:${quality}"     
       ffmpeg -report -loglevel warning -i "${f}" ${transcodeOpts} ${aspect} ${rate} ${name}.mov && echo "${green}Transcode of $f ${red}Complete! and available in $destDir${reset}" ||  echo "${green}Transcode of $f ${red}Failed! ${reset}"
       endTime=${SECONDS}
       diffTime=$(expr ${endTime} - ${startTime})
       echo "${green}Transcode took: ${red}${diffTime} seconds${reset}"
  }
     if  [[ $ext == mpeg || $ext == m4v || $ext == mp4 || $ext == mkv || $ext == avi ]]
     then
       scale="trunc(oh*a/2)*2:${quality}"
       transcodeOpts=" -c:v prores_ks -profile:v 0 -q:v 0 -vf yadif=0:1,scale=${scale}  -c:a pcm_s16le -ar 48000 -timecode 00:00:00:00 -metadata title=${name} -metadata creation_time=now "
       vtranscode
     fi
fi
done
cd $workdir
