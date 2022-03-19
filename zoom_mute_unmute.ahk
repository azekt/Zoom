; Zoom_mute_unmute.ahk
; Azariasz Trzcinski, 2022
; 
; Checked on Zoom 5.9.3 
; Participants Window has to be merge to Meeting Window, Gallery view, and show non-video participants!
;
; Hotkeys:
; Numpad 1-9 (depends on participants count) - unmute / mute and lower hand
; Numpad/ - lower hand first participant
; Ctrl + Shift + Numpad+ - Unmute and spotlight two first participants
; Ctrl + Shift + Numpad- - Mute two first participants in Gallery view and remove spotlight
; F12 - reset saved settings (Unmute button color, Share Screen panel's width, client window's width and height)
; F8 - show overlay on first five participants (debugging)
; Ctrl + Shift + D - toggle debuging overlay (hide, show only on changed, show always)
; F9 - restart app


#SingleInstance force
#NoEnv
SetBatchLines, -1
ListLines, Off
CoordMode, Mouse, Client
CoordMode, Pixel, Client
; Settings
maxPcpsCount := 49
debug := 1 ; 0 - never, 1 - only when changed, 2 - always
refreshTime := 250
debugWinTransp := 60
maxPcpsOp := 5 ; max number (1-9) of participants we want to operate with numpad

; variables pre-declaration
oldPcpsCount := 0
oldWinPosX := 0
oldWinPosY := 0
oldWinWidth := 0
oldWinHeight := 0
oldListWidth := 0
oldVSWidth := 0
recountFlag := false

global buttonXoffset := -70
global buttonYoffset := 21
global clientWidthDiff := 0
global clientHeightDiff := 0
global videoWidth := 0
global videoHeight := 0
global videoShare := false
global videoShareClass := false
global buttonColor := false
global inAction := false ; prevent from doing another action before end current one

; --- for debuging only ---
if (debug) {
	Gui, VideoGUI:New, +AlwaysOnTop -Caption +Owner +LastFound +E0x20
	Gui, VideoGUI:Margin, 0, 0
	Gui, VideoGUI:Color, 66ff33
	Gui, VideoGUI:Font, cBlack s11 bold, Arial
	Gui, VideoGUI:Add, Edit, ReadOnly r9 vTextarea w300 y5 x5
	WinSet, Transparent, %debugWinTransp%

	Gui, HelperGUI:New, +AlwaysOnTop -Caption +Owner +LastFound +E0x20
	Gui, HelperGUI:Margin, 0, 0
	Gui, HelperGUI:Color, FF0000
	Gui, HelperGUI:Font, c000000 s11 bold, Arial
	Gui, HelperGUI:Add, Text, vhelperGuiText Left x10 y7 
	GuiControl, HelperGUI:Move, helperGuiText, w200 Center 
	WinSet, Transparent, 160
}
; ---------
SetTimer, CheckParticipants, %refreshTime%
Return

