#!/bin/bash

#sleep 5
#trayer --transparent true --alpha 10 --tint 0x303030 --SetDockType true --SetPartialStrut true --height 24 &
xsetroot -cursor_name left_ptr
# xscreensaver -no-splash &
if [ -x $(command -v unity-settings-daemon) ]; then
    unity-settings-daemon &
else
    gnome-settings-daemon &
fi
# This is now being handled by gnome-panel, since we run in GNOME these days
# fbpanel &
# lxpanel &
# killall gnome-screensaver

/usr/lib/geoclue-2.0/demos/agent &
volumeicon &
# dropbox start &
nm-applet &
keepassxc &

#if [[ `hostname` != "krzys-desktop" ]]; then
indicator-cpufreq &
#fi

$HOME/.fehbg

sleep 1
redshift &

xmodmap -e "remove Lock = Caps_Lock"
xmodmap -e "add Control = Caps_Lock"
xmodmap -e "remove Control = Control_R"
xmodmap -e "add Mod4 = Control_R"
cat | xmobar 0<&0 ## Redirect STDIN to xnomad
wait
