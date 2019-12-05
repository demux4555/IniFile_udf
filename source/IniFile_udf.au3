#include-once
#include <Array.au3>
#include <File.au3>
#include <String.au3>


; #DESCRIPTION# =================================================================================================================
; Title .........: IniFile_udf v1.5.1
; Description ...: AutoIt3 UDF for expanded INI file operations. Eases the process of reading and writing to INI files.
; Author(s) .....: demux4555
; Changelog .....:
;	v1.5		2019.12.03	Proper code cleanup. Removed _IniWriteSectionClear()
;	v1.5.1		2019.12.05	_IniReadSectionNamesFromArray() redone
; ===============================================================================================================================


#Region ### GLOBAL VARIABLES ###


	; _IniCheck() $_IniKeyCreate options
	Global Const $INIFILE_NOCREATEKEY 	= 0
	Global Const $INIFILE_CREATEKEY 	= 1

	; The could/should be set already in the main script. Personally I use these two Global vars throughout all my scripts.
	If Not IsDeclared("_D")  Then Global $_D  = False		; $_D  for console debugging
	If Not IsDeclared("_DD") Then Global $_DD = False		; $_DD for extra verbose console debugging


#EndRegion ### GLOBAL VARIABLES ###


#Region ### INI FILE FUNCTIONS ###

	; Functions to ease ini file operations. Allows writing default key-value pairs if missing, and read sections and assign values
	; to varaibles.

	; #FUNCTION# ====================================================================================================================
	; Name ..........: _IniCheck
	; Description ...: Check ini file to see if a key exists. If it exists it returns the current found key value. If it doesnt
	;                  exist, it saves it to the ini file using the default value provided.
	;                  Operates in same manner as IniRead().
	;                  Will create the file if missing. Will also create the section if missing.
	; Syntax ........: _IniCheck($_iniFile, $_iniSection, $_iniKey, $_iniDefault[, $_IniKeyCreate = 1])
	; Parameters ....: $_iniFile            - The filename of the .ini file.
	;                  $_iniSection         - The section name in the .ini file.
	;                  $_iniKey             - The key name in the .ini file.
	;                  $_iniDefault         - [optional] The default value to return/write if the requested key is not found.
	;                  $_IniKeyCreate       - [optional] Create key if missing, with $_iniDefault value.
	;                                         Default is $INIFILE_CREATEKEY (1).
	; Return values .: Success: The requested key value as a string.
	;                  Failure: The provided default string if requested key not found.
	; Author ........: demux4555
	; ===============================================================================================================================
	Func _IniCheck($_iniFile, $_iniSection, $_iniKey, $_iniDefault = "", $_IniKeyCreate = $INIFILE_CREATEKEY)
		Local $_iniValue = IniRead($_iniFile, $_iniSection, $_iniKey, "")		; look in the ini file and see what we have
		If StringIsSpace($_iniValue) Then
			If ($_IniKeyCreate==$INIFILE_CREATEKEY) Then						; if the ini file doesn't have the specified key...
				If $_D Then ConsoleWrite('INFO: _IniCheck() "' & $_iniFile & '" missing key/value ' & $_iniKey & ' [default value written to ini].' & @CRLF)	; if $_D is True, we show a debug message in console
				_IniWrite($_iniFile, $_iniSection, $_iniKey, $_iniDefault)		; ... we write the key to the ini file
			EndIf
			$_iniValue = $_iniDefault											; ... and apply the default value
		EndIf
		Return $_iniValue
	EndFunc


	; #FUNCTION# ====================================================================================================================
	; Name ..........: _IniWrite
	; Description ...: Provides verbose errohandling for IniWrite().
	;                  Identical operation as IniWrite().
	; Syntax ........: _IniWrite($_iniFile, $_iniSection, $_iniKey, $_iniValue)
	; Parameters ....: $_iniFile            - The filename of the .ini file.
	;                  $_iniSection         - The section name in the .ini file.
	;                  $_iniKey             - The key name in the .ini file.
	;                  $_iniValue           - The value to write/change
	; Return values .: Success: 1
	;                  Failure: 0, @error set to non-zero
	; Author ........: demux4555
	; ===============================================================================================================================
	Func _IniWrite($_iniFile, $_iniSection, $_iniKey, $_iniValue)
		Local $_ret = IniWrite($_iniFile, $_iniSection, $_iniKey, $_iniValue)
		If Not ($_ret==1) Then ConsoleWriteError('ERROR: _IniWrite() could not write to ini file (write protected or locked by another program): "' & $_iniFile & '".' & @CRLF)
		Return SetError((($_ret==1)?(0):(1)), 0, $_ret)
	EndFunc


	; #FUNCTION# ====================================================================================================================
	; Name ..........: _IniReadSection
	; Description ...: Reads an ini section, and assigns key values to specified variables.
	;                  Note: does not return an array like IniReadSection() does.
	; Syntax ........: _IniReadSection($_iniFile, $_iniSection, $_csvStr)
	; Parameters ....: $_iniFile            - The filename of the .ini file.
	;                  $_iniSection         - The section name in the .ini file.
	;                  $_csvStr             - Comma-separated string containing Key names and variable names. See below.
	;                                         Example:  "keyName1|$varName1,keyName2|$varName2"
	; Return values .: Success: number of variables set, and @extended is set to number of keys in the ini file.
	;                  Failure: 0, and sets @error to non-zero
	; Author ........: demux4555
	; Important .....: Will NOT create specified variables if not already declared as Global in main script.
	; Example .......:
	;        Global $_Syslog_Target, $_Syslog_Facility, $_Syslog_Severity, $_Syslog_Tag, $_Syslog_Port
	;        _IniReadSection("C:\SyslogSend.ini", "SyslogSend", "target|$_Syslog_Target,facility|$_Syslog_Facility,severity|$_Syslog_Severity,tag|$_Syslog_Tag,port|$_Syslog_Port")
	; ===============================================================================================================================
	Func _IniReadSection($_iniFile, $_iniSection, $_csvStr)

		If (StringInStr($_csvStr, "|",0,1,1,1) <> 0) Then Return SetError(1, 0 ,0)		; quick check to see if we find at least one "keyName1|$varName1"
		Local $_aCommaList = StringSplit($_csvStr, ",")									; split at comma, and end up with an array containing: "keyName1|$varName1"  and  "keyName2|$varName2"  etc...
		If Not IsArray($_aCommaList) Then Return SetError(2, 0 ,0)

		Local $_aIniSection = IniReadSection($_iniFile, $_iniSection)					; read the entire [section] from the ini
		If (@error==0) And IsArray($_aIniSection) Then
			Local $_cnt = 0																; keys counter
			Local $_num = $_aIniSection[0][0]											; [0][0] = Number of keys
			Local $_IniKey, $_IniValue, $_aKeyVars, $_Keyname, $_Varname
			For $E = 1 To $_num															; enumerates the [section] array.

				$_IniKey	= $_aIniSection[$E][0]	; grab the ini Key
				$_IniValue	= $_aIniSection[$E][1]	; grab the ini Value

				For $S = 1 To $_aCommaList[0]											; enumerate the comma separated list, with each element containing "keyName1|$varName1"

					$_aKeyVars = StringSplit($_aCommaList[$S], "|")						; this splits each "keyName1|$varName1" element into keyname and variablename (these two will be matched together)
					If (Not IsArray($_aKeyVars)) Or ($_aKeyVars[0] <> 2) Then Return SetError(3, 0 ,0)	; we ensure we get a valid pair of "keyName1|$varName1"

					$_Keyname = $_aKeyVars[1]											; this is the key name ...
					$_Varname = StringReplace($_aKeyVars[2], "$", "", 1)				; ... and this is the variable name (we strip the $ character from the var name)

					If ($_IniKey == $_Keyname) Then										; does the comma separated key name match any of the key names in the ini? NOTE: case-sensitive
						$_cnt += 1														; we count the number of keys we actually processed
						$_res = Assign($_Varname, $_IniValue, 2+4) ; $ASSIGN_FORCEGLOBAL+$ASSIGN_EXISTFAIL ... NOTE: will only assign variables if Global $variablename has been declared
						If Not ($_res==1) Then ConsoleWriteError("ERROR: _IniReadSection() falied. Global variable does not exist: $" & $_Varname & @CRLF)
					EndIf

				Next
			Next
			Return SetError(0, $_num, $_cnt)	; Success. This returns the number of "hits" we found (the actual number of keys processed), and sets @extended to the number of keys in the ini file
		Endif

		Return SetError(-1, 0, 0)				; Failure. we end up here if we couldnt read ini file, or we didn't find [section]

	EndFunc


