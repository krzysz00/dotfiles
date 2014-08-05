#!/bin/bash

#sleep 5
#trayer --transparent true --alpha 10 --tint 0x303030 --SetDockType true --SetPartialStrut true --height 24 &
xscreensaver -no-splash &
gnome-settings-daemon &
sleep 3
# fbpanel &
lxpanel &
killall gnome-screensaver
sleep 1
gnome-sound-applet &
dropbox start &
nm-applet &
redshift &
keepassx -min -lock &
skype &
# volumeicon &

#if [[ `hostname` != "krzys-desktop" ]]; then
indicator-cpufreq &
#fi

feh --bg-fill /usr/share/backgrounds/warty-final-ubuntu.png

xmodmap -e "remove Lock = Caps_Lock"
xmodmap -e "add Control = Caps_Lock"
xmodmap -e "remove Control = Control_R"
xmodmap -e "add Mod4 = Control_R"
cat | xmobar 0<&0 ## Redirect STDIN to xnomad
wait