CheckParticipants:
winTitle := "ahk_class ZPContentViewWndClass"
curWin := WinExist(winTitle)
If (curWin) {
	WinGetPos, WinPosX, WinPosY, winWidth, winHeight, %winTitle%
	if (!clientWidthDiff) {
		wW := winWidth
		wH := winHeight
		GetClientSize(curWin, winWidth, winHeight)
		clientWidthDiff := wW - winWidth
		clientHeightDiff := WH - winHeight
	} else {
		winWidth := winWidth - clientWidthDiff
		winHeight := winHeight - clientHeightDiff
	}
	
	ControlGetText, str, zPlistWndClass1, %winTitle%
	ControlGetPos, , , listWidth, , zRightPanelContainerClass1, %winTitle%
	vsWidth := VideoShareWidth(WinPosX, WinPosY)
	pcpsCount := SubStr(str, 15, -1) ; participant's counter
	if (pcpsCount > maxPcpsCount)
		pcpsCount := maxPcpsCount

	; We recount video position on:
	;   * window's resizing
	;   * window's moving
	;	* start / end screen sharing
	; 	* share screen part resizing
	;   * participant's panel's resize
	;   * participant's number changing

	changesFlag := (oldPcpsCount != pcpsCount)
		|| IsVideoShareChanged()
		|| (vsWidth != oldVSWidth)
		|| (WinPosX != oldWinPosX)
		|| (WinPosY != oldWinPosY)
		|| (winWidth != oldWinWidth)
		|| (winHeight != oldWinHeight)
		|| (oldListWidth != listWidth)

	if (changesFlag || recountFlag) {
		oldPcpsCount := pcpsCount
		oldVSWidth := vsWidth
		oldWinPosX := WinPosX
		oldWinPosY := WinPosY
		oldWinWidth := winWidth
		oldWinHeight := winHeight
		oldListWidth := listWidth
				
		fieldWidth := winWidth - listWidth - 1 - 12
		fieldHeight := winHeight - 59 - 59
		if (vsWidth > 0) {
			fieldWidth := fieldWidth - vsWidth - 18
			fieldHeight := fieldHeight - 36 - 36
		}
		; We put flag every time something changed to recount
		; If we did and there is no more changes we can stop

		recountFlag := true
		if (!changesFlag && recountFlag)
			recountFlag := false

		pcpsCount++ ; add participant that we could minus in loop
		; we find the highest value of https://www.desmos.com/calculator/7g6narkmky

		Loop {
			pcpsCount--
			;https://www.wolframalpha.com/input?i=solve+%28%28h-6*%28p%2Fx-1%29%29%2F%28p%2Fx%29%29%2F9%2B1+%3E+10+for+x
			;https://www.wolframalpha.com/input?i=solve+%28w-6*%28x-1%29%29%2Fx+%3E+160+for+x
			minColumn := floor((87 * pcpsCount) / (fieldHeight + 6)) - 1
			maxColumn := min(pcpsCount, ceil((fieldWidth + 6) / 150))
			columnsCount := minColumn
			bestVideoWidth := 0
			bestColumn := 0
			Loop {
				if (columnsCount >= maxColumn)
					break
				columnsCount++
				rowsCount := Ceil(pcpsCount / columnsCount)
				rowsSpace := (rowsCount - 1) * 6
				columnsSpace := (columnsCount - 1) * 6
				maxPossWidth := Floor((fieldWidth - columnsSpace) / columnsCount / 16) * 16
				maxPossHeight := Floor((fieldHeight - rowsSpace) / rowsCount / 9) * 16
				videoWidth := (maxPossWidth < maxPossHeight) ? maxPossWidth : maxPossHeight
				if (videoWidth > bestVideoWidth) {
					bestVideoWidth := videoWidth
					bestColumn := columnsCount
				}
				if (videoWidth < bestVideoWidth)
					break
			}
		} Until ((bestVideoWidth >= 160) || (pcpsCount < 0))

		; upper and control panels  - 53 px;

		columnsCount := bestColumn
		columnsSpace := (columnsCount - 1) * 6
		rowsCount := Ceil(pcpsCount / columnsCount)
		rowsSpace := (rowsCount - 1) * 6
		videoWidth := bestVideoWidth
		videoHeight := bestVideoWidth * 0.5625
		videoPozX := Ceil((fieldWidth - (videoWidth * columnsCount + columnsSpace)) / 2) + 6
		videoPozY := Ceil((fieldHeight - (videoHeight * rowsCount + rowsSpace)) / 2) + 53 + 6
		if (vsWidth > 0) {
			videoPozX := videoPozX + vsWidth + 21
			videoPozY := videoPozY + 36
		}

		videoButtonPozX := []
		videoButtonPozY := []
		mC := columnsCount
		modPcps := Mod(pcpsCount, columnsCount)
		mR := rowsCount
		offset := 0 ; used in non-full last row
		nr := 1
		
		lR := 1
		loop {
			if (lR > mR)
				break
			if (modPcps != 0 && lR = mR)
				offset := Ceil(videoWidth * (columnsCount - modPcps) + 6 * (columnsCount - modPcps - 1)) / 2
			lC := 1
			Loop {
				if (lC > mC)
					break
				videoButtonPozX[nr] := videoPozX + offset + videoWidth * lC + 6 * (lc - 1) + buttonXoffset
				videoButtonPozY[nr] := videoPozY + videoHeight * (lR - 1) + 6 * (lR - 1) + buttonYoffset
				fn := Func("SwitchMic").Bind(videoButtonPozX[nr], videoButtonPozY[nr])
				Hotkey, Numpad%nr%, %fn%
				lc++
				nr++
				if (nr > maxPcpsOp)
					break 2
			}
			lR++
		}
		; --- for debuging only ---
		if (debug) {
			; actual window X - WinPosX = 8 px
			; actual window Y - WinPosY = 31 px
			videoGuiPozX :=	WinPosX + 8 + videoPozX
			videoGuiPozY :=	WinPosY + 31 + videoPozY
			GuiControl, VideoGUI:Text, Textarea, field size: %fieldWidth% %fieldHeight%`nvideo size: %videoWidth% %videoHeight%`nvideo poz.: %videoPozX% %videoPozY%`nbestColumn %bestColumn%
			Gui, VideoGUI:Show, NoActivate x%videoGuiPozX% y%videoGuiPozY% w%videoWidth% h%videoHeight%
			if (debug = 1) {
				sleep, 200
				Gui, VideoGUI:Hide
			}
		}
		; ---------
	}
} else {
	Gui, VideoGUI:Hide
	Gui, HelperGUI:Hide
}
Return

#IfWinActive ahk_class ZPContentViewWndClass
; lower hand only
NumpadDiv::
	LowerHand(videoButtonPozX[1], videoButtonPozY[1])
Return

^+NumpadAdd::
	; --- unmute and spotlight first two participants
	if (inAction) {
		return
	}
	inAction := true
	WinActivate, ahk_class ZPContentViewWndClass
	pix1X := videoButtonPozX[1] - buttonXoffset - videoWidth/2
	pix1Y := videoButtonPozY[1] - buttonYoffset
	pix2X := videoButtonPozX[2] - buttonXoffset - videoWidth/2
	pix2Y := videoButtonPozY[2] - buttonYoffset
	PixelGetColor, color1, %pix1X%, %pix1Y%, RGB
	PixelGetColor, color2, %pix2X%, %pix2Y%, RGB
	if (color1 = 0x222222 || color2 = 0x222222) {
		inAction := false
		helperGuiTextWidth := 375
		Gui, HelperGUI:Color, FF0000
		GuiControl, HelperGUI:Move, helperGuiText, w%helperGuiTextWidth% Center
		GuiControl, HelperGUI:Text, helperGuiText,⚠ You cannot spotlight participants without video!
		helperGuiPozX := WinPosX + 8 + fieldWidth/2 - helperGuiTextWidth/2
		helperGuiPozY := WinPosY + 31 + 5
		Gui, HelperGUI:Show, NoActivate x%helperGuiPozX% y%helperGuiPozY% h30 w%helperGuiTextWidth%
		Sleep, 3000
		Gui, HelperGUI:Hide
		return
	}
	BlockInput, MouseMove
	MouseMove, videoButtonPozX[1] + 10, videoButtonPozY[1], 2 ; unmute first pcp
	Sleep, 50
	Click
	MouseMove, videoButtonPozX[1], videoButtonPozY[1] + 10, 2 ; then spotlight
	Click, right
	MouseMove, videoButtonPozX[1] + 20, videoButtonPozY[1] + 135, 2
	Click
	Sleep, 50
	Send !{F2} ; change to gallery view
	MouseMove, videoButtonPozX[2] + 10, videoButtonPozY[2], 2 ; unmute second pcp
	Sleep, 50
	Click
	MouseMove, videoButtonPozX[2], videoButtonPozY[2] + 10, 2 ; add to spotlight
	Click, right
	MouseMove, videoButtonPozX[2] + 20, videoButtonPozY[2] + 135, 2
	Click
	Sleep, 50
	Send !{F2} ; change to gallery view
	BlockInput, MouseMoveOff
	inAction := false
Return

^+NumpadSub::
	; --- remove spotlight and mute first two participants
	if (inAction) {
		return
	}
	inAction := true
	WinActivate, ahk_class ZPContentViewWndClass
	XPoz := winWidth - listWidth
	BlockInput, MouseMove
	MouseMove, XPoz - 20, 20, 2
	Sleep, 50
	Click
	MouseMove, Xpoz - 20, 120, 2
	Sleep, 50
	Click
	MouseMove, videoButtonPozX[1] + 10, videoButtonPozY[1], 2 ; mute first pcp
	Sleep, 50
	Click
	MouseMove, videoButtonPozX[2] + 10, videoButtonPozY[2], 2 ; mute second pcp
	Sleep, 50
	Click
	BlockInput, MouseMoveOff
	inAction := false
Return

F12::
	videoShareClass := false
	buttonColor := false
	clientWidthDiff := 0
	clientHeightDiff := 0
	helperGuiTextWidth := 425
	Gui, HelperGUI:Color, 00FF00
	GuiControl, HelperGUI:Move, helperGuiText, w%helperGuiTextWidth% Center
	GuiControl, HelperGUI:Text, helperGuiText,The saved button color and screen size have been reset.
	helperGuiPozX := WinPosX + 8 + fieldWidth/2 - helperGuiTextWidth/2
	helperGuiPozY := WinPosY + 31 + 5
	Gui, HelperGUI:Show, NoActivate x%helperGuiPozX% y%helperGuiPozY% h30 w%helperGuiTextWidth%
	Sleep, 3000
	Gui, HelperGUI:Hide
Return

; --- for debuging only ---
^+d::
	if (debug = 2) {
		debug := 0
		Gui, VideoGUI:Hide
		Gui, HelperGUI:Hide
	} else {
		debug++
		if (debug = 2)
			Gui, VideoGUI:Show, NoActivate x%videoGuiPozX% y%videoGuiPozY% w%videoWidth% h%videoHeight%
	}
Return

F8::
	if (inAction)
		return
	inAction := true
	WinActivate, ahk_class ZPContentViewWndClass
	MouseGetPos, mouseX, mouseY
	BlockInput, MouseMove
	if (debug)
		Gui, VideoGUI:Show, NoActivate x%videoGuiPozX% y%videoGuiPozY% w%videoWidth% h%videoHeight%
	l := (maxPcpsOp < pcpsCount) ? maxPcpsOp : pcpsCount
	Loop, %l% {
		MouseMove, videoButtonPozX[A_Index], videoButtonPozY[A_Index], 2
		x := WinPosX + 8 + videoButtonPozX[A_Index] - buttonXoffset - videoWidth
		y := WinPosY + 31 + videoButtonPozY[A_Index] - buttonYoffset
		Gui, VideoGUI:Show, NoActivate x%x% y%y% w%videoWidth% h%videoHeight%
		Sleep, 50
	}
	
	MouseMove, mouseX, mouseY, 2 ; return
	BlockInput, MouseMoveOff
	if (debug)
		Gui, VideoGUI:Hide
	inAction := false
return

F9::Reload
; ---------

; --------- functions ----------
IsHandRised(ByRef XPoz, ByRef YPoz){
	if (videoWidth < 360) {
		handXOffset := 16
		handYOffset := 23
	} else if(videoWidth < 620) {
		handXOffset := 22
		handYOffset := 33
	} else {
		handXOffset := 32
		handYOffset := 50
	}
	pixX :=	XPoz - buttonXoffset - videoWidth + handXOffset
	pixY := YPoz - buttonYoffset + handYOffset
	PixelGetColor, color, %pixX%, %pixY%, RGB
	return color = 0xFCD5B2 || color = 0xFDCA47 || color = 0xEBBEA0
}

SwitchMic(ByRef XPoz, ByRef YPoz) {
	if (inAction)
		return
	inAction := true
	BlockInput, MouseMove
	WinActivate, ahk_class ZPContentViewWndClass
	if (!buttonColor)
		buttonColor := getButtonColor(XPoz, YPoz)
	MouseMove, XPoz, YPoz, 1
	Sleep, 50
	PixelGetColor, color, %XPoz%, %YPoz%, RGB
	; see below why we check two colors
	if (color = buttonColor[1] || color = buttonColor[2]) {
		MouseMove, XPoz + 10, YPoz, 1 ; unmute
		Click
	} else {
		MouseMove, XPoz + 10, YPoz, 1 ; mute first
		Click
		if (IsHandRised(XPoz, YPoz)) {
			MouseMove, XPoz, YPoz + 10, 2 ; then lower hand
			Click, right
			MouseMove, XPoz + 20, YPoz + 30, 2
			Click
		}
	}
	MouseMove, XPoz + 10, YPoz - 30, 1 ; move away from the buttons
	BlockInput, MouseMoveOff
	inAction := false
}

LowerHand(ByRef XPoz, ByRef YPoz) {
	if (inAction)
		return
	if (!IsHandRised(XPoz, YPoz))
		return
	inAction := true
	BlockInput, MouseMove
	WinActivate, ahk_class ZPContentViewWndClass
	MouseMove, XPoz, YPoz + 10, 2 ; then lower hand
	Click, right
	MouseMove, XPoz + 20, YPoz + 30, 2
	Click
	MouseMove, XPoz + 10, YPoz - 30, 2 ; move away from the buttons
	BlockInput, MouseMoveOff
	inAction := false
}

GetButtonColor(ByRef XPoz, ByRef YPoz){
	pixX := XPoz + 60
	pixY := YPoz
	MouseMove, pixX, pixY+20, 3
	; we need onMouseOut color in case button didn't have time to change it on mouse over
	PixelGetColor, color1, %pixX%, %pixY%, RGB ; should be 0e71eb
	nr := 0
	MouseMove, pixX, pixY, 3
	Loop {
		nr++
		Sleep 50
		PixelGetColor, color2, %pixX%, %pixY%, RGB ; onMouseOver, should be 0D68D8
	} Until ((color1 != color2 ) || (nr > 5))
	return [color1, color2]
}

GetClientSize(hWnd, ByRef w := "", ByRef h := "") {
	VarSetCapacity(rect, 16)
	DllCall("GetClientRect", "ptr", hWnd, "ptr", &rect)
	w := NumGet(rect, 8, "int")
	h := NumGet(rect, 12, "int")
}

IsVideoShareChanged() {
	if (videoShare) {
		if (!WinExist("Screen share viewing options")) {
			videoShare := false
			return true
		}
	} else {
		if (WinExist("Screen share viewing options")) {
			videoShare := true
			return true
		}
	}
	return false
}

VideoShareWidth(ByRef XPoz, ByRef YPoz) {
	; There is a problem to get "ahk_class [TAB]ZPControlPanelHintClass" because of TAB char
	if (WinExist("Screen share viewing options")) {
		if (!videoShareClass)
			videoShareClass := GetVideoShareClass(XPoz, YPoz)
		ControlGetPos, , , w,, %videoShareClass%, ahk_class ZPContentViewWndClass
		return w
	}
	return 0
}

GetVideoShareClass(ByRef winX, ByRef winY){
	CoordMode, Mouse, Screen
	BlockInput, MouseMove
	MouseGetPos, x, y
	mX := winX + 30
	mY := winY + 150
	MouseMove, mX, mY, 0
	MouseGetPos, , , , className
	MouseMove, x, y, 0 ; move back
	CoordMode, Mouse, Client
	BlockInput, MouseMoveOff
	return className
}
