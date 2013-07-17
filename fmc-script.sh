#!/bin/bash
# set up the global variables 

FMC="$(dirname "$0")/fmc.sh"
FMCINFO="$(dirname "$0")/fmcinfo.sh"

cat << EOB
<?xml version="1.0"?>
<items>
EOB

orig="$1"
commands=( 'play' 'pause' 'toggle' 'next' 'channels' 'launch' 'rate' 'unrate' 'ban' 'quality')
descs=( '' '' 'toggle the status of the song' 'skip to the next song' 'select a channel' 'restart the fmd daemon' 'rate the current song' 'unrate the current song' 'ban the current song' 'change the bitrate' )
icons=( 'play.png' 'pause.png' 'toggle.png' 'next.png' 'channel.png' 'restart.png' 'liked.png' 'like.png' 'ban.png' 'quality.png' )
validity=( 'yes' 'yes' 'yes' 'yes' 'no' 'yes' 'yes' 'yes' 'yes' 'no' )

if [ -n "$orig" ]; then
    # first need to cut the space out
    orig=${orig# }
    # we will grep through the available commands
    case "$orig" in
        channels*)
            #need to show the list of channels
            # just hold the content in an array is find
            oldIFS=$IFS
            IFS=$'\n'
            channels=(`"$FMC" channels`)
            IFS=$oldIFS
            channels_names=(${channels[@]##* })
            channels_ids=(${channels[@]% *})
            # the four lines below are really there as a hack; the problem is that there can be at most two spaces in front of each lines, which is ANNOYING
            shopt -s extglob
            channels_ids=(${channels_ids[@]##*( )})
            # get the search terms
            channel_search=${orig#channels}
            channel_search=${channel_search##*( )}
            channel_search=${channel_search%%*( )}
            shopt -u extglob
            for (( j=1; j<${#channels[@]}; j++ ))
            do
                if [[ "${channels[$j]}" = *"$channel_search"* ]]; then
                    cat << EOB
                      <item uid="fmc channel" arg="setch ${channels_ids[$j]}" autocomplete=" channels ${channels_ids[$j]}">
                        <title>${channels_names[$j]}</title>
                        <subtitle></subtitle>
                        <icon>channel.png</icon>
                      </item>
EOB
                fi
            done
            ;;
        quality*)
            quality_search=${orig#quality }
            shopt -s extglob
            quality_search=${orig#quality}
            quality_search=${quality_search##*( )}
            quality_search=${quality_search%%*( )}
            shopt -u extglob
            for bit in 64 128 192
            do
                if [[ "$bit" = "$quality_search"* ]]; then
                    [ "$bit" != '64' ] && exp="$bit kbps (Paid)" || exp="$bit kbps"
                    cat << EOB
                      <item uid="fmc quality" arg="quality $bit" autocomplete=" quality $bit">
                        <title>$exp</title>
                        <subtitle></subtitle>
                        <icon>quality.png</icon>
                      </item>
EOB
                fi
            done
            ;;
        *)
            for (( i=0; i<${#commands[@]}; i++ ))
            do
                if [[ "${commands[$i]}" = "$orig"* ]]; then
                        cat << EOB
                          <item uid="fmc command" arg="${commands[$i]}" autocomplete=" ${commands[$i]}" valid="${validity[$i]}">
                            <title>${commands[$i]}</title>
                            <subtitle>${descs[$i]}</subtitle>
                            <icon>${icons[$i]}</icon>
                          </item>
EOB
                fi
            done
            ;;
    esac
else 
    oldIFS=$IFS
    IFS=$'\n'
    QUERY=(`"$FMCINFO" '%u\n%c\n%s\n%a\n%q';"$FMCINFO" like`)
    if (( $? == 0 )); then
        like_cmd='unrate'
        like_title='Liked'
        like_icon='liked.png'
    else
        like_cmd='rate'
        like_title='Like'
        like_icon='like.png'
    fi
    IFS=$oldIFS
    STATUS=${QUERY[0]}
    CHANNEL=${QUERY[1]}
    SONG=${QUERY[2]}
    ARTIST=${QUERY[3]}
    QUALITY=${QUERY[4]}
    stopped=false
    toggle_command=toggle
    case "$STATUS" in
        Playing) 
            status_icon="play.png"
            toggle_icon="pause.png"
            ;;
        Paused)
            status_icon="pause.png"
            toggle_icon="play.png"
            ;;
        Stopped)
            stopped=true
            SONG=Stopped
            status_icon="stop.png"
            toggle_icon="play.png"
            ;;
        Error)
            stopped=true
            SONG=Disconnected
            status_icon="stop.png"
            toggle_icon="play.png"
            toggle_command='launch'
    esac

    if ! $stopped; then
        cat << EOB
          <item uid="fmc channel" autocomplete=" channels" valid="no">
            <title>$CHANNEL</title>
            <subtitle>$QUALITY kbps</subtitle>
            <icon>channel.png</icon>
          </item>
EOB
    fi

cat << EOB
      <item uid="fmc song" arg="toggle" autocomplete=" $toggle_command">
        <title>$SONG</title>
        <subtitle>$ARTIST</subtitle>
        <icon>$status_icon</icon>
      </item>
EOB
    if ! $stopped; then
        cat << EOB
          <item uid="fmc like" arg="$like_cmd" autocomplete=" $like_cmd">
            <title>$like_title</title>
            <subtitle></subtitle>
            <icon>$like_icon</icon>
          </item>
EOB
    fi
fi

echo '</items>'
