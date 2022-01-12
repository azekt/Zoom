CoordMode, Pixel, Client
CoordMode, Mouse, Client

F8::
WinActivate, ahk_class ZPContentViewWndClass
MsgBox, 65, Zoom Unmute / Mute Settings, Place the mouse cursor on upper left Zoom Gallery FIRST participant's window's corner and press "OK"
IfMsgBox, Cancel
	Return
MouseGetPos, xul, yul
If (xul < 0) {
	Msgbox, 48, Zoom Unmute / Mute Settings, Zoom Window was not active! Try again!
	Return
}
MsgBox, 65, Zoom Unmute / Mute Settings, Now place the mouse cursor on upper left Zoom Gallery second participant's window's corner and press "OK"
IfMsgBox, Cancel
	Return
MouseGetPos, xur, yur
buttonXoffset := -75
buttonYoffset := 22
windowSizeX := xur - xul
WinYPoz := yul + buttonYoffset
Win1XPoz := xul + windowSizeX + buttonXoffset
Win2XPoz := xul + windowSizeX*2 + buttonXoffset
Win3XPoz := xul + windowSizeX*3 + buttonXoffset
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
Return

Numpad0::
	SwitchMic(Win1XPoz, WinYPoz, buttonColor, false)
Return

Numpad1::
	SwitchMic(Win1XPoz, WinYPoz, buttonColor)
Return

Numpad2::
	SwitchMic(Win2XPoz, WinYPoz, buttonColor)
Return

Numpad3::
	SwitchMic(Win3XPoz, WinYPoz, buttonColor)
Return

SwitchMic(ByRef XPoz, ByRef YPoz, ByRef buttonColor, lowerHande := true)
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
		MouseMove, XPoz, YPoz+10, 2 ; then lower hande
		;Sleep, 100
		Click, right
		MouseMove, XPoz+20, YPoz+30, 2
		;Sleep, 100
		Click
	}
	BlockInput, MouseMoveOff
}

GetButtonColor(ByRef XPoz, ByRef YPoz)
{
	num := 0
	YPoz := YPoz - 1
	MouseMove, XPoz, YPoz, 1
	PixelGetColor, color, %XPoz%+10, %YPoz%, RGB
	While (color != 0x0D67D8 and color != 0x0D68D8 and num < 5) {
		YPoz := YPoz - 1
		PixelGetColor, color, %XPoz%+10, %YPoz%, RGB	
		num := num + 1
	}
	YPoz := YPoz - 1
	if (color != 0x0D67D8 and color != 0x0D68D8) {
		Msgbox, 48, Zoom Unmute / Mute Settings, Cannot set window's position correctly! Try again!
		return false
	}
	return color
}


