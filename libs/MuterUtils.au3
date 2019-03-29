#cs ----------------------------------------------------------------------------
#   Muter-specific utilities
#   currently included:
#   - keyboard state checker
#   - keydown checker
#   - information menu
#   - muter quit function
#ce ----------------------------------------------------------------------------

func _noKeyDown()
	local $i, $noKeyDown = True

	for $i = 0 to 255
		if _IsPressed(hex($i)) Then
			$noKeyDown = False
		EndIf
	Next

	return $noKeyDown
EndFunc


; ------------------------------------------------------------------------------

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
