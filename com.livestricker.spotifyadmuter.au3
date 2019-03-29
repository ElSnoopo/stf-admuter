#cs

   Spotify AdMuter v0.3
   The software is licensed under GNU GPL 2.0: https://github.com/ElSnoopo/stf-admuter/blob/master/LICENSE

#ce

; bibs --------------------------------------------------------------------------------------------------------------------------------------------------------------------

#include <Array.au3>
#include <File.au3>
#include <SendMessage.au3>
#include <Misc.au3>
#include "libs\FileOperations.au3"
#include "libs\StfInteractions.au3"


; hotkeys --------------------------------------------------------------------------------------------------------------------------------------------------------------------

HotKeySet("!{a}", "_addTitle")																									; Alt-A (add)   -> blacklist currently played title
HotKeySet("!{p}", "_scriptPause")																								; Alt-P (pause)	-> pause script
HotKeySet("!{s}", "_main")																											; Alt-S (start)	-> (re)start main function, used against malfunctions
HotKeySet("!{c}", "_quit")																											; Alt-C (close) -> close the AdMuter
;HotKeySet("!{x}", "_playPause")																								; Alt-X 		-> play/pause (not properly implemented yet)
HotKeySet("!{u}", "_changeSpotifyVersion")																			; Alt-U 		-> change version mode from 0.9 to 1.0 and vice versa
HotKeySet("!{h}", "_showMuterInfo")																							; Alt-H (help)	-> show commands and settings
;HotKeySet("!{d}", "_debug")																										; Alt-D (debug) -> enter debug mode (not implemented yet)


; global variables -------------------------------------------------------------

Global 	$running = True, _																											; initialize running variable (can be switched via Alt-P)
				$titleList[0], _																												; creates an empty local title list array
				$firstStart = True, _																										; first start variable, see main function
				$scriptName = "Spotify AdMuter", _																			; script name, used in multiple occasions later on
;				$muted = False																													; default: volume is up - MOVED TO MAIN

Global	$dataFile = "werbetitel_0-3.txt", _																			; data file name ("blacklist.txt")
				$versionFile = "lastversion_0-3.txt", _																	; version mode cache, may or may not be integrated into the blacklist later on
				$appName																																; Spotify window name for title catching

Global 	$spotifyVersion																													; initialize version mode variable, used multiple times in the script


; pre-start catches ------------------------------------------------------------

if UBound(ProcessList("com.livestricker.spotifyadmuter.exe")) < 3 Then					; check if AdMuter is already running
	_main()																																				; if not, start main function
	;MsgBox( "", $ScriptName, "Instanzen: " & UBound(ProcessList("com.livestricker.spotifyadmuter.exe")))			; debug message that lists the number of currently running AdMuter instances - did not work as expected
Else
	MsgBox( "" , $ScriptName, "Anwendung läuft bereits!", 5)											; if it's already running, remind the user (MsgBox flag 5: okay button)
	;MsgBox( "", $ScriptName, "Instanzen: " & UBound(ProcessList("com.livestricker.spotifyadmuter.exe")))
	Exit																																					; and exit the script
EndIf


; main loop --------------------------------------------------------------------
func _main()
	Local $winTitle = " ", _ 																											; local Spotify window title caches
			$newTitle, _
			$spotifyVersion, _																												; local version number cache
			$versionString, _																													; version string cache
			$muted = False																														; default: volume is up

	if $firstStart Then																														; first start operations,
		_readDataFile($dataFile)																										; put contents of blacklist.txt into a local array - a closed file can't be corrupted as easily
		$spotifyVersion = _readVersionFile($versionFile)														; get last used version mode (int value, used in the script)

		if $spotifyVersion = 1 Then																									; set the appName variable depending on the version mode
			$appName = [CLASS:Chrome_WidgetWin_0]																			; Spotify 1.0 is basically just a Chromium wrapper
		else if $spotifyVersion = 0 Then
				$appName = [CLASS:SpotifyMainWindow]																		; Spotify 0.9 was an independent application with Chromium integrated for everything beside the sidebars
			EndIf
		EndIf

		$versionString = _getVersionString($spotifyVersion)													; convert int value to displayable text (used in tray tips and msgboxes)

		TrayTip($scriptName & " gestartet", "" & _																	; initial tray tip with basic information, uses native Win 10 notifications
		 "Alt-H drücken, um eine Übersicht der Hotkeys zu öffnen" & @crlf & _
		 @crlf & UBound($titleList) & " Titel in der Datenbank" & @crlf & @crlf & _
		 "Aktueller Modus: Spotify " & $versionString, 1)
		;MsgBox(0, $scriptName, "Daten eingelesen. " & _
		; _filecountlines("werbetitel.txt") & _
		; " Titel in der Datenbank vorhanden.", 2)
		$firstStart = False																													; flag first start as false, otherwise the first start operations would be executed every time _main() loops
		;$winTitle = "Spotify"
	EndIf

	while 1																																		; actual main loop
		sleep(100)																																	; polling frequency, massive influence on system load! set to 200 or even 500 on slower systems (e.g. old Intel Atoms)
		if $running then																														; script paused?
			$newTitle = _getUnifiedTitle($appName)																		; get new title (still uses outdated unified title function that was implemented due to my stupidity)
			if (($spotifyVersion = 1) and ($newTitle <> "spotify")) then _						; adds "spotify" to the title when Spotify 1.0 mode is used to ensure cross-compatibility - possibly unnecessary
			 $newTitle = "spotify" + $newTitle
			;TrayTip("","Neue Runde", 1)																							; debug tray tip
			if ($newTitle <> $winTitle) Then																					; is the new title the same as the one in the last loop?
			;TrayTip("", "Neuer Titel", 2)
			;_stringUnify($newTitle)
			if $newTitle <> "spotify" Then																						; is the new title not just "Spotify"? (= music paused?)
				if _adExists($newTitle) Then																						; is the new title already in the blacklist?
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


func _adExists($winTitle, $tList)
	local $i = 0, _
			$tExists = False

	if ProcessExists("spotify.exe") then
		while (($i < UBound($tList)) And (not $tExists))
			if $winTitle = $titleList[$i] then $tExists = True
			$i += 1
		WEnd
	EndIf

	return $tExists
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


#cs --------------------------              LEGACY CODE, REPLACED BY _getWindowTitle() in SpotifyActions.au3
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



#cs
func _debug()
   MsgBox("", "", WinGetTitle($appName), 2)
EndFunc
#ce


func _changeVersion($sName, $vFile, ByRef $version, ByRef $vString)
	if $version = 1 then
		$version = 0
	Else
		$version = 1
	EndIf

	$vString = _getVersionString($version)

	FileOpen($vFile, 2)
	FileWrite($vFile, $version)
	FileClose($vFile)

	TrayTip($sName, "Spotify-Version auf " & _getVersionString($version) & " geändert.", 3)
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
