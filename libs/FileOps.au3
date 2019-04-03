#cs	--------------------------------------------------------------------------
#		File operation functions
#		currently included:
#		-	read the version file
#		-	import the blacklist
#		-	add a new spot title to the blacklist
#ce	--------------------------------------------------------------------------

#include <File.au3>

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
		MsgBox("", "Spotify AdMuter", "Keine Versionsinformation gefunden!" & @CRLF & "Version automatisch auf 1.0 festgelegt." & _
			@CRLF & "Zum Wechseln auf Version 0.9 bitte Alt-U drücken." & @CRLF & "Die Auswahl wird für den nächsten Start gespeichert.")
	EndIf

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
