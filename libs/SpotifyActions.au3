func _mute($aClass, $sVersion, $wTitle, $mute)
	local	$i = 0, _																																; running variable
				$loopLimit, _																														; number of loops, depending on version mode
				$noTrayTip = 1, _																												; tray tip indicator, so the user won't be spammed with "hey, listen"
				$muteCmnd, _																														; command that's sent to Spotify
				$muted = 0																															; return/success value

	;TrayTip("", "Mute eingeleitet", 1)

	Switch $sVersion																															; version-dependent settings
	Case 0
		$loopLimit = 20																															; Spotify 0.9 doesn't have a shortcut for mute, you can only de- or
		if $mute then $muteCmnd = "^{DOWN}" Else $muteCmnd = "^{UP}"								; increase the program's volume by pressing Ctrl-Down/Up
	Case 1
		$loopLimit = 1																															; in Spotify 1.0, you mute and unmute with Ctrl-Shift-Down - way easier
		$muteCmnd = "^+{DOWN}"
	EndSwitch

	sleep(50)

	while $i < $loopLimit																													; mute loop for both versions for the sake of simplicity
		if _noKeyDown() Then																												; old bug - keystrokes disturb the muter, so no key must be pressed
			ControlSend($aClass, "", "", $muteCmnd)																		; muteCmnd is directly sent to the Spotify window
			inc($i)
		else
			if $noTrayTip then																												; tray tip to stop typing is only displayed once
				TrayTip("", "Bitte kurz nichts drücken", 2)
				$noTrayTip = 0
			EndIf
			sleep(500)																																; we'll give the user half a second to react and try again
		EndIf
	WEnd

	;TrayTip("", "Mute abgeschlossen", 1)												;debug traytip

	if ((not $sVersion) And (WinGetTitle($aClass) <> $wTitle)) Then								; Spotify 0.9 pauses the playback when the player's volume is decreased quickly,
		ControlSend($aClass, "", "", "{SPACE}")																			; so we detect this behavior and re-start the playback when this happens
	EndIf

	sleep(50)
	;ControlSend($aClass, "", "", "^{RIGHT}")
	$muted = 1

	Send("{ALTUP}")																																; bug prevention - sometimes Alt and Ctrl get "stuck"
	Send("{CTRLUP}")
	Send("{SHIFTUP}")																															; Shift is now also used (since v0.3), so we include it here

	return $muted																																	; everything okay? good.
EndFunc


; -------------- legacy function, not used anymore -----------------------------
#cs
func _getWindowTitle($spotifyWindow)
	local $title

	$title = WinGetTitle($spotifyWindow)

EndFunc
#ce

; -------------- legacy function, not used anymore -----------------------------
#cs
func _playPause($aClass)
	;ControlSend("Spotify", "", "", "{SPACE}")

	$debugOldTitle = _getUnifiedTitle($aClass)

	if (Send("{MEDIA_PLAY_PAUSE}") And (_getUnifiedTitle("[CLASS:SpotifyMainWindow]") <> $debugOldTitle)) then
		TrayTip("", "Leertaste gesendet", 1)
	else
		TrayTip("", "Senden fehlgeschlagen", 1, 1)
	EndIf

	sleep(50)
EndFunc
#ce
