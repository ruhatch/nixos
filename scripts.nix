# Various useful scripts, installed as system packages

{ pkgs, ... }:

let

  # 'show-clock' shows an xclock that disappears when it loses focus
  show-clock = pkgs.writeScriptBin "show-clock" ''
    ${pkgs.xorg.xclock}/bin/xclock -digital -brief -padding 75 &

    while [ true ]
    do
      sleep 1
      window=`xdotool getwindowfocus getwindowname`
      if [ "$window" != "xclock" ]; then
        pkill -9 xclock
        exit
      fi
    done
  '';

  # 'focus' is a small script to set a focus in xmobar
  focus = pkgs.writeScriptBin "focus" ''
    xprop -root -f focus 8s -set focus "$*"
  '';

  pom = pkgs.writeScriptBin "pom" ''
    writeToTimer(){
      xprop -root -f pom-timer 8s -set pom-timer "$1"
    }

    countdown(){
      date1=$((`date +%s` + $1));
      while [ "$date1" -ge `date +%s` ]; do
        writeToTimer "$(date -u --date @$(($date1 - `date +%s`)) +%H:%M:%S)";
        sleep 0.1
      done
    }

    killPom(){
      if [ $(pgrep -c -f "pom ") -ge 2 ]; then
        kill -9 $(pgrep -f "pom " | head -n -2)
      fi
    }

    printUsage(){
      echo "pom [start|break|long-break|stop]"
    }

    if [ -n "$1" ]; then
      case "$1" in
        "start")
          killPom
          countdown $((25 * 60))
          writeToTimer "<action=\`pom break\` button=1>Pom finished. Start a break?</action>"
          gxmessage -geometry 600x400 -center "Pomodoro finished!"
          ;;
        "break")
          killPom
          countdown $((5 * 60))
          writeToTimer "<action=\`pom start\` button=1>Break finished. Start another pom?</action>"
          gxmessage -geometry 600x400 -center "Break finished!"
          ;;
        "long-break")
          killPom
          countdown $((20 * 60))
          writeToTimer "<action=\`pom start\` button=1>Break finished. Start another pom?</action>"
          gxmessage -geometry 600x400 -center "Break finished!"
          ;;
        "stop")
          killPom
          writeToTimer "<action=\`pom start\` button=1>Start a pomodoro</action>"
          ;;
        *) printUsage ;;
      esac
    else
      printUsage
    fi
  '';

in
{
  environment.systemPackages = [show-clock focus pom];
}
