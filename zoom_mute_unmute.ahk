#SingleInstance force
#NoEnv
SetBatchLines, -1
ListLines, Off
CoordMode, Mouse, Client
CoordMode, Pixel, Client
; Settings
maxPcpsCount := 49
debug := 1 ; 0 - never, 1 - only when changed, 2 - always
refreshTime := 100
debugWinTransp := 60

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
	if (pcpsCount > maxPcpsCount) {
		pcpsCount := maxPcpsCount
	}
	; We recount video position on:
	;   * window's resizing
	;   * window's moving
	;	* start / end screen sharing
	; 	* share screen part resizing
	;   * participant's panel's resize
	;   * participant's number changing
	; changed

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
		if (!changesFlag && recountFlag) {
			recountFlag := false
		}

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
				if (columnsCount >= maxColumn) {
					break
				}
				columnsCount++
				rowsCount := Ceil(pcpsCount / columnsCount)
				rowsSpace := (rowsCount - 1) * 6
				columnsSpace := (columnsCount - 1) * 6
				maxPossWidth := Floor((fieldWidth - columnsSpace) / columnsCount / 16) * 16
				maxPossHeight := Floor((fieldHeight - rowsSpace) / rowsCount / 9) * 16
				if (maxPossWidth < maxPossHeight) {
					videoWidth := maxPossWidth
				} else {
					videoWidth := maxPossHeight
				}
				if (videoWidth > bestVideoWidth) {
					bestVideoWidth := videoWidth
					bestColumn := columnsCount
				}
				if (videoWidth < bestVideoWidth) {
					break
				}
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
		videoButton1PozX := videoPozX + videoWidth + buttonXoffset
		videoButton1PozY := videoPozY + buttonYoffset
		if (columnsCount > 1) {
			videoButton2PozX := videoPozX + videoWidth * 2 + 6 + buttonXoffset
			videoButton2PozY := videoButton1PozY
			if (columnsCount > 2) {
				videoButton3PozX := videoPozX + videoWidth * 3 + 12 + buttonXoffset
				videoButton3PozY := videoButton1PozY
			} else {
				if (pcpsCount > 2) {
					if (pcpsCount = 3) {
						videoButton3PozX := videoPozX + videoWidth * 1.5 + buttonXoffset
					} else {
						videoButton3PozX := videoButton1PozX
					}
					videoButton3PozY := videoPozY + videoHeight + 6 + buttonYoffset
				}
			}
		} else {
			if (pcpsCount > 1) {
				videoButton2PozX := videoButton1PozX
				videoButton2PozY := videoPozY + videoHeight + 6 + buttonYoffset
				if (pcpsCount > 2) {
					videoButton3PozX := videoButton1PozX
					videoButton3PozY := videoPozY + videoHeight * 2 + 12 + buttonYoffset
				}
			}
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
Numpad1::
	SwitchMic(videoButton1PozX, videoButton1PozY)
Return

Numpad2::
	SwitchMic(videoButton2PozX, videoButton2PozY)
Return

Numpad3::
	SwitchMic(videoButton3PozX, videoButton3PozY)
Return

; lower hand only
Numpad7::
	LowerHand(videoButton1PozX, videoButton1PozY)
Return

^+NumpadAdd::
	; --- unmute and spotlight first two participants
	if (inAction) {
		return
	}
	inAction := true
	WinActivate, ahk_class ZPContentViewWndClass
	pix1X := videoButton1PozX - buttonXoffset - videoWidth/2
	pix1Y := videoButton1PozY - buttonYoffset
	pix2X := videoButton2PozX - buttonXoffset - videoWidth/2
	pix2Y := videoButton2PozY - buttonYoffset
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
	MouseMove, videoButton1PozX + 10, videoButton1PozY, 2 ; unmute first pcp
	Sleep, 50
	Click
	MouseMove, videoButton1PozX, videoButton1PozY + 10, 2 ; then spotlight
	Click, right
	MouseMove, videoButton1PozX + 20, videoButton1PozY + 135, 2
	Click
	Sleep, 50
	Send !{F2} ; change to gallery view
	MouseMove, videoButton2PozX + 10, videoButton2PozY, 2 ; unmute second pcp
	Sleep, 50
	Click
	MouseMove, videoButton2PozX, videoButton2PozY + 10, 2 ; add to spotlight
	Click, right
	MouseMove, videoButton2PozX + 20, videoButton2PozY + 130, 2
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
	MouseMove, Xpoz - 20, 145, 2
	Sleep, 50
	Click
	MouseMove, videoButton1PozX + 10, videoButton1PozY, 2 ; mute first pcp
	Sleep, 50
	Click
	MouseMove, videoButton2PozX + 10, videoButton2PozY, 2 ; mute second pcp
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
		if (debug = 2) {
			Gui, VideoGUI:Show, NoActivate x%videoGuiPozX% y%videoGuiPozY% w%videoWidth% h%videoHeight%
		}
	}
Return

F8::
	if (inAction) {
		return
	}
	inAction := true
	WinActivate, ahk_class ZPContentViewWndClass
	MouseGetPos, mouseX, mouseY
	BlockInput, MouseMove
	if (debug) {
		Gui, VideoGUI:Show, NoActivate x%videoGuiPozX% y%videoGuiPozY% w%videoWidth% h%videoHeight%
	}
	MouseMove, videoButton1PozX, videoButton1PozY, 2 ; first participant
	Sleep, 200
	if (pcpsCount > 1) {
		MouseMove, videoButton2PozX, videoButton2PozY, 2 ; second participant
		Sleep, 200
		if (pcpsCount > 2) {
			MouseMove, videoButton3PozX, videoButton3PozY, 2 ; third participant
			Sleep, 200
		}
	}	
	MouseMove, mouseX, mouseY, 2 ; return
	BlockInput, MouseMoveOff
	if (debug) {
		Gui, VideoGUI:Hide
	}
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
	if (color = 0xFCD5B2 || color = 0xFDCA47 || color = 0xEBBEA0) {
		return true
	} else {
		return false
	}
}

SwitchMic(ByRef XPoz, ByRef YPoz) {
	if (inAction){
		return
	}
	inAction := true
	BlockInput, MouseMove
	WinActivate, ahk_class ZPContentViewWndClass
	if (!buttonColor) {
		buttonColor := getButtonColor(XPoz, YPoz)
	}
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
	if (inAction) {
		return
	}
	if (!IsHandRised(XPoz, YPoz)) {
		return
	}
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
	msgbox, %nr% %color1% %color2%
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
		if (!videoShareClass) {
			videoShareClass := GetVideoShareClass(XPoz, YPoz)
		}
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