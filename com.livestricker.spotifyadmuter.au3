#cs

  Spotify AdMuter v0.3
  The software is licensed under GNU GPL 2.0: https://github.com/ElSnoopo/stf-admuter/blob/master/LICENSE

#ce

; includes ---------------------------------------------------------------------

#include <Array.au3>
#include <SendMessage.au3>
#include "libs\FileOps.au3"
#include "libs\SpotifyActions.au3"
#include "libs\MuterUtils.au3"
#include "libs\GeneralUtils.au3"


;  ---------------------------------hotkeys-------------------------------------
			; Alt-A (add)   -> blacklist currently played title
			; Alt-P (pause)	-> pause script
			; Alt-S (start)	-> (re)start main function, used against malfunctions
			; Alt-C (close) -> close the AdMuter
			; Alt-X 		-> play/pause (not properly implemented yet)
			; Alt-U 		-> change version mode from 0.9 to 1.0 and vice versa
			; Alt-H (help)	-> show commands and settings
			; Alt-D (debug) -> enter debug mode (not implemented yet)
;  ---------------------------------hotkeys-------------------------------------


HotKeySet("!{a}", "_addTitle")
HotKeySet("!{p}", "_scriptPause")
HotKeySet("!{s}", "_main")
HotKeySet("!{c}", "_quit")
;HotKeySet("!{x}", "_playPause")
HotKeySet("!{u}", "_changeSpotifyVersion")
HotKeySet("!{h}", "_showMuterInfo")
;HotKeySet("!{d}", "_debug")

; ----------------------------------global variables ---------------------------
; 			$scriptIsRunning 	 initialize running variable (can be switched via Alt-P)
; 			$titleList 	 creates an empty local title list array
; 			$firstStart	 variable, see main function
; 			script name, used in multiple occasions later on
; 			default: volume is up - MOVED TO MAIN
; ----------------------------------global variables ---------------------------

Global 	$scriptIsRunning = True, _
				$titleList[0], _
				$firstStart = True, _
				$scriptName = "Spotify AdMuter", _
;				$isMuted = False

Global	$dataFile = "werbetitel_0-3.txt", _																			; data file name ("blacklist.txt")
				$versionFile = "lastversion_0-3.txt", _																; version mode cache, may or may not be integrated into the blacklist later on
				$spotifyWindowClass																					; Spotify window name for title catching

Global 	$spotifyVersionAsNumber																						; initialize version mode variable, used multiple times in the script


;  ---------------------------pre-start catches--------------------------------------------------------------------
; 			check if AdMuter is already running if not, start main function
; 			debug message that lists the number of currently running AdMuter instances - did not work as expected
; 			if it's already running, remind the user (MsgBox flag 5: okay button) and exit the script
;  ---------------------------pre-start catches--------------------------------------------------------------------

if UBound(ProcessList("com.livestricker.spotifyadmuter.exe")) < 3 Then					
	_main()																																				
	;MsgBox( "", $ScriptName, "Instanzen: " & _ 																	
	; UBound(ProcessList("com.livestricker.spotifyadmuter.exe")))
Else
	MsgBox( "" , $ScriptName, "Anwendung läuft bereits!", 5)											
	;MsgBox( "", $ScriptName, "Instanzen: " & UBound(ProcessList("com.livestricker.spotifyadmuter.exe")))
	Exit																																					
EndIf


