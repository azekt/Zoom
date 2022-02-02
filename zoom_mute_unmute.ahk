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
buttonXoffset := -70
buttonYoffset := 22
recountFlag := false
global videoShare := false
global videoShareClass := false
global buttonColor := false

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
	Gui, HelperGUI:Font, cWhite s11 bold, Arial
	Gui, HelperGUI:Add, Text, vhelperGuiText Left x10 y10
	GuiControl, HelperGUI:Move, helperGuiText, w200 Center
	GuiControl, HelperGUI:Text, helperGuiText, ---
	Gui, HelperGUI:Show, NoActivate x10 y10 h40 w200
	WinSet, Transparent, %debugWinTransp%
}
; ---------
SetTimer, CheckParticipants, %refreshTime%
Return

CheckParticipants:
winTitle := "ahk_class ZPContentViewWndClass"
curWin := WinExist(winTitle)
If (curWin) {
	WinGetPos, WinPosX, WinPosY, winWidth, winHeight, %winTitle%
	GetClientSize(curWin, winWidth, winHeight)
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
				
		fieldWidth := winWidth - listWidth - 12
		fieldHeight := winHeight - 59 - 59 ;- 53 - 53
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
		; we are looking for highest value of https://www.desmos.com/calculator/7g6narkmky

		Loop {
			pcpsCount--
;
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
			;;msgbox bestVideoWidth %bestVideoWidth%
		} Until ((bestVideoWidth >= 160) || (pcpsCount < 0))
		
		; windowX - clientX = 8 px
		; windowY - clientY = 31 px
		; upper and control panels  - 53 px;
		; sometimes Zoom decides to make video little smaller - i don't know why :-(
		; we have to check it

		columnsCount := bestColumn
		rowsCount := Ceil(pcpsCount / columnsCount)
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
					} else  {
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
		
		helperGuiPozX := WinPosX + 8 + 6
		helperGuiPozY := WinPosY + 31 + 95
		;Gui, helperGUI:Show, NoActivate x%helperGuiPozX% y%helperGuiPozY% w500 h200
		; --- for debuging only ---
		if (debug) {
			videoGuiPozX :=	videoPozX + WinPosX + 8
			videoGuiPozY :=	videoPozY + WinPosY + 31
			GuiControl, VideoGUI:Text, Textarea, %fieldWidth%, %fieldHeight%`n%videoWidth% %videoHeight%`n`nbestColumn %bestColumn%
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
Numpad0::
	SwitchMic(videoButton1PozX, videoButton1PozY, false)
Return

Numpad1::
	SwitchMic(videoButton1PozX, videoButton1PozY)
Return

Numpad2::
	SwitchMic(videoButton2PozX, videoButton2PozY)
Return

Numpad3::
	SwitchMic(videoButton3PozX, videoButton3PozY)
Return

; mute without lower hand
Numpad4::
	SwitchMic(videoButton1PozX, videoButton1PozY, false)
Return

Numpad5::
	SwitchMic(videoButton2PozX, videoButton2PozY, false)
Return

Numpad6::
	SwitchMic(videoButton3PozX, videoButton3PozY, false)
Return

; lower hand only
Numpad7::
	LowerHand(videoButton1PozX, videoButton1PozY)
Return

F9::
winTitle := "ahk_class ZPContentViewWndClass"
curWin := WinExist(winTitle)
If (curWin) {
	WinGetPos, WinPosX, WinPosY, , , %winTitle%
	cl := GetVideoShareClass(WinPosX, WinPosY)
	msgbox %cl%
}
Return

F12::
	videoShareClass := false
Return

^!NumpadAdd::
	; --- unmute and spotlight first two participants
	WinActivate, ahk_class ZPContentViewWndClass
	BlockInput, MouseMove
	MouseMove, videoButton1PozX + 10, videoButton1PozY, 2 ; unmute first pcp
	Sleep, 50
	Click
	MouseMove, videoButton1PozX, videoButton1PozY + 10, 2 ; then spotlight
	Click, right
	MouseMove, videoButton1PozX + 20, videoButton1PozY + 135, 2
	Click
	Sleep, 50
	Send !{F2}
	MouseMove, videoButton2PozX + 10, videoButton2PozY, 2 ; unmute second pcp
	Sleep, 50
	Click
	MouseMove, videoButton2PozX, videoButton2PozY + 10, 2 ; add to spotlight
	Click, right
	MouseMove, videoButton2PozX + 20, videoButton2PozY + 130, 2
	Click
	Sleep, 50
	Send !{F2}
	BlockInput, MouseMoveOff
Return

^+d::
	if (debug = 2) {
		debug := 0
		Gui, VideoGUI:Hide
		Gui, HelperGUI:Hide
	} else {
		debug++
	}
Return

^!NumpadSub::
	; --- remove spotlight and mute first two participants
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
Return



; --- for debuging only ---
F8::
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
return
; --------- 


; --------- functions ----------
CountMaxVideoWidth(ByRef fieldWidth, ByRef fieldHeight, ByRef pcpsCount, columnsCount) {
	rowsCount := Ceil(pcpsCount / columnsCount)
	rowsSpace := (rowsCount - 1) * 6
	columnsSpace := (columnsCount - 1) * 6
	maxPossHeight := (fieldHeight - rowsSpace) / rowsCount
	maxPossHeight := Floor(maxPossHeight / 9) * 9
	maxPossWidth := (fieldWidth - columnsSpace) / columnsCount
	maxPossWidth := Floor(maxPossWidth / 16) * 16
	if (maxPossWidth * 0.5625 < maxPossHeight) {
		videoHeight := maxPossWidth * 0.5625
		videoWidth := maxPossWidth
	} else {
		videoHeight := maxPossHeight
		videoWidth := maxPossHeight / 0.5625
	}
	return [videoWidth, videoHeight, rowsCount, rowsSpace, columnsSpace]
}

SwitchMic(ByRef XPoz, ByRef YPoz, lowerHand := true) {
	BlockInput, MouseMove
	WinActivate, ahk_class ZPContentViewWndClass
	if (!buttonColor) {
		buttonColor := getButtonColor(XPoz, YPoz)
	}
	MouseMove, XPoz, YPoz, 3
	Sleep, 100
	PixelGetColor, color, %XPoz%, %YPoz%, RGB
	;msgbox Button color: %buttonColor%, founded %color%
	Sleep, 100
	
	if (color = buttonColor) {
		;msgbox unmute!
		MouseMove, XPoz + 10, YPoz, 2 ; unmute
		;Sleep, 100
		Click
	} else {
		;msgbox mute and lower hand
		MouseMove, XPoz + 10, YPoz, 2 ; mute first
		;Sleep, 100
		Click
		;Sleep, 100
		if (lowerHand) {
			MouseMove, XPoz, YPoz + 10, 2 ; then lower hand
			;Sleep, 100
			Click, right
			MouseMove, XPoz + 20, YPoz + 30, 2
			;Sleep, 100
			Click
		}
	}
	MouseMove, XPoz + 10, YPoz - 30, 2 ; move away from buttons
	BlockInput, MouseMoveOff
}

LowerHand(ByRef XPoz, ByRef YPoz) {
	BlockInput, MouseMove
	WinActivate, ahk_class ZPContentViewWndClass
	MouseMove, XPoz, YPoz + 10, 2 ; lower hand
	;Sleep, 100
	Click, right
	MouseMove, XPoz + 20, YPoz + 30, 2
	;Sleep, 100
	Click
	MouseMove, XPoz + 10, YPoz - 30, 2 ; move away from buttons
	BlockInput, MouseMoveOff
}

GetButtonColor(ByRef XPoz, ByRef YPoz){
	buttonXoffset := -70
	buttonYoffset := 22
	x := XPoz + 50
	y := YPoz - 2
	MouseMove, XPoz, YPoz, 3
	PixelGetColor, color, %XPoz%, %YPoz%, RGB
	;msgbox %color%
	return color
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
	MouseMove, x, y, 0
	CoordMode, Mouse, Client
	BlockInput, MouseMoveOff
	return className
}