#EndRegion ### INI FILE FUNCTIONS ###


#Region ### INI ARRAY FUNCTIONS ###

	; Internal use. _IniReadFromArray() error codes
	Global Const $INIFILE_KEYNOTFOUND 		= -10
	Global Const $INIFILE_SECTIONNOTFOUND 	= -20
	Global Const $INIFILE_NOSECTIONS 		= -30

	; Functions to reduce disk operations when reading ini file. The file is read as an array, and values and section names can be
	; retrieved from it.

	; #FUNCTION# ====================================================================================================================
	; Name ..........: _IniFileToArray
	; Description ...: Reads all sections and key/value pairs from a standard format .ini file, and returns contents as an array
	;                  that can be easily accessed using _IniReadFromArray()
	; Syntax ........: _IniFileToArray($_iniFile)
	; Parameters ....: $_iniFile            - The filename of the .ini file.
	; Return values .: Success: A 2 dimensional array where Col0 is section name, Col1 is key name, and Col2 is key value.
	;                           Row0 contains: [0][0] total number of sections, [0][1] total number of keys, [0][2] ini filename.
	;                  Failure: Array with only 1 row (containing zero'ed counters, and filename), @error is set to non-zero.
	;                           @error values: see _FileReadToArray() as reference.
	; Author ........: demux4555
	; Related .......: _IniReadFromArray()
	; Note ..........: Tip: use _ArrayDisplay() to explore contents of returned array if explanation above is unclear.
	; Requires ......: Array.au3, File.au3, String.au3
	; ===============================================================================================================================
	Func _IniFileToArray($_iniFile)
		Local $_hIniRead = TimerInit()	; somtimes it takes a while to read the file, so we have a timer for debug output
		Local $_aFile, $_lineCnt = -1, $_secCnt = 0, $_pairCnt = 0, $_aSplit, $_aBtwn, $_sSection, $_sKey, $_sValue
		Local $_aIniFile[0][3]
		_ArrayAdd($_aIniFile, "0|0|" & $_iniFile)	; note: if file doesn't exist, we still have filled the top row with the zero counters and ini filename i.e.  [0] [0] [net-snmp_SysInfo_192.168.1.1_channels.ini]
		_FileReadToArray($_iniFile, $_aFile)
		Local $_error = @error

		If ( ($_error==0) And (Not ($_aFile==0)) And (IsArray($_aFile)==1) ) Then				; ensure we got a proper fileread
			$_lineCnt = $_aFile[0]																; number of lines in the file
			If ($_lineCnt<=0) Then Return SetError(-1, 0, $_aIniFile)							; no lines read?

			For $_sLine In $_aFile																; enumerate the lines in the files
				If StringIsSpace($_sLine) Or (StringLeft($_sLine, 1)==";") Then ContinueLoop 	; skip empty lines and and comments

				If (StringLeft($_sLine, 1)=="[") And (StringRight($_sLine, 1)=="]") Then		; got a [section] ?

					$_aBtwn = _StringBetween($_sLine, "[", "]")
					If (@error==0) Then								; did we find a section name with "[" and "]" ?
						$_sSection = $_aBtwn[0]						; store section name i.e. "config"
						$_secCnt += 1
					EndIf

				Else
					$_aSplit = StringSplit($_sLine, "=")								; did we find "=" ?
					If (@error==0) Then
						$_sKey = $_aSplit[1]											; store key string
						If StringIsSpace($_sKey) Then ContinueLoop
						$_sValue = $_aSplit[2]											; .. and store value string (even if its blank)
					EndIf
					If Not (StringIsSpace($_sSection) Or StringIsSpace($_sKey))  Then	; if both SECTION and KEY are defined, we add it to the array
						_ArrayAdd($_aIniFile, $_sSection&"|"&$_sKey&"|"&$_sValue)
						$_sKey 		= ""	; clear for next run
						$_sValue 	= ""
						$_pairCnt += 1
					EndIf
				EndIf
			Next

			; update header row in array
			$_aIniFile[0][0] = $_secCnt		; num of sections found in ini file
			$_aIniFile[0][1] = $_pairCnt	; num of keys found in ini file
			$_aIniFile[0][2] = $_iniFile	; the ini filename

			; debug showing relevant info on processed ini file
			If $_D Then ConsoleWrite(">> _IniFileToArray():   @error:" & $_error & " lines:" & $_lineCnt & " sections:" & $_secCnt & " pairs:" & $_pairCnt & " " & @TAB & "[" & $_iniFile & "]  (" & Round(TimerDiff($_hIniRead),2) & "ms)" & @CRLF)

		Else

			; debug showing relevant info on failed processing of ini file
			If $_D Then ConsoleWrite(">> _IniFileToArray():   @error:" & $_error & " (file missing?) " & @TAB & "[" & $_iniFile & "]  (" & Round(TimerDiff($_hIniRead),2) & "ms)" & @CRLF)

		EndIf

		Return SetError($_error, $_secCnt, $_aIniFile)	; @extended is set to number of sections read

	EndFunc


	; #FUNCTION# ====================================================================================================================
	; Name ..........: _IniReadFromArray
	; Description ...: Reads a key value from an array created by _IniFileToArray().
	;                  Operates in same manner as IniRead(), except instead of a filename, it requires an _IniFileToArray() array.
	; Syntax ........: _IniReadFromArray(Byref $_aIniFile, $_iniSection, $_iniKey[, $_sDefault = ""])
	; Parameters ....: $_aIniFile      - [in/out] an array created by _IniReadFromArray().
	;                  $_iniSection    - The section name in the .ini file.
	;                  $_iniKey        - The key name in the .ini file.
	;                  $_sDefault      - [optional] The default value to return if the requested key is not found.
	; Return values .: Success: the requested key value as a string.
	;                  Failure: the default string if requested key not found. @error is set to non-zero.
	;                           @extended is set to $INIFILE_KEYNOTFOUND (-10) if there was no hit on key name.
	; Author ........: demux4555
	; Related .......: _IniFileToArray()
	; Example .......:
	;		$aIniFile = _IniFileToArray("C:\configuration.ini")
	;		$sMode    = _IniReadFromArray($aIniFile, "config", "Mode", "-1")
	; ===============================================================================================================================
	Func _IniReadFromArray(ByRef $_aIniFile, $_iniSection, $_iniKey, $_iniDefault = "")
		If Not IsArray($_aIniFile) Then Return SetError(2, 0, "")
		If (UBound($_aIniFile, 1)<=1) Or (UBound($_aIniFile, 2)<>3) Then Return SetError(3, $INIFILE_NOSECTIONS, "")	; there must be 3 columns, and there must be at least one row (besides the top header row)
		Local $_SECFOUND = False
		For $R = 1 To UBound($_aIniFile, 1)-1	; enumerate rows
			If ($_aIniFile[$R][0] = $_iniSection) Then 												; Note: NOT case-sensitive		[r][0] = section
				If ($_aIniFile[$R][1] = $_iniKey) Then Return SetError(0, $R, $_aIniFile[$R][2])	; found the correct key?		[r][1] = key		[r][2] = value
				$_SECFOUND = True																	; ... if not, we mark that we found the correct section name
			ElseIf $_SECFOUND Then				; if we found correct section, but passed on to a new section name, we exit the loop
				ExitLoop
			EndIf
		Next
		If Not $_SECFOUND Then Return SetError(1, $INIFILE_SECTIONNOTFOUND, $_iniDefault)
		Return SetError(1, $INIFILE_KEYNOTFOUND, $_iniDefault)	; if we made it here, there was no hit on KEY name, and we simply return the Default string
	EndFunc


	; #FUNCTION# ====================================================================================================================
	; Name ..........: _IniCheckInArray
	; Description ...: Check array created by _IniFileToArray() to see if a key exists. If it exists it returns the current found
	;                  key value. If it doesnt exist, it saves it to the ini file using the default value provided.
	;                  Operates in same manner as _IniCheck().
	; Syntax ........: _IniCheckInArray(Byref $_aIniFile, $_iniSection, $_iniKey[, $_iniDefault = ""[, $_IniKeyCreate = 1]])
	; Parameters ....: $_aIniFile       - [in/out] an array created by _IniReadFromArray().
	;                  $_iniSection     - The section name in the .ini file.
	;                  $_iniKey         - The key name in the .ini file.
	;                  $_iniDefault     - [optional] The default value to return/write if the requested key is not found.
	;                  $_IniKeyCreate   - [optional] Create key if missing, with $_iniDefault value.
	;                                     Default is $INIFILE_CREATEKEY (1).
	; Return values .: Success: The requested key value as a string.
	;                  Failure: The provided default string if requested key not found, @error is set to non-zero.
	; Author ........: demux4555
	; Related .......: _IniFileToArray()
	; ===============================================================================================================================
	Func _IniCheckInArray(ByRef $_aIniFile, $_iniSection, $_iniKey, $_iniDefault = "", $_IniKeyCreate = $INIFILE_CREATEKEY)
		Local $_iniValue = _IniReadFromArray($_aIniFile, $_iniSection, $_iniKey, "")
		Local $_extended = @extended

		Local Const $_ArS_START = 0, $_ArS_END = 0, $_ArS_NOCASE = 0, $_ArS_CASE = 1, $_ArS_COMP_SAME = 0, $_ArS_COMP_PARTIAL = 1, $_ArS_REV = 0, $_ArS_FWD = 1

		Local $_NOTFOUND = False
		Switch $_extended
			Case $INIFILE_KEYNOTFOUND
				$_NOTFOUND = True
			Case $INIFILE_NOSECTIONS
				$_NOTFOUND = True
			Case $INIFILE_SECTIONNOTFOUND
				$_NOTFOUND = True
		EndSwitch

		Local $_iniFile = $_aIniFile[0][2]												; grab the full ini filename
		If StringIsSpace($_iniFile) Then Return SetError(1, 0, $_iniDefault)
		If $_NOTFOUND Then																; this way we avoid re-writing keys to the ini file whenever their value is ""
			If ($_IniKeyCreate == $INIFILE_CREATEKEY) Then
				If $_D Then ConsoleWrite('INFO: _IniCheckInArray() "' & $_iniFile & '" missing key/value ' & $_iniKey & ' [default value written to ini].' & @CRLF)	; if $_D is True, we show a debug message in console
				_IniWrite($_iniFile, $_iniSection, $_iniKey, $_iniDefault)
				_ArrayAdd($_aIniFile, $_iniSection & "|" & $_iniKey & "|" & $_iniDefault)
				$_aIniFile[0][1] += 1						; increase the key counter at [0][1]
			EndIf
			$_iniValue = $_iniDefault
		EndIf
		$_aIniFile[0][0] = _ArrayUnique($_aIniFile, 0, 1)[0]	; count unique section namesa dn update counte at [0][0]

		Return $_iniValue
	EndFunc


	; #FUNCTION# ====================================================================================================================
	; Name ..........: _IniReadSectionNamesFromArray
	; Description ...: Reads all sections in an array created by _IniFileToArray().
	;                  Operates in same manner as IniReadSectionNames()
	; Syntax ........: _IniReadSectionNamesFromArray(Byref $_aIniFile)
	; Parameters ....: $_aIniFile           - [in/out] an array created by _IniReadFromArray().
	; Return values .: Success: an array of all section names in the INI file. @extended is set to number sections.
	;                  Failure: sets @error to non-zero.
	; Author ........: demux4555
	; Remarks .......: The number of elements returned will be in $_aReturn[0]. If an @error occurs, no array is returned.
	; Related .......: _IniReadFromArray()
	; Requires ......: Array.au3
	; ===============================================================================================================================
	Func _IniReadSectionNamesFromArray(ByRef $_aIniFile)
		If Not IsArray($_aIniFile) Then Return SetError(1, 0, "")
		If (UBound($_aIniFile, 1)<=1) Or (UBound($_aIniFile, 2)<>3) Then Return SetError(2, 0, "")	; there must be 3 columns, and there must be at least one row (besides the top header row)
		Local $_aReturn = _ArrayUnique($_aIniFile, 0, 1)
		Local $_secCnt = $_aReturn[0]
		$_aIniFile[0][0] = $_secCnt	; update the section counter in the ByRef array (just in case)

		Return SetError(0, $_secCnt, $_aReturn)
	EndFunc


#EndRegion ### INI ARRAY FUNCTIONS ###


#Region ### INI SECTION FUNCTIONS ###

	; Functions to ease writing entire sections to ini files, while reducing disk operations.
	; Use _IniWriteSectionAdd() to add key-value pairs to specified section, and then use _IniWriteSectionFlush() to write/flush buffer to ini file.

	Global Const $__IniFile_udf_sectionNamePrefix = "___IWSA_sectionName_" ; For internal use. A long string to avoid variable name conflicts for the buffer variables.

	; #FUNCTION# ====================================================================================================================
	; Name ..........: _IniWriteSectionAdd
	; Description ...: Adds ini file key-value pairs to a buffer in preparation for _IniWriteSectionFlush().
	;                  Allows use of multiple sections simultaneously, as long as they have unique names.
	;                  Use _IniWriteSectionFlush() when fnished to write/flush to disk.
	;                  Note: will overwrite an existing section completely.
	; Syntax ........: _IniWriteSectionAdd($_iniSection, $_iniKey[, $_iniValue = ""])
	; Parameters ....: $_iniSection         - The section name in the .ini file.
	;                  $_iniKey             - The key name in the .ini file.
	;                  $_iniValue           - [optional] The value to write.
	; Return values .: None
	; Author ........: demux4555
	; Related .......: _IniWriteSectionFlush()
	; Example .......:
	;		_IniWriteSectionAdd("data", "Thermo", "24.1")
	;		_IniWriteSectionAdd("data", "Hygro", "67")
	;		_IniWriteSectionFlush("C:\storage.ini", "data")
	; ===============================================================================================================================
	Func _IniWriteSectionAdd($_iniSection, $_iniKey, $_iniValue = "")
		If StringIsSpace($_iniSection) Or StringIsSpace($_iniKey) Then Return SetError(1, 0, 0)		; quick check to ensure we have section name and a key
		Local $_varName = $__IniFile_udf_sectionNamePrefix & $_iniSection							; this is the name of the buffer variable
		Local $_sBuffer = Eval($_varName)															; grab the existing value of the buffer
		$_sBuffer &= $_iniKey & "=" & $_iniValue & @LF												; ... and add the key=value to the buffer (@LF is delimiter)
		Assign($_varName, $_sBuffer, 2) ; $ASSIGN_FORCEGLOBAL										; finally we store the buffer as a global var
	EndFunc


	; #FUNCTION# ====================================================================================================================
	; Name ..........: _IniWriteSectionFlush
	; Description ...: Writes ini file buffer created by _IniWriteSectionAdd() to disk, and then clears the buffer.
	; Syntax ........: _IniWriteSectionFlush($_inifile, $_iniSection)
	; Parameters ....: $_inifile            - The filename of the .ini file.
	;                  $_iniSection         - The section name in the .ini file.
	; Return values .: Success: 1
	;                  Failure: 0, and sets @error to non-zero
	; Author ........: demux4555
	; Remarks .......: Clears the buffer variable when done.
	; Requires.......: _IniWriteSectionAdd() must be used to create the buffer first
	; ===============================================================================================================================
	Func _IniWriteSectionFlush($_inifile, $_iniSection)
		If StringIsSpace($_iniSection) Then Return SetError(1, 0, 0)						; quick check to ensure we have section name
		Local $_varName = $__IniFile_udf_sectionNamePrefix & $_iniSection					; this is the name of the buffer variable
		Local $_sBuffer = Eval($_varName)													; grab the existing value of the buffer
		If Not (@error==0) Then Return SetError(2, 0, 0)									; if the buffer variable doesn't exist we quit
		If (StringInStr($_sBuffer, "=", 0, 1) <= 1) Then Return SetError(3, 0, 0)			; make sure we at least have one key in the buffer
		IniWriteSection($_inifile, $_iniSection, $_sBuffer)									; write the buffer variable to the ini file
		If Not (@error==0) Then Return SetError(4, 0, 0)
		Assign($_varName, Null, 2)	; $ASSIGN_FORCEGLOBAL 									; ... we clear/flush the global variable
		Return SetError(0, 0, 1)
	EndFunc


#EndRegion ### INI SECTION FUNCTIONS ###


#Region ### BOOL/INT/STRING CONVERSIONS FOR INI VALUES ###

	; A bunch of small Funcs to make reading/writing ini values "0" and "1" a bit easier.
	; Also allows using strings such as "ENABLED" / "DISABLED" to set Bool values True / False.

	; #FUNCTION# ====================================================================================================================
	; Name ..........: Bool2Int
	; Description ...: Converts Bool to INT. Returns INT 1 on True, and 0 if not
	; Syntax ........: Bool2Int($_bVal)
	; Parameters ....: $_bVal               - Bool: True or False.
	; Return values .: Integer 0 or 1
	; Author ........: demux4555
	; ===============================================================================================================================
	Func Bool2Int($_bVal)
		If IsBool($_bVal) And ($_bVal==True) Then Return 1
		If (Number($_bVal)==1)				 Then Return 1	; safeguard
		Return 0			; Note: defaults to 0 on all other values
	EndFunc


	; #FUNCTION# ====================================================================================================================
	; Name ..........: Int2Bool
	; Description ...: Converts INT 0..1 to Bool. Returns Bool True on 1, and False if not
	; Syntax ........: Int2Bool($_iVal)
	; Parameters ....: $_iVal               - String or INT: 0 or 1.
	; Return values .: True if $_iVal = 1. If not False.
	; Author ........: demux4555
	; ===============================================================================================================================
	Func Int2Bool($_iVal)
		If IsBool($_iVal)		Then Return $_iVal
		If (Number($_iVal)==1) 	Then Return True 	; safeguard
		Return False		; Note: defaults to False on all other values
	EndFunc


	; #FUNCTION# ====================================================================================================================
	; Name ..........: Str2Bool
	; Description ...: Converts positive/negative string to Bool.
	; Syntax ........: Str2Bool($_sVal)
	; Parameters ....: $_sVal               - String: Not case-sensitive.
	; Return values .: True:  1 | TRUE | YES | ON |  ENABLE
	;                  False: 0 | FALSE |  NO | OFF | DISABLE
	; Author ........: demux4555
	; ===============================================================================================================================
	Func Str2Bool($_sVal)
		$_sVal = StringStripWS(String($_sVal), 8)	; $STR_STRIPALL ... we need to convert to string to avoid problems with blank values "" and string comparisons.
		$_sVal = StringUpper($_sVal)
		If ($_sVal=="1") Or ($_sVal=="TRUE")  Or ($_sVal=="YES") Or ($_sVal=="ON")  Or (StringLeft($_sVal, 6) == "ENABLE")  Then Return True
		If ($_sVal=="0") Or ($_sVal=="FALSE") Or ($_sVal=="NO")  Or ($_sVal=="OFF") Or (StringLeft($_sVal, 7) == "DISABLE") Then Return False
		Return SetError (1, 0, False) ; Note: defaults to False on all other values, and sets @error=1
	EndFunc


	; #FUNCTION# ====================================================================================================================
	; Name ..........: Str2Int
	; Description ...: Converts positive/negative strings to INT -1..1
	; Syntax ........: Str2Int($_sVal)
	; Parameters ....: $_sVal               - String: Not case-sensitive.
	; Return values .: 1:  TRUE | YES | NO | ENABLE
	;                  0:  FALSE | NO | OFF | DISABLE
	;                  -1: "" | AUTO
	;                  -1: on anything else, and sets @error to 1
	; Author ........: demux4555
	; ===============================================================================================================================
	Func Str2Int($_sVal)
		$_sVal = StringStripWS(String($_sVal), 8)	; $STR_STRIPALL  ... we need to convert to string to avoid problems with blank values "" and string comparisons.
		$_sVal = StringUpper($_sVal)
		If ($_sVal=="1") Or ($_sVal=="TRUE")  Or ($_sVal=="YES") Or ($_sVal=="ON")  Or (StringLeft($_sVal, 6) == "ENABLE")  Then Return 1
		If ($_sVal=="0") Or ($_sVal=="FALSE") Or ($_sVal=="NO")  Or ($_sVal=="OFF") Or (StringLeft($_sVal, 7) == "DISABLE") Then Return 0
		If ($_sVal=="")  Or ($_sVal=="-1")    Or (StringLeft($_sVal, 4) == "AUTO") 											Then Return -1
		Return SetError (1, 0, -1) ; Note: defaults to automatic -1 on all other values, and sets @error=1
	EndFunc


#EndRegion ### BOOL/INT/STRING CONVERSIONS FOR INI VALUES ###