;  --------------------------------main loop------------------------------------
func _main()

	Local $spotifyWindowTitle = " ", _ 																											
			$newTitle, _
			$spotifyVersionAsNumber, _																												
			$spotifyVersionAsString, _																													
			$isMuted = False, _	         ; default: volume is up
			$pollsPerSecond = 10, _		 ; polling frequency - default: 10 Hz, massive influence on system load! set to 200 or even 500 on slower systems (e.g. old Intel Atoms)
			$spotifyTitleWhenPaused, _																											
			$waitTime = trunc(1000/$pollsPerSecond)

	if $firstStart Then																													
		_readDataFile($dataFile)																						; put contents of blacklist.txt into a local array - a closed file can't be corrupted as easily
		$spotifyVersionAsNumber = _readVersionFile($versionFile)														

		if $spotifyVersionAsNumber Then																					; set the spotifyWindowClass variable depending on the version mode
			$spotifyWindowClass = [CLASS:Chrome_WidgetWin_0]															; Spotify 1.0 is basically just a Chromium wrapper
			$spotifyTitleWhenPaused = "Spotify Free"
		else if $spotifyVersionAsNumber < 1 Then
				$spotifyWindowClass = [CLASS:SpotifyMainWindow]															; Spotify 0.9 was an independent application with Chromium integrated for everything beside the sidebars
				$spotifyTitleWhenPaused = "Spotify"
			EndIf
		EndIf
		
;------- convert int value to displayable text (used in tray tips and msgboxes)
		$spotifyVersionAsString = _getVersionString($spotifyVersionAsNumber)													
		;$waitTime = trunc(1000/$pollsPerSecond) kann raus

		TrayTip($scriptName & " gestartet", "" & _																	; initial tray tip with basic information, uses native Win 10 notifications
		 "Alt-H drücken, um eine Übersicht der Hotkeys zu öffnen" & @crlf & _
		 @crlf & UBound($titleList) & " Titel in der Datenbank" & @crlf & @crlf & _
		 "Aktueller Modus: Spotify " & $spotifyVersionAsString, 1)
		;MsgBox(0, $scriptName, "Daten eingelesen. " & _
		; _filecountlines("werbetitel.txt") & _
		; " Titel in der Datenbank vorhanden.", 2)
		$firstStart = False																							
		;$spotifyWindowTitle = "Spotify"
	EndIf
	
;--- actual main loop

	while 1																																																													
		if $scriptIsRunning then																	
			$newTitle = WinGetTitle($spotifyWindowClass)																				
			if (($spotifyVersionAsNumber ) and ($newTitle <> "Spotify")) then _				; du hast eine Variable für pausiert... adds "spotify" to the title when Spotify 1.0 mode is used to ensure cross-compatibility - possibly unnecessary
			 $newTitle = "Spotify" + $newTitle
			;TrayTip("","Neue Runde", 1)													; debug tray tip
			if ($newTitle <> $spotifyWindowTitle) Then										; is the new title the same as the one in the last loop?
			;TrayTip("", "Neuer Titel", 2)
			;_stringUnify($newTitle)
				if $newTitle <> "spotify" Then												; du hast eine Variable für pausiert...	; is the new title not just "Spotify"? (= music paused?)
					if _adExists($newTitle) Then											; is the new title already in the blacklist?
						if not $isMuted Then																										
							$spotifyWindowTitle = $newTitle
							_mute($spotifyWindowClass, $spotifyVersionAsNumber, $spotifyWindowTitle, 1) ; spotifyVersionAsNumber IST GLOBAL
							TrayTip("", "Werbung gemutet", 1)
							Sleep(19000)
						EndIf
					Elseif $isMuted Then
						$spotifyWindowTitle = _resumeState()
						TrayTip("", "Lautstärke wieder hochgefahren", 1)
						sleep($waitTime)
						Send("{ALTUP}")
					Else
						;$isMuted = False
						$spotifyWindowTitle = _getUnifiedTitle($spotifyWindowClass)
					EndIf
				EndIf
			EndIf
		EndIf
		sleep($waitTime)
	WEnd
EndFunc


func _adExists($spotifyWindowTitle, $tList)
	local $i = 0, _
			$tExists = False

	if ProcessExists("spotify.exe") then
		while (($i < UBound($tList)) And (not $tExists))
			if $spotifyWindowTitle = $titleList[$i] then $tExists = True
			$i += 1
		WEnd
	EndIf

	return $tExists
EndFunc


func _scriptPause()
	if $scriptIsRunning then
		$scriptIsRunning = False
		TrayTip("", $scriptName & " pausiert", 1)
	else
		$scriptIsRunning = True
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
   MsgBox("", "", WinGetTitle($spotifyWindowClass), 2)
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
