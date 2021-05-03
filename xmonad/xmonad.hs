import XMonad
import XMonad.Hooks.ManageDocks
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.DynamicBars
import XMonad.Util.EZConfig
import XMonad.Hooks.ManageHelpers
import XMonad.Hooks.EwmhDesktops
import XMonad.Actions.Minimize
import XMonad.Layout.Minimize
import XMonad.Hooks.Minimize
import XMonad.Util.SpawnOnce
import XMonad.Util.Run (spawnPipe)
import XMonad.Config.Gnome (gnomeRegister)

main =
  xmonad $ ewmh defaults

myPP = xmobarPP { ppCurrent = \x -> "<fc=green>" ++ x ++ "</fc>"
                , ppHidden = id
                , ppUrgent = \x -> "<fc=red>" ++ x ++ "</fc>"
                , ppSep = " | "
                , ppWsSep = " "
                , ppTitle = shorten 40
                , ppOrder = \(w:_:t:_) -> [w,t]
                }

myPPInactive = myPP { ppCurrent = \x -> "<fc=cyan>" ++ x ++ "</fc>"
                    }

toggleStrutsKey XConfig{modMask = modm} = (modm, xK_b )

myManageHook = composeAll [
  isFullscreen --> doFullFloat,
  className =? "VirtualBox" --> doFloat]

xmobarCreate :: DynamicStatusBar
xmobarCreate (S sid) = spawnPipe $ "xmobar --screen " ++ show sid

xmobarDestroy :: DynamicStatusBarCleanup
xmobarDestroy = return ()

defaults =
  def { modMask = mod4Mask
      , terminal = "gnome-terminal"
      , manageHook = manageDocks <+> myManageHook <+> manageHook def
      , layoutHook = avoidStruts (minimize (Tall 1 (3/100) (1/2)) ||| layoutHook def)
      , logHook = do
          logHook def
          multiPP myPP myPPInactive
      , handleEventHook =
        docksEventHook <+>
        dynStatusBarEventHook xmobarCreate xmobarDestroy <+>
        minimizeEventHook <+> fullscreenEventHook <+> handleEventHook def
      , startupHook = docksStartupHook
                      >> gnomeRegister >> spawnOnce "~/.xmonad/xmonad-startup.sh"
                      >> dynStatusBarStartup xmobarCreate xmobarDestroy
                      >> startupHook def }
  `additionalKeysP` [("M-C-S-q", spawn "systemctl suspend")
                    ,("M-C-q", spawn "dm-tool switch-to-greeter")
                    ,("M-S-q", spawn "gnome-session-quit --logout")
                    ,("M-S-l", spawn "gnome-screensaver-command --lock")
                    ,("M-m", withFocused minimizeWindow)
                    ,("M-S-m", withLastMinimized maximizeWindowAndFocus)
                    ,("M-b", sendMessage ToggleStruts)
                    ,("M-p", spawn "dmenu_run -fn Inconsolata-12:normal")
                    ]
