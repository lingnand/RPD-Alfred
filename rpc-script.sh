#!/bin/bash
# set up the global variables 

RPCBIN="rpc"

cat << EOB
<?xml version="1.0"?>
<items>
EOB

orig="$1"
commands=( 'play' 'pause' 'toggle' 'next' 'setch' 'launch' 'rate' 'unrate' 'ban' 'kbps')
descs=( '' '' 'toggle the status of the song' 'skip to the next song' 'select a channel' 'restart the fmd daemon' 'rate the current song' 'unrate the current song' 'ban the current song' 'change the bitrate' )
icons=( 'play.png' 'pause.png' 'toggle.png' 'next.png' 'channel.png' 'restart.png' 'liked.png' 'like.png' 'ban.png' 'quality.png' )
validity=( 'yes' 'yes' 'yes' 'yes' 'no' 'yes' 'yes' 'yes' 'yes' 'no' )

if [ -n "$orig" ]; then
    # first need to cut the space out
    orig=${orig# }
    # we will grep through the available commands
    case "$orig" in
        setch*)
            #need to show the list of channels
            # just hold the content in an array is find
            oldIFS=$IFS
            IFS=$'\n'
            channels=(`"$RPCBIN" channels`)
            IFS="$oldIFS"
            # get the search terms
            shopt -s extglob
            channel_search=${orig#setch}
            channel_search=${channel_search##*( )}
            channel_search=${channel_search%%*( )}
            shopt -u extglob
            found=false
            for (( j=1; j<${#channels[@]}; j++ ))
            do
                channel="${channels[$j]}"
                shopt -s extglob
                channel="${channel##*( )}"
                channel="${channel%%*( )}"
                shopt -u extglob
                if [[ "$channel" = *"$channel_search"* ]]; then
                    found=true
                    channel_id="${channel%% *}"
                    channel_name="${channel#* }"
                    cat << EOB
                      <item uid="rpc channel" arg="setch $channel_id" autocomplete="setch $channel_id">
                        <title>$channel_name</title>
                        <subtitle></subtitle>
                        <icon>channel.png</icon>
                      </item>
EOB
                fi
            done
            if ! $found; then
                cat << EOB
                  <item uid="rpc channel" arg="setch $channel_search" autocomplete="setch $channel_search">
                    <title>search Jing.fm for $channel_search</title>
                    <subtitle></subtitle>
                    <icon>channel.png</icon>
                  </item>
EOB
            fi
            ;;
        kbps*)
            shopt -s extglob
            quality_search=${orig#kbps}
            quality_search=${quality_search##*( )}
            quality_search=${quality_search%%*( )}
            shopt -u extglob
            for bit in 64 128 192
            do
                if [[ "$bit" = "$quality_search"* ]]; then
                    exp="$bit kbps"
                    cat << EOB
                      <item uid="rpc kbps" arg="kbps $bit" autocomplete="kbps $bit">
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
                          <item uid="rpc command" arg="${commands[$i]}" autocomplete="${commands[$i]}" valid="${validity[$i]}">
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
    QUERY=(`"$RPCBIN" info $'%u\n%c\n%t\n%a\n%k\n%r'`)
    IFS="$oldIFS"
    STATUS="${QUERY[0]}"
    CHANNEL="${QUERY[1]}"
    SONG="${QUERY[2]}"
    ARTIST="${QUERY[3]}"
    QUALITY="${QUERY[4]}"
    LIKE="${QUERY[5]}"
    stopped=false
    toggle_command=toggle
    if [ "$LIKE" = 1 ]; then
        like_cmd='unrate'
        like_title='Liked'
        like_icon='liked.png'
    else
        like_cmd='rate'
        like_title='Like'
        like_icon='like.png'
    fi
    case "$STATUS" in
        play) 
            status_icon="play.png"
            toggle_icon="pause.png"
            ;;
        pause)
            status_icon="pause.png"
            toggle_icon="play.png"
            ;;
        stop)
            stopped=true
            SONG=Stopped
            status_icon="stop.png"
            toggle_icon="play.png"
            ;;
        error)
            stopped=true
            SONG=Disconnected
            status_icon="stop.png"
            toggle_icon="play.png"
            toggle_command='launch'
    esac

    if ! $stopped; then
        cat << EOB
          <item uid="rpc channel" autocomplete="setch" valid="no">
            <title>$CHANNEL</title>
            <subtitle>$QUALITY kbps</subtitle>
            <icon>channel.png</icon>
          </item>
EOB
    fi

cat << EOB
      <item uid="rpc song" arg="toggle" autocomplete="$toggle_command">
        <title>$SONG</title>
        <subtitle>$ARTIST</subtitle>
        <icon>$status_icon</icon>
      </item>
EOB
    if ! $stopped; then
        cat << EOB
          <item uid="rpc like" arg="$like_cmd" autocomplete="$like_cmd">
            <title>$like_title</title>
            <subtitle></subtitle>
            <icon>$like_icon</icon>
          </item>
EOB
    fi
fi

echo '</items>'
