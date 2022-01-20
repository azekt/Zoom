#SingleInstance force
#NoEnv
SetBatchLines, -1
ListLines, Off
CoordMode, Mouse, Client
CoordMode, Pixel, Client
; Settings
maxPcpsCount := 49
debug := true
refreshTime := 100
debugWinTransp := 100

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
	Gui, VideoGUI:Font, cBlack s13 bold, Arial
	Gui, VideoGUI:Add, Edit, ReadOnly r9 vTextarea w300 y5 x5
	WinSet, Transparent, %debugWinTransp%

	Gui, HelperGUI:New, +AlwaysOnTop -Caption +Owner +LastFound +E0x20
	Gui, HelperGUI:Margin, 0, 0
	Gui, HelperGUI:Color, FF0000
	Gui, HelperGUI:Font, cWhite s13 bold, Arial
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
		
		maxColumn := min(fieldWidth / 160, pcpsCount+1)
		pcpsCount++ ; add participant that we could minus in loop
		Loop {
			Loop {
				pcpsCount--
				bestColumn := Sqrt((9 * fieldWidth * pcpsCount) / (16 * fieldHeight))
			;	msgbox bestColumn %bestColumn%
			} Until ((bestColumn <= maxColumn) || (pcpsCount < 0))
			
			if (bestColumn >= 1) {
				pFloor := Floor(bestColumn)
				cC := fieldWidth / (16 * pFloor)
				rC := fieldHeight / (9 * (Ceil(pcpsCount / pFloor)))
				mFloor := Min(cC, rC)
			} else {
				mFloor := 0
			}
			pCeil := Ceil(bestColumn)
			if (pCeil <= pcpsCount) {
				cC := fieldWidth / (16 * pCeil)
				rC := fieldHeight / (9 * (Ceil(pcpsCount / pCeil)))
				mCeil := Min(cC, rC)
				if (pCeilPlus <= pcpsCount) {
					pCeilPlus := Ceil(bestColumn) + 1
					cC := fieldWidth / (16 * pCeilPlus)
					rC := fieldHeight / (9 * (Ceil(pcpsCount / pCeilPlus)))
					mCeilPlus := Min(cC, rC)
				} else {
					mCeilPlus := 0
				}
				if (mCeilPlus > mCeil) {
					if (mCeilPlus > mFloor) {
						Gui, VideoGUI:Color, FF0000
						columnsCount := pCeilPlus
						maxRatio := mCeilPlus ; for debuging only
					} else {
						Gui, VideoGUI:Color, 00FF00
						columnsCount := pFloor
						maxRatio := mFloor ; for debuging only
					}
				} else {	
					if (mCeil > mFloor) {
						Gui, VideoGUI:Color, ffff00
						columnsCount := pCeil
						maxRatio := mCeil ; for debuging only
					} else {
						Gui, VideoGUI:Color, 00FF00
						columnsCount := pFloor
						maxRatio := mFloor ; for debuging only
					}
				}
			} else {
				Gui, VideoGUI:Color, 00FF00
				columnsCount := pFloor
				maxRatio := mFloor ; for debuging only
			}
			
		} Until (maxRatio >= 10 || (pcpsCount < 0))
		;msgbox columnsCount %columnsCount%
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
		; windowX - clientX = 8 px
		; windowY - clientY = 31 px
		; upper and control panels  - 53 px;
		; sometimes Zoom decides to make video little smaller - i don't know why :-(
		; we have to check it

		videoWidth := videoWidth + 16 ; add now, minus in loop
		videoHeight := videoHeight + 9
		
		nr := 0
		colStr := ""
		Loop {
			nr++
			videoWidth := videoWidth - 16
			videoHeight := videoHeight - 9
			videoPozX := Ceil((fieldWidth - (videoWidth * columnsCount + columnsSpace)) / 2) + 6
			videoPozY := Ceil((fieldHeight - (videoHeight * rowsCount + rowsSpace)) / 2) + 53 + 6
			pixX := videoPozX + 1
			pixY := videoPozY + 1
			if (vsWidth > 0) {
				videoPozX := videoPozX + vsWidth + 21
				videoPozY := videoPozY + 36
				pixX := pixX + vsWidth + 21
				pixY := pixY + 36
			}
			PixelGetColor, color, %pixX%, %pixY%, RGB
			if (debug) {
				GuiControl, HelperGUI:Text, helperGuiText, In %nWejscie% In %nWyjscie% %nr%
			}
			colStr := colStr . " X " . pixX . " Y " . pixY . " " . SubStr(color, 3, 6)
		} Until ((color != 0x1A1A1A) || (nr > 1))
		
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
			GuiControl, VideoGUI:Text, Textarea, %fieldWidth%, %fieldHeight%`n%videoWidth% %videoHeight%`nRatio: %maxRatio%`nbestColumn %bestColumn%`nchangesFlag %changesFlag% recountFlag %recountFlag%`nnr %nr%`nmFloor %mFloor%,  mCeil %mCeil%
			Gui, VideoGUI:Show, NoActivate x%videoGuiPozX% y%videoGuiPozY% w%videoWidth% h%videoHeight%
			;sleep, 200
			;Gui, VideoGUI:Hide
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