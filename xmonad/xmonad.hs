import XMonad
import XMonad.Hooks.ManageDocks
import XMonad.Hooks.DynamicLog
import XMonad.Util.EZConfig
import XMonad.Hooks.ManageHelpers
import XMonad.Hooks.EwmhDesktops
import XMonad.Layout.Minimize
import XMonad.Hooks.Minimize

main = do
--   spawn "sh /home/krzys/.xmonad/xmonad-startup.sh"
  xmonad =<< statusBar xmobar' myPP toggleStrutsKey (ewmh $ defaults)

xmobar' = "sh /home/krzys/.xmonad/xmonad-startup.sh"

myPP = xmobarPP { ppCurrent = (\x -> "<fc=green>" ++ x ++ "</fc>")
                , ppHidden = id
                , ppUrgent = (\x -> "<fc=red>" ++ x ++ "</fc>")
                , ppSep = " | "
                , ppWsSep = " "
                , ppTitle = shorten 40
                , ppOrder = (\(w:_:t:_) -> [w,t])
                }

toggleStrutsKey XConfig{modMask = modm} = (modm, xK_b )

myManageHook = composeAll [
  isFullscreen --> doFullFloat,
  className =? "VirtualBox" --> doFloat]

defaults =
  defaultConfig { modMask = mod4Mask
                , manageHook = myManageHook <+> manageHook defaultConfig
                , layoutHook = minimize (Tall 1 (3/100) (1/2)) ||| layoutHook defaultConfig
                , handleEventHook = minimizeEventHook <+> handleEventHook defaultConfig}
  `additionalKeysP` [("M-C-S-q", spawn "dbus-send --system --print-reply  --dest=\"org.freedesktop.UPower\" /org/freedesktop/UPower org.freedesktop.UPower.Suspend")
                    ,("M-C-q", spawn "dm-tool switch-to-greeter")
                    ,("M-S-l", spawn "xscreensaver-command -lock")
                    ,("M-m", withFocused minimizeWindow)
                    ,("M-S-m", sendMessage RestoreNextMinimizedWin)
                    ,("M-p", spawn "dmenu_run -fn Inconsolata-16:normal")
                    ,("<XF86MonBrightnessUp>", spawn "xbacklight -inc 10")
                    ,("<XF86MonBrightnessDown>", spawn "xbacklight -dec 10")
                    ,("<XF86Display>", spawn "autorandr")
                    ]
