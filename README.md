# IniFile_udf - AutoIt3 UDF for expanded INI file operations

## Introduction

A set of user defined functions to ease the process of read and writing to INI files. The primary role of these functions is to reduce disk operations when handling large number of INI file actions. Expands on the internal INI related functions `IniRead()`,  `IniWrite()`, `IniReadSection()`, `IniWriteSection()`, etc.

Some of the functions:
* `_IniCheck()`         - Read ini file key value, and if key doesn't exits, it is created with a default value.
* `_IniReadSection()`  - Reads all key/value pairs in a section, and sets predefined variables with its values.  
* `_IniFileToArray()`   - Reads an ini file, and populates an array, allowing for smoother access to keys and values.
* `_IniWriteSectionAdd()` and `_IniWriteSectionFlush()`   - Add key-value pairs to a buffer, and flush buffer to disk when done.




### `_IniCheck()` example:
```AutoIt
#include "IniFile_udf.au3"

; Set variable values, while also creating ini file key-value pairs (if they don't exist already).
Global $Fscreen   = _IniCheck("C:\temp\settings.ini", "config", "fullsreen", "1")
Global $Xpos      = _IniCheck("C:\temp\settings.ini", "config", "xpos", "400")
Global $Ypos      = _IniCheck("C:\temp\settings.ini", "config", "ypos", "300")
Global $SavePath  = _IniCheck("C:\temp\settings.ini", "directories", "savepath", "C:\Users\username\Documents\")
Global $NetSnmp   = _IniCheck("C:\temp\settings.ini", "directories", "netsnmp", "C:\usr\bin\")

ConsoleWrite("SavePath = " & $SavePath & @CRLF)
ConsoleWrite("NetSnmp  = " & $NetSnmp & @CRLF)
```


### `_IniReadSection()` example:
```
#include "IniFile_udf.au3"

; These must be declared globally first.
Global $PositionX, $PositionY, $FullscreenMode   

; Read the specified keys, and assign their values to matched Global variables.
_IniReadSection("C:\temp\settings.ini", "config", "xpos|$PositionX,ypos|$PositionY,$FullscreenMode|fullsreen")

ConsoleWrite("XPOS = " & $PositionX & @CRLF)
ConsoleWrite("YPOS = " & $PositionY & @CRLF)
```

### `_IniCheckInArray()` example:
```
#include "IniFile_udf.au3"

; Read the ini file into an array
Global $aIniFile 	= _IniFileToArray("C:\temp\settings.ini")

; Set variable values, while also creating ini file key-value pairs (if they don't exist already).
Global $Fscreen     = _IniCheckInArray($aIniFile, "config", "fullsreen", "1")
Global $Xpos        = _IniCheckInArray($aIniFile, "config", "xpos", "400")
Global $Ypos        = _IniCheckInArray($aIniFile, "config", "ypos", "300")
Global $SavePath    = _IniCheckInArray($aIniFile, "directories", "savepath", "C:\Users\username\Documents\")
Global $NetSnmp     = _IniCheckInArray($aIniFile, "directories", "netsnmp", "C:\usr\bin\")

ConsoleWrite("SavePath = " & $SavePath & @CRLF)
ConsoleWrite("NetSnmp  = " & $NetSnmp & @CRLF)
_ArrayDisplay($aIniFile)
```

### `_IniReadSectionNamesFromArray()` example:
```
#include "IniFile_udf.au3"

; Read the ini file into an array
Global $aIniFile = _IniFileToArray("C:\temp\settings.ini")

; Gather all the section names
Global $aSectionsNames = _IniReadSectionNamesFromArray($aIniFile)

ConsoleWrite("Number of sections: " & @extended & @CRLF)
_ArrayDisplay($aSectionsNames)
```


### `_IniWriteSectionAdd()` example:
```
#include "IniFile_udf.au3"

; Create and populate the two sections' buffers...
_IniWriteSectionAdd("config", "fullsreen", "1")
_IniWriteSectionAdd("config", "xpos", "400")
_IniWriteSectionAdd("config", "ypos", "300")
_IniWriteSectionAdd("directories", "savepath", "C:\Users\username\Documents\")
_IniWriteSectionAdd("directories", "netsnmp", "C:\usr\bin\")

; ... and now we flush the two buffers to disk. Note that this overwrites an existing section if it exists.
_IniWriteSectionFlush("C:\temp\settings.ini", "config")
_IniWriteSectionFlush("C:\temp\settings.ini", "directories")
```
