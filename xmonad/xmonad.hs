import XMonad
import XMonad.Hooks.ManageDocks
import XMonad.Hooks.DynamicLog
import XMonad.Util.EZConfig
import XMonad.Hooks.ManageHelpers
import XMonad.Hooks.EwmhDesktops
import XMonad.Layout.Minimize
import XMonad.Hooks.Minimize

main =
--   spawn "sh /home/krzys/.xmonad/xmonad-startup.sh"
  xmonad =<< statusBar xmobar' myPP toggleStrutsKey (ewmh defaults)

xmobar' = "sh ~/.xmonad/xmonad-startup.sh"

myPP = xmobarPP { ppCurrent = \x -> "<fc=green>" ++ x ++ "</fc>"
                , ppHidden = id
                , ppUrgent = \x -> "<fc=red>" ++ x ++ "</fc>"
                , ppSep = " | "
                , ppWsSep = " "
                , ppTitle = shorten 40
                , ppOrder = \(w:_:t:_) -> [w,t]
                }

toggleStrutsKey XConfig{modMask = modm} = (modm, xK_b )

myManageHook = composeAll [
  isFullscreen --> doFullFloat,
  className =? "VirtualBox" --> doFloat]

defaults =
  def { modMask = mod4Mask
      , terminal = "gnome-terminal"
      , manageHook = myManageHook <+> manageHook def
      , layoutHook = minimize (Tall 1 (3/100) (1/2)) ||| layoutHook def
      , handleEventHook = minimizeEventHook <+> handleEventHook def <+> fullscreenEventHook}
  `additionalKeysP` [("M-C-S-q", spawn "systemctl suspend")
                    ,("M-C-q", spawn "dm-tool switch-to-greeter")
                    ,("M-S-l", spawn "xscreensaver-command -lock")
                    ,("M-m", withFocused minimizeWindow)
                    ,("M-S-m", sendMessage RestoreNextMinimizedWin)
                    ,("M-p", spawn "dmenu_run -fn Inconsolata-16:normal")
                    ,("<XF86MonBrightnessUp>", spawn "xbacklight -inc 10")
                    ,("<XF86MonBrightnessDown>", spawn "xbacklight -dec 10")
--                    ,("<XF86Display>", spawn "autorandr")
                    ]
