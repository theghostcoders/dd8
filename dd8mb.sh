#!/bin/bash

if [[ -z "$1" ]]
then
    exit 1
fi

if [[ ! -f "$1" ]]
then
    exit 1
fi

base_filename=$(basename -- "$1")
base_filename="${base_filename%.*}"
filename=$base_filename
incr=0
while [[ -f $filename.mp4 ]]
do
    filename="${base_filename}-${incr}"
    incr=$(($incr + 1))
done

secs=$(ffprobe -i "$1" -show_entries format=duration -v quiet -of csv="p=0")
audio_kb=`echo "160*$secs" | bc`
if [[ "$2" == "-an" ]]
then
	audio_kb=0
fi
bitrate=`echo "(64000-$audio_kb)/$secs" | bc`
if [[ $bitrate -le 0 ]]
then
	echo "Video grande demais para reencodar..."
	if [[ "$2" != "-an" ]]
	then
		echo "Tente remover o audio usando \"-an\""
	fi
	exit 1
fi
bitrate=`echo "$bitrate*0.95" | bc`
bitrate="${bitrate}k"

ffmpeg -i "$1" -c:v libx264 -b:v $bitrate -an -pass 1 -f mp4 -y /dev/null
if [[ "$2" == "-an" ]]
then
	ffmpeg -i "$1" -c:v libx264 -b:v $bitrate -an -pass 2 "${filename}.mp4"
else
	ffmpeg -i "$1" -c:v libx264 -b:v $bitrate -c:a aac -b:a 160k -pass 2 "${filename}.mp4"
fi

pattern=".*ffmpeg2pass-[0-9]\.log.*"
files=$(ls)
for file in $files; do
    if [[ $file =~ $pattern ]]
    then
        rm $file
    fi
done

