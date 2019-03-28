#cs

   Spotify AdMuter v0.3
   The software is licensed under GNU GPL 2.0: https://github.com/ElSnoopo/stf-admuter/blob/master/LICENSE

#ce

; bibs --------------------------------------------------------------------------------------------------------------------------------------------------------------------

#include <Array.au3>
#include <File.au3>
#include <SendMessage.au3>
#include <Misc.au3>


; hotkeys --------------------------------------------------------------------------------------------------------------------------------------------------------------------

HotKeySet("!{a}", "_addTitle")																											; Alt-A (add)   -> blacklist currently played title
HotKeySet("!{p}", "_scriptPause")																										; Alt-P (pause)	-> pause script
HotKeySet("!{s}", "_main")																													; Alt-S (start)	-> (re)start main function, used against malfunctions
HotKeySet("!{c}", "_quit")																													; Alt-C (close) -> close the AdMuter
;HotKeySet("!{x}", "_playPause")																											; Alt-X 		-> play/pause (not properly implemented yet)
HotKeySet("!{u}", "_changeSpotifyVersion")																							; Alt-U 		-> change version mode from 0.9 to 1.0 and vice versa
HotKeySet("!{h}", "_showHotKeys")																										; Alt-H (help)	-> show commands and settings
;HotKeySet("!{d}", "_debug")																												; Alt-D (debug) -> enter debug mode (not implemented yet)


; global variables --------------------------------------------------------------------------------------------------------------------------------------------------------------------

Global 	$running = True, _																												; initialize running variable (can be switched via Alt-P)
			$titleList[0], _																													; creates an empty local title list array
			$firstStart = True, _																											; first start variable, see main function
			$scriptName = "Spotify AdMuter", _																							; script name, used in multiple occasions later on
			$muted = False																														; default: volume is up

Global	$dataFile = "werbetitel_0-3.txt", _																							; data file name ("blacklist.txt")
			$versionFile = "lastversion_0-3.txt", _																					; version mode cache, may or may not be integrated into the blacklist later on
			$appName																																; Spotify window name for title catching

Global 	$spotifyVersion																													; initialize version mode variable, used multiple times in the script


; pre-start catches --------------------------------------------------------------------------------------------------------------------------------------------------------------------

if UBound(ProcessList("com.livestricker.spotifyadmuter.exe")) < 3 Then														; check if AdMuter is already running
	_main()																																		; if not, start main function
	;MsgBox( "", $ScriptName, "Instanzen: " & UBound(ProcessList("com.livestricker.spotifyadmuter.exe")))			; debug message that lists the number of currently running AdMuter instances - did not work as expected
Else
	MsgBox( "" , $ScriptName, "Anwendung läuft bereits!", 5)																		; if it's already running, remind the user (MsgBox flag 5: okay button)
	;MsgBox( "", $ScriptName, "Instanzen: " & UBound(ProcessList("com.livestricker.spotifyadmuter.exe")))
	Exit																																			; and exit the script
EndIf


; main loop --------------------------------------------------------------------------------------------------------------------------------------------------------------------
func _main()
	Local $winTitle = " ", _ 																												; local Spotify window title caches
		$newTitle, _
		$spotifyVersion																														; local version number cache
		$versionString																															; version string cache

	if $firstStart Then																														; first start operations,
		_readDataFile($dataFile)																											; put contents of blacklist.txt into a local array - a closed file can't be corrupted as easily
		$spotifyVersion = _readVersionFile($versionFile)																			; get last used version mode (int value, used in the script)

		if $spotifyVersion = 1 Then																										; set the appName variable depending on the version mode
			$appName = [CLASS:Chrome_WidgetWin_0]																						; Spotify 1.0 is basically just a Chromium wrapper
		else if $spotifyVersion = 0 Then
				$appName = [CLASS:SpotifyMainWindow]																					; Spotify 0.9 was an independent application with Chromium integrated for everything beside the sidebars
			EndIf
		EndIf

		$versionString = _getVersionString($spotifyVersion)																		; convert int value to displayable text (used in tray tips and msgboxes)

		TrayTip($scriptName & " gestartet", "" & _																					; initial tray tip with basic information, uses native Win 10 notifications
			"Alt-H drücken, um eine Übersicht der Hotkeys zu öffnen" & @crlf & @crlf & _
			UBound($titleList) & " Titel in der Datenbank" & @crlf & @crlf & _
			"Aktueller Modus: Spotify " & $versionString, 1)
		;MsgBox(0, $scriptName, "Daten eingelesen. " & _filecountlines("werbetitel.txt") & " Titel in der Datenbank vorhanden.", 2)
		$firstStart = False																													; flag first start as false, otherwise the first start operations would be executed every time _main() loops
		;$winTitle = "Spotify"
	EndIf

	while 1																																	; main loop
		sleep(100)																																; polling frequency, massive influence on system load! set to 200 or even 500 on slower systems (e.g. old Intel Atoms)
		if $running then																														; script paused?
			$newTitle = _getUnifiedTitle($appName)																						; get new title (still uses outdated unified title function that was implemented due to my stupidity)
			if (($spotifyVersion = 1) and ($newTitle <> "spotify")) then $newTitle = "spotify" + $newTitle			; adds "spotify" to the title when Spotify 1.0 mode is used to ensure cross-compatibility - possibly unnecessary
			;TrayTip("","Neue Runde", 1)																									; debug tray tip
			if ($newTitle <> $winTitle) Then																								; is the new title the same as the one in the last loop?
			;TrayTip("", "Neuer Titel", 2)
			;_stringUnify($newTitle)
			if $newTitle <> "spotify" Then																								; is the new title not just "Spotify"? (= music paused?)
				if _adExists($newTitle) Then																								; is the new title already in the blacklist?
					if not $muted Then																										; is Spotify not muted?
						$winTitle = _mute()
						TrayTip("", "Werbung gemutet", 1)
						Sleep(100)
						send("{ALTUP}")
					EndIf
				Elseif $muted Then
					$winTitle = _resumeState()
					TrayTip("", "Lautstärke wieder hochgefahren", 1)
					sleep(100)
					Send("{ALTUP}")
				Else
					;$muted = False
					$winTitle = _getUnifiedTitle($appName)
				EndIf
			EndIf
		 EndIf
	  EndIf
	WEnd
