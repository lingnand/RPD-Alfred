#! /bin/bash

FMC="$(dirname "$0")/fmc.sh"

usage() {
    cat << END
    help          -- print this help message
    artist(%a)    -- get the artist name
    song(%s)      -- get song name
    channel(%c)   -- get channel name
    currtime(%t)  -- get the current playing time
    totaltime(%l) -- get the total playing time
    status(%u)    -- get the current status of the player (one of 'Playing', 'Paused', 'Stopped', 'Error')
    quality(%q)   -- get the current bitrate of the player
    <a format string> -- a format string containing the specifiers listed above
    like          -- return exit status indicating if the song is liked or not
END
}

oldIFS=$IFS
IFS=$'\n'
lines=(`"$FMC" 2>/tmp/fmcerr`)

like=false
if [ -n "`cat /tmp/fmcerr`" ]; then
    status=Error
elif [ -n "${lines[0]}" ]; then
    status=${lines[0]%% - *}
    status=${status#FMD }
    channel=${lines[0]##* - }
    bitrate="`"$FMC" quality`"
fi

if (( ${#lines[@]} == 4 )); then
    artist=${lines[1]%% - *}
    if [[ "$artist" =~ \[Like\] ]]; then
        like=true
        artist=${artist#\[Like\] }
    fi
    song=${lines[1]##* - }
    curr_time=${lines[2]%% / *}
    total_time=${lines[2]##* / }
fi

case $1 in
    channel) echo "$channel";;
     artist) echo "$artist";;
       song) echo "$song";;
   currtime) echo "$curr_time";;
  totaltime) echo "$total_time";;
       like) $like && exit 0 || exit 2;;
     status) echo "$status";;
    quality) echo "$bitrate";;
       help) usage;;
          *) 
              if [ -n "$1" ] && [ -n "$status" ]; then
                  f=$1
                  f=${f//\%u/"$status"}
                  f=${f//\%a/"$artist"}
                  f=${f//\%s/"$song"}
                  f=${f//\%c/"$channel"}
                  f=${f//\%t/"$curr_time"}
                  f=${f//\%l/"$total_time"}
                  f=${f//\%q/"$bitrate"}
                  echo -e "$f"
              fi
              ;;
esac

IFS=$oldIFS
