#SingleInstance force
#NoEnv
SetBatchLines, -1
ListLines, Off

CoordMode, Mouse, Client
CoordMode, Pixel, Client
; Settings
minRatio := 11
maxPcpsCount := 49
debug := true
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
recountAgain := 0
global videoShare := false
global videoShareClass := false
global buttonColor := false
;buttonColor := 0x0D67D8
;buttonColor := 0x0D68D8
; --- for debuging only ---
if (debug) {
	Gui, VideoGUI:New, +AlwaysOnTop -Caption +Owner +LastFound +E0x20
	Gui, VideoGUI:Margin, 0, 0
	Gui, VideoGUI:Color, 66ff33
	Gui, VideoGUI:Font, cBlack s13 bold, Arial
	Gui, VideoGUI:Add, Edit, ReadOnly r9 vTextarea y5 x5
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
SetTimer, CheckParticipants, 1000
Return

CheckParticipants:
winTitle := "ahk_class ZPContentViewWndClass"
curWin := WinExist(winTitle)
If (curWin) {
	WinGetPos, WinPosX, WinPosY, winWidth, winHeight, %winTitle%
	GetClientSize(curWin, winWidth, winHeight)
	ControlGetText, str, zPlistWndClass1, %winTitle%
	ControlGetPos, , , listWidth, , zRightPanelContainerClass1, %winTitle%
	vsWidth := VideoShareWidth()
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
	if ((oldPcpsCount != pcpsCount)
			|| IsVideoShareChanged()
			|| (vsWidth != oldVSWidth)
			|| (WinPosX != oldWinPosX)
			|| (WinPosY != oldWinPosY)
			|| (winWidth != oldWinWidth)
			|| (winHeight != oldWinHeight)
			|| (oldListWidth != listWidth)
			|| recountAgain)
		{
		oldWinPosX := WinPosX
		oldWinPosY := WinPosY
		oldWinWidth := winWidth
		oldWinHeight := winHeight
		oldPcpsCount := pcpsCount
		oldListWidth := listWidth
		fieldWidth := winWidth - listWidth
		fieldHeight := winHeight - 53 - 53
		if (vsWidth > 0) {
			fieldWidth := fieldWidth - vsWidth - 18
			fieldHeight := winHeight - 95 - 95
		}
		recountAgain := recountAgain * -1

		maxRatio := 0
		maxRatioIndex := 1
		pcpsCountL := Ceil(sqrt(pcpsCount)) + 1
		pcpsCount++ ; we add one participant to minus it in while loop :-)
		opCount := 0 ; for debuging only
		while ((maxRatio < minRatio) && (pcpsCount > 0)) {
			pcpsCount--
			Loop, %pcpsCountL% {
				p := Ceil(pcpsCount / A_Index)
				rC := fieldHeight / (9 * p)
				opCount++ ; for debuging only
				if (rC > minRatio) {
					cC := fieldWidth / (16 * A_Index)
					m := Min(cC, rC)
					if (m > maxRatio) {
						maxRatioIndex := A_Index
						maxRatio := m
					}
					opCount++ ; for debuging only
				}
				cC := fieldWidth / (16 * p)
				opCount++ ; for debuging only
				if (cC > minRatio) {
					rC := fieldHeight / (9 * A_Index)
					m := Min(cC, rC)
					if (m > maxRatio) {
						maxRatioIndex := p
						maxRatio := m
					}
					opCount++ ; for debuging only
				}
			}
		}
		if (debug) {
			GuiControl, HelperGUI:Text, helperGuiText, %A_TickCount%`n%videoShareClass%`n%videoShare%
		}
		columnsCount := maxRatioIndex
		rowsCount := Ceil(pcpsCount / columnsCount)
		rowsSpace := (rowsCount - 1) * 6
		columnsSpace := (columnsCount - 1) * 6
		maxPossHeight := (fieldHeight - rowsSpace) / rowsCount
		maxPossHeight := Floor(maxPossHeight / 9) * 9
		maxPossWidth := (fieldWidth - (columnsCount - 1) * 6) / columnsCount
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

		videoPozX := (fieldWidth - (videoWidth * columnsCount + columnsSpace)) / 2
		videoPozY := (fieldHeight - (videoHeight * rowsCount + rowsSpace)) / 2 + 53

		

		; sometimes Zoom decides to make video little smaller - i don't know why :-(
		; we have to check it
		pixX := Ceil((fieldWidth - (videoWidth * columnsCount + columnsSpace)) / 2) + 1
		pixY := Ceil((fieldHeight - (videoHeight * rowsCount + rowsSpace)) / 2) + 53 + 1
		if (vsWidth > 0) {
			videoPozX := videoPozX + vsWidth + 18
			videoPozY := videoPozY + 42
			pixX := pixX + vsWidth + 18
			pixY := pixY + 42
		}
		
		PixelGetColor, color, %pixX%, %pixY%, RGB
		nr := 0
		while (color = 0x1A1A1A && nr < 1) {
			nr++
			videoWidth := videoWidth - 16
			videoHeight := videoHeight - 9
			videoPozX := Ceil((fieldWidth - (videoWidth * columnsCount + columnsSpace)) / 2)
			videoPozY := Ceil((fieldHeight - (videoHeight * rowsCount + rowsSpace)) / 2) + 53
			pixX := Ceil((fieldWidth - (videoWidth * columnsCount + columnsSpace)) / 2) + 1
			pixY := Ceil((fieldHeight - (videoHeight * rowsCount + rowsSpace)) / 2) + 53 + 1
			if (vsWidth > 0) {
				videoPozX := videoPozX + vsWidth + 18
				videoPozY := videoPozY + 42
				pixX := pixX + vsWidth + 18
				pixY := pixY + 42
			}

			PixelGetColor, color, %pixX%, %pixY%, RGB
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
	
		; --- for debuging only ---
		if (debug) {
			videoGuiPozX :=	videoPozX + WinPosX + 8
			videoGuiPozY :=	videoPozY + WinPosY + 31
			videoGuiPozX = x%videoGuiPozX%
			videoGuiPozY = y%videoGuiPozY%
			videoGuiWidth = w%videoWidth%
			videoGuiHeight = h%videoHeight%
			GuiControl, VideoGUI:Text, Textarea, %videoPozX%, %videoPozY%`nRatio: %maxRatio%`nVS width:%vsWidth%`n%nr%
			Gui, VideoGUI:Show, NoActivate %videoGuiPozX% %videoGuiPozY% %videoGuiWidth% %videoGuiHeight%
			;Sleep, 700
			;Gui, VideoGUI:Hide
		}
		; ---------2123
	}
}
Return

#IfWinActive ahk_class ZPContentViewWndClass
/*
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
*/
F9::
	cl := GetVideoShareClass()
	msgbox %cl%
Return

; --- for debuging only ---
F8::
WinActivate, ahk_class ZPContentViewWndClass
MouseGetPos, mouseX, mouseY
BlockInput, MouseMove
if (debug) {
	Gui, VideoGUI:Show, NoActivate %videoGuiPozX% %videoGuiPozY% %videoGuiWidth% %videoGuiHeight%
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
		MouseMove, XPoz+10, YPoz, 2 ; unmute
		;Sleep, 100
		Click
	} else {
		;msgbox mute and lower hand
		MouseMove, XPoz+10, YPoz, 2 ; mute first
		;Sleep, 100
		Click
		;Sleep, 100
		if (lowerHand) {
			MouseMove, XPoz, YPoz+10, 2 ; then lower hand
			;Sleep, 100
			Click, right
			MouseMove, XPoz+20, YPoz+30, 2
			;Sleep, 100
			Click
		}
	}
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
	;msgbox %videoshare%
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

VideoShareWidth() {
	; There is a problem to get "ahk_class [TAB]ZPControlPanelHintClass" because of TAB char
	if (WinExist("Screen share viewing options")) {
		if (!videoShareClass) {
			videoShareClass := GetVideoShareClass()
		}
		ControlGetPos, , , w,, %videoShareClass%, ahk_class ZPContentViewWndClass
		return w
	}
	return 0
}

GetVideoShareClass(){
	WinActivate, ahk_class ZPContentViewWndClass
	BlockInput, MouseMove
	MouseGetPos, x, y
	MouseMove, 100, y, 0
	MouseGetPos, , , , className
	MouseMove, x, y, 0
	BlockInput, MouseMoveOff
	return className
}
/*

ClassNN:	CASView_0x2BB762701
Text:	
	x: 14	y: 84	w: 816	h: 882
Client:	x: 6	y: 53	w: 816	h: 882


Screen share viewing options
ahk_class 	ZPControlPanelHintClass
*/