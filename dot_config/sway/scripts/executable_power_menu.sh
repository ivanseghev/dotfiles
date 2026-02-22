#!/bin/bash
entries="Shutdown\nReboot\nSuspend\nLogout"
selected=$(echo -e $entries | wofi --dmenu --prompt="Power Menu" | awk '{print tolower($1)}')

case $selected in
  shutdown) systemctl poweroff ;;
  reboot) systemctl reboot ;;
  suspend) systemctl suspend ;;
  logout) swaymsg exit ;;
esac

