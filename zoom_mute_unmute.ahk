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
buttonXoffset := -70
buttonYoffset := 22
;buttonColor := 0x0D67D8
buttonColor := 0x0D68D8
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
SetTimer, CheckParticipants, 500
Return

CheckParticipants:
winTitle := "ahk_class ZPContentViewWndClass"
curWin := WinExist(winTitle)
If (curWin) {
	WinGetPos, WinPosX, WinPosY, winWidth, winHeight, %winTitle%
	GetClientSize(curWin, winWidth, winHeight)
	ControlGetText, str, zPlistWndClass1, %winTitle%
	ControlGetPos, , , listWidth, , zRightPanelContainerClass1, %winTitle%

	pcpsCount := SubStr(str, 15, -1) ; participant's counter
	if (pcpsCount > maxPcpsCount) {
		pcpsCount := maxPcpsCount
	}
	; We recount video position ONLY when:
	;   * window's size
	;   * window's position
	;   * participant's panel's size
	;   * participant's number
	; changed
	if ((oldPcpsCount != pcpsCount) || (WinPosX != oldWinPosX) || (WinPosY != oldWinPosY) || (winWidth != oldWinWidth) || (winHeight != oldWinHeight) || (oldListWidth != listWidth)) {
		oldWinPosX := WinPosX
		oldWinPosY := WinPosY
		oldWinWidth := winWidth
		oldWinHeight := winHeight
		oldPcpsCount := pcpsCount
		oldListWidth := listWidth
		
		fieldWidth := winWidth - listWidth
		fieldHeight := winHeight - 53 - 53

		maxRatio := 0
		maxRatioIndex := 1
		pcpsCountL := Ceil(sqrt(pcpsCount)) + 1
		pcpsCount++ ; we add one participant to minus it in while loop :-)
		opCount := 0 ; for debuging only
		while (maxRatio < minRatio) {
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
			GuiControl, HelperGUI:Text, helperGuiText, Op. count: %opCount%, Pcps. %pcpsCount%
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
		PixelGetColor, color, %pixX%, %pixY%, RGB
		if (color = 0x1A1A1A) {
			videoWidth := videoWidth - 16
			videoHeight := videoHeight - 9
			videoPozX := Ceil((fieldWidth - (videoWidth * columnsCount + columnsSpace)) / 2)
			videoPozY := Ceil((fieldHeight - (videoHeight * rowsCount + rowsSpace)) / 2) + 53
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

		/*
		buttonColor := GetButtonColor(Win1XPoz, WinYPoz)

		if (buttonColor) {
			MsgBox, 36, Zoom Unmute / Mute Settings, Settings saved successfully. Do you want to see how it is set?
			IfMsgBox, No
				Return
			MouseMove, Win1XPoz, WinYPoz, 4 ; first participant
			Sleep, 200
			MouseMove, Win2XPoz, WinYPoz, 4 ; second participant
			Sleep, 200
			MouseMove, Win3XPoz, WinYPoz, 4 ; third participant
			Sleep, 200
		}
		*/
		
		; --- for debuging only ---
		if (debug) {
			videoGuiPozX :=	videoPozX + WinPosX + 8
			videoGuiPozY :=	videoPozY + WinPosY + 31
			videoGuiPozX = x%videoGuiPozX%
			videoGuiPozY = y%videoGuiPozY%
			videoGuiWidth = w%videoWidth%
			videoGuiHeight = h%videoHeight%
			GuiControl, VideoGUI:Text, Textarea, %videoPozX%, %videoPozY%`nRatio: %maxRatio%
			Gui, VideoGUI:Show, NoActivate %videoGuiPozX% %videoGuiPozY% %videoGuiWidth% %videoGuiHeight%
			Sleep, 700
			Gui, VideoGUI:Hide
		}
		; ---------
	}
}
Return

Numpad0::
	SwitchMic(videoButton1PozX, videoButton1PozY, buttonColor, false)
Return

Numpad1::
	SwitchMic(videoButton1PozX, videoButton1PozY, buttonColor)
Return

Numpad2::
	SwitchMic(videoButton2PozX, videoButton2PozY, buttonColor)
Return

Numpad3::
	SwitchMic(videoButton3PozX, videoButton3PozY, buttonColor)
Return

; mute without lower hand
Numpad4::
	SwitchMic(videoButton1PozX, videoButton1PozY, buttonColor, false)
Return

Numpad5::
	SwitchMic(videoButton2PozX, videoButton2PozY, buttonColor, false)
Return

Numpad6::
	SwitchMic(videoButton3PozX, videoButton3PozY, buttonColor, false)
Return

SwitchMic(ByRef XPoz, ByRef YPoz, ByRef buttonColor, lowerHand := true)
{
	BlockInput, MouseMove
	WinActivate, ahk_class ZPContentViewWndClass
	MouseMove, XPoz, YPoz, 3
	Sleep, 100

	PixelGetColor, color, %XPoz%, %YPoz%, RGB
	Sleep, 100
	;msgbox Button color: %buttonColor%, founded %color%
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


GetClientSize(hWnd, ByRef w := "", ByRef h := "")
{
	VarSetCapacity(rect, 16)
	DllCall("GetClientRect", "ptr", hWnd, "ptr", &rect)
	w := NumGet(rect, 8, "int")
	h := NumGet(rect, 12, "int")
}

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