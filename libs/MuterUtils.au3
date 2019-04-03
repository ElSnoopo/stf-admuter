#cs ----------------------------------------------------------------------------
#   Muter-specific utilities
#   currently included:
#   - keydown checker
#   - information menu
#   - muter quit function
#ce ----------------------------------------------------------------------------

#include <Misc.au3>																															; includes _IsPressed()

func _noKeyDown()
	local $i, $noKeyDown = True, _
				$hDLL = DllOpen("user32.dll")

	for $i = 0 to 255
		if _IsPressed(hex($i), $hDLL) Then
			$noKeyDown = False
		EndIf
	Next

	DllClose($hDLL)

	return $noKeyDown
EndFunc


; ---------------------- legacy function, replaced by _IsPressed ---------------
#cs
Func _WinAPI_GetKeyboardState($iFlag)	;Function by UEZ@autoitscript.com
	Local $aDllRet, $lpKeyState = DllStructCreate("byte[256]")
	$aDllRet = DllCall("User32.dll", "int", "GetKeyboardState", "ptr", DllStructGetPtr($lpKeyState))
	If @error Then Return SetError(@error, 0, 0)
	If $aDllRet[0] = 0 Then
		Return SetError(1, 0, 0)
	Else
		Switch $iFlag
			Case 0
				Local $aReturn[256]
				For $i = 1 To 256
					$aReturn[$i - 1] = DllStructGetData($lpKeyState, 1, $i)
				Next
					Return $aReturn
			Case Else
				Return DllStructGetData($lpKeyState, 1)
		EndSwitch
	EndIf
EndFunc
#ce

; ------------------------------------------------------------------------------

func _showMuterInfo()
	MsgBox("", $scriptName & " - Hotkeys", _
		"Alt-A: Titel zur Werbeliste hinzufügen" & @CRLF & _
		"Alt-U: Spotify-Version wechseln" & @CRLF & _
		"Alt-P: Pausieren" & @CRLF & _
		"Alt-C: Beenden" & @CRLF & @CRLF & _
		"Alt-S: Zurücksetzen der Anwendung im Falle eines Problems" & @CRLF & _
		"Alt-H: diese Infobox" & @CRLF & @CRLF & _
		"Aktueller Modus: Spotify " & _getVersionString($spotifyVersion), "")
EndFunc


; ------------------------------------------------------------------------------

func _quit($sName)
	TrayTip("", $scriptName & " beendet", 2)
	sleep(2000)
	Exit
EndFunc
