----------------------------------------------
--xmonad.hs for darcs
--7-23-10
----------------------------------------------

-- Imports.

import XMonad
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.UrgencyHook
import qualified XMonad.StackSet as W
import qualified Data.Map as M
import Data.Ratio ((%))

import XMonad.Util.NamedScratchpad
import XMonad.Util.EZConfig
import XMonad.Actions.WindowBringer
import XMonad.Actions.GridSelect

import XMonad.Layout.NoBorders
import XMonad.Layout.Named
import XMonad.Layout.Tabbed
import XMonad.Layout.PerWorkspace

-- The main function.
main = xmonad =<< statusBar cmd pp kb conf
  where
    uhook = withUrgencyHookC NoUrgencyHook urgentConfig
    cmd = "xmobar"
    pp = customPP
    kb = toggleStrutsKey
    conf = uhook myConfig

-- The main config.
myConfig = defaultConfig { terminal = myTerminal
			 , modMask = myModMask
			 , workspaces = myWorkspaces
			 , borderWidth = myBorderWidth
			 , normalBorderColor = myNormalBorderColor
			 , focusedBorderColor = myFocusedBorderColor
			 , focusFollowsMouse = myFocusFollowsMouse
			 , layoutHook = myLayoutHook
			 , manageHook = myManageHook
			 } `additionalKeysP` myKeys

-- Default terminal.
myTerminal = "urxvt"

-- Mod key.
myModMask = mod1Mask

-- Names and number of workspaces.
myWorkspaces :: [WorkspaceId]
myWorkspaces = ["term", "tab", "3", "4", "5", "6", "7", "8", "9"]

-- Border width.
myBorderWidth = 2

-- Color of non-focused borders.
myNormalBorderColor = "#465457"

-- Color of focused borders.
myFocusedBorderColor = "#94bff3"

myFocusFollowsMouse :: Bool
myFocusFollowsMouse = False

-- Theme for tabbed layout 1.
tabTheme1 = defaultTheme { decoHeight = 20
                         , activeColor = "#ccccc6"
			 , inactiveColor = "#0f0f0f"
			 , urgentColor = "#B7416E"
                         , activeBorderColor = "#0d0d0d"
                         , activeTextColor = "#000000"
                         , inactiveBorderColor = "#0d0d0d"
			 , fontName = "xft:Droid Sans-8"
                         }

-- Layout config.
myLayoutHook = onWorkspace "tab" (tab ||| tiled ||| wtiled ||| full) $ tiled ||| wtiled ||| full ||| tab
  where
    t = Tall 1 (3/100) (1/2)
    tiled = named "V" $ smartBorders t
    tiledborders = named "V2" t
    wtiled = named "H" $ smartBorders $ Mirror t 
    full = named "F" $ smartBorders $ Full
    tab = named "T" $ smartBorders $ tabbed shrinkText tabTheme1

-- Rules for window management.
myManageHook = composeAll
  [ className =? "MPlayer"           --> doFloat
  , className =? "Gimp"              --> doFloat
  , className =? "desktop_window"    --> doIgnore 
  , title     =? "glxgears"          --> doFloat
  , title     =? "Chromium Options"  --> doFloat
  , className =? "lol"               --> doFloat ] <+> namedScratchpadManageHook myScratchPads

-- Scratchpad config.
myScratchPads = [ NS "terminal" spawnTerm findTerm manageTerm
		, NS "sonata" spawnSonata findSonata manageSonata
		]
  where
    spawnTerm = myTerminal ++ " -name scratchpad"
    findTerm = resource =? "scratchpad"
    manageTerm = customFloating $ W.RationalRect l t w h
      where
        h = 0.15      -- height - 10%
	w = 1         -- width - 100%
	t = 1 - h     -- bottom edge
	l = (1 - w)/2 -- centered
    spawnSonata = "sonata"
    findSonata = className =? "Sonata"
    manageSonata = doFloat

-- Config for xmobar (additional config in ~/.xmobarrc).
customPP = defaultPP { ppTitle = xmobarColor "#dfaf8f" "" . shorten 80
                     , ppCurrent = xmobarColor "#60b48a" ""
                     , ppHidden = xmobarColor "#465457" ""
                     , ppLayout = xmobarColor "#465457" ""
                     , ppSep = xmobarColor "#465457" "" " ~ "
                     , ppUrgent = xmobarColor "#d81860" "" . wrap "[" "]"
                     }

-- Urgent notification.
urgentConfig = UrgencyConfig { suppressWhen = Focused, remindWhen = Dont }

-- Keybinding config for statusBar function.
toggleStrutsKey :: XConfig Layout -> (KeyMask, KeySym)
toggleStrutsKey XConfig {XMonad.modMask = modMask} = (modMask, xK_x)

-- Keybinding configs.
myKeys = [ ("M-o c", spawn "chromium") 
         , ("M-s", namedScratchpadAction myScratchPads "terminal")
	 , ("M-S-s", namedScratchpadAction myScratchPads "sonata")
	 , ("M-f", spawn "amixer set Master 3dB+ unmute")
	 , ("M-d", spawn "amixer set Master 3dB- unmute")
	 , ("M-g", spawn "amixer set Master toggle")
	 , ("M-a", spawn "mpc toggle")
	 , ("M-i", goToSelected defaultGSConfig)
	 , ("M-p", spawn "exe=`dmenu_path | dmenu -nb \"#3f3f3f\" -nf \"#a0a0a0\" -sb \"#705050\" -sf \"#a0a0a0\" -i` && eval \"exec $exe\"")

	 ]
