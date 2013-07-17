#! /bin/bash
# include a few more commands
DIR="$(dirname "$0")"
FMC="$DIR/fmc.sh"
# we need to get the correct bin variable
if [ -n "${FMC_BIN}" ]; then
    echo "${FMC_BIN}" > "$DIR/fmc_bin"
else
    FMC_BIN="`cat "$DIR/fmc_bin"`"
    FMC_BIN="${FMC_BIN:-fmc}"
fi
    
if [ -n "${FMD_BIN}" ]; then
    echo "${FMD_BIN}" > "$DIR/fmd_bin"
else
    FMD_BIN="`cat "$DIR/fmd_bin"`"
    FMD_BIN="${FMD_BIN:-fmd}"
fi

term="$@"
case "$1" in
  ''|info) 
          ## needs to add the bitrate information to the end
          "$FMC_BIN" 2>/tmp/fmcerr
          ## if the error output is not nil
          if [ -z "`cat /tmp/fmcerr`" ]; then
              bit="`"$FMC" quality`"
              echo "$bit kbps"
          else
              cat /tmp/fmcerr >&2
          fi
          ;;
    next) 
        "$FMC_BIN" skip
        ;;
    launch)
        killall fmd 1>/dev/null 2>&1
        sleep 1
        "$FMD_BIN" 1>/dev/null 2>&1
        ;;
    quality)
        # the second argument should tell the bitrate to change
        if (($# == 1)); then
            # display the current bitrate
            bitrate="`grep '^kbps.*' ~/.fmd/fmd.conf`"
            bitrate="${bitrate##*=}"
            shopt -s extglob
            bitrate="${bitrate##*( )}"
            bitrate="${bitrate%%*( )}"
            shopt -u extglob
            # trim the thing
            echo "${bitrate:-64}"
        elif [[ "$2" =~ (192|128|64) ]]; then
            [ "$2" = '64' ] && rep='' || rep="$2"
            sed -i '' -e 's/^kbps.*$/kbps = '"$rep"'/' ~/.fmd/fmd.conf
            "$FMC" launch
        else
            echo 'Wrong argument for bitrate. Only 64/128/192 are allowed.'
            exit 1
        fi
        ;;
    *) "$FMC_BIN" "$@"
        ;;
esac