EndFunc


func _readDataFile($fName)
	if FileExists($fName) Then
		local $fLines = _FileCountLines($fName)
		ReDim $titleList[$fLines]

		FileOpen($fName)

		for $i = 0 to ($fLines-1) step 1
			$titleList[$i] = FileReadLine($fName, ($i+1))
		next

		FileClose($fName)
	Else
		FileWrite($fName, "")
	EndIf
EndFunc


func _readVersionFile($fName)
	local $versionNumber

	if FileExists($fName) Then
		FileOpen($fName)
		$versionNumber = FileReadLine($fName, 1)
		FileClose($fName)
		return $versionNumber
	Else
		FileWrite($fName, "1")
		MsgBox("", "Spotify AdMuter", "Keine Versionsinformation gefunden!" & @CRLF & "Version automatisch auf 1.x festgelegt." & _
			@CRLF & "Zum Wechseln auf Version 0.9.x bitte Alt-U drücken." & @CRLF & "Die Auswahl wird für den nächsten Start gespeichert.")
	EndIf

EndFunc


func _adExists($winTitle)
	local $i = 0, $tExists = False
	if ProcessExists("spotify.exe") then
		while (($i < UBound($titleList)) And (not $tExists))
			if $winTitle = $titleList[$i] then $tExists = True
			$i += 1
		WEnd
	EndIf

	return $tExists
EndFunc


func _addTitle()
	$title = _getUnifiedTitle($appName)
	if (($spotifyVersion = 1) and ($title <> "spotify")) then $title = "spotify" + $title														; SPOTIFY KLEIN

	if not (_adExists($title) Or ($title = "spotify")) Then																								; SPOTIFY KLEIN
		local $newDim = UBound($titleList)+1
		;MsgBox(0, "Titel", _getUnifiedTitle($appName), 2)
		ReDim $titleList[$newDim]

		$titleList[$newDim-1] = $title

		FileOpen($dataFile)
		FileWriteLine($dataFile, $title)
		FileClose($dataFile)

		TrayTip("", "'" & $title & "' zur Werbeliste hinzugefügt.", 2)
		_mute()
	Else
		TrayTip("", "Fehler: Titel schon in der Datenbank vorhanden!", 3)
	EndIf

	_main()
EndFunc


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


func _scriptPause()
	if $running then
		$running = False
		TrayTip("", $scriptName & " pausiert", 1)
	else
		$running = True
		TrayTip("", $scriptName & " wird fortgesetzt", 1)
	EndIf
EndFunc


func _quit()
	TrayTip("", $scriptName & " beendet", 2)
	sleep(2000)
	Exit
EndFunc


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

#cs --------------------------              LEGACY CODE, REPLACED BY _getWindowTitle()
func _stringUnify(ByRef $title)
   $title = StringLower($title)
   $title = StringReplace($title, "–", "")
   $title = StringRegExpReplace($title, "[- #!?$'üäöß¨.,:%„“]", "")
EndFunc


func _getUnifiedTitle($WindowTitle)
   local $title
   $title = WinGetTitle($WindowTitle)
   _stringUnify($title)

   Return $title
EndFunc
#ce --------------------------

func _getWindowTitle()
	local $title

	$title = WinGetTitle($spotifyWindow)

EndFunc

#cs
func _debug()
   MsgBox("", "", WinGetTitle($appName), 2)
EndFunc
#ce

func _noKeyDown()
	local $i, $noKeyDown = True

	for $i = 0 to 255
		if _IsPressed(hex($i)) Then
			$noKeyDown = False
		EndIf
	Next

	return $noKeyDown
EndFunc


func _changeSpotifyVersion()
	if $spotifyVersion = 1 then
		$spotifyVersion = 0
	Else
		$spotifyVersion = 1
	EndIf

	FileOpen($versionFile, 2)
	FileWrite($versionFile, $spotifyVersion)
	FileClose($versionFile)

	TrayTip($scriptName, "Spotify-Version auf " & _getVersionString($spotifyVersion) & " geändert.", 3)
EndFunc


func _showHotKeys()
	MsgBox("", $scriptName & " - Hotkeys", _
		"Alt-A: Titel zur Werbeliste hinzufügen" & @CRLF & _
		"Alt-U: Spotify-Version wechseln" & @CRLF & _
		"Alt-P: Pausieren" & @CRLF & _
		"Alt-C: Beenden" & @CRLF & @CRLF & _
		"Alt-S: Zurücksetzen der Anwendung im Falle eines Problems" & @CRLF & _
		"Alt-H: diese Infobox" & @CRLF & @CRLF & _
		"Aktueller Modus: Spotify " & _getVersionString($spotifyVersion), "")
EndFunc


func inc(ByRef $number)
	$number += 1
EndFunc


func _getVersionString($version)

	local $result

	if $version = 1 then
		$result = "1.x"
	Else
		$result = "0.9.x"
	EndIf

	return $result
EndFunc


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
