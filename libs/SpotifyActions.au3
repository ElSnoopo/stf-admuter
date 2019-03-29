func _mute()
	local $winTitle, $subStrPos, $i = 0, $j = 1
	;TrayTip("", "Mute eingeleitet", 1)

	sleep(50)

	while $i < 10
		if _noKeyDown() Then
			ControlSend($appName, "", "", "^{DOWN 2}")
			Send("{ALTUP}")
			Send("{CTRLUP}")
			inc($i)
		else
			sleep(250)
			if $j then
				TrayTip("", "Bitte kurz nichts drücken", 2)
				$j = 0
			EndIf
		EndIf
	WEnd

	;TrayTip("", "Mute abgeschlossen", 1)												;debug traytip

	$winTitle = _getUnifiedTitle($appName)
	sleep(100)
	$subStrPos = StringInStr(_getUnifiedTitle($appName), "Spotify ", 0)

	if $subStrPos = 0 then
		send("{MEDIA_PLAY_PAUSE}")
		;TrayTip("", "Wiedergabe fortgesetzt", 1)											;debug traytip
	Else
		If $subStrPos = 1 Then
			;TrayTip("", "Wiedergabe ist ordnungsgemaess weitergelaufen", 1)				;debug traytip
		else
			;TrayTip("", "Substring an Position " & $subStrPos & " gefunden.", 1)			;debug traytip
		EndIf
	EndIf

	sleep(50)
	;ControlSend($appName, "", "", "^{RIGHT}")
	$muted = True

	Send("{ALTUP}")
	Send("{CTRLUP}")

	return _getUnifiedTitle($appName)
EndFunc


; ------------------------------------------------------------------------------

func _getWindowTitle($spotifyWindow)
	local $title

	$title = WinGetTitle($spotifyWindow)

EndFunc


; ------------------------------------------------------------------------------

func _resumeState()
	local $i = 0, $j = 1
	;TrayTip("", "Lautstärkewiederherstellung eingeleitet", 1)							;debug traytip

	sleep(100)

	while $i < 10
		if _noKeyDown() Then
			ControlSend($appName, "", "", "^{UP 2}")
			Send("{ALTUP}")
			Send("{CTRLUP}")
			inc($i)
		else
			sleep(250)
			if $j then
				TrayTip("", "Bitte kurz nichts drücken", 2)
				$j = 0
			EndIf
		EndIf
	WEnd

	sleep(100)

	Send("{ALTUP}")
	Send("{CTRLUP}")

	;TrayTip("", "Lautstärkewiederherstellung abgeschlossen", 1)							debug traytip

	$muted = False
	return WinGetTitle($appName)
EndFunc


; ------------------------------------------------------------------------------

func _playPause()
	;ControlSend("Spotify", "", "", "{SPACE}")

	$debugOldTitle = _getUnifiedTitle($appName)

	if (Send("{MEDIA_PLAY_PAUSE}") And (_getUnifiedTitle("[CLASS:SpotifyMainWindow]") <> $debugOldTitle)) then
		TrayTip("", "Leertaste gesendet", 1)
	else
		TrayTip("", "Senden fehlgeschlagen", 1, 1)
	EndIf

	sleep(50)
EndFunc
