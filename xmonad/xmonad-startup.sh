#!/bin/bash

#sleep 5
#trayer --transparent true --alpha 10 --tint 0x303030 --SetDockType true --SetPartialStrut true --height 24 &
xsetroot -cursor_name left_ptr
xscreensaver -no-splash &
unity-settings-daemon &
sleep 2
# fbpanel &
lxpanel &
killall gnome-screensaver
sleep 3
gnome-sound-applet &
volumeicon &
dropbox start &
nm-applet &
redshift &
skypeforlinux &
keepassxc &

#if [[ `hostname` != "krzys-desktop" ]]; then
indicator-cpufreq &
#fi

$HOME/.fehbg

xmodmap -e "remove Lock = Caps_Lock"
xmodmap -e "add Control = Caps_Lock"
xmodmap -e "remove Control = Control_R"
xmodmap -e "add Mod4 = Control_R"
cat | xmobar 0<&0 ## Redirect STDIN to xnomad
wait
