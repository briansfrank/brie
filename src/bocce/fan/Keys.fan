//
// Copyright (c) 2014, Brian Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   23 Jul 14  Brian Frank  Creation
//

using gfx
using fwt
using syntax
using concurrent

**
** Key bindings
**
@NoDoc
class Keys
{
  const static Bool mac := Env.cur.os == "macosx"

  const static Str up            := "Up"
  const static Str down          := "Down"
  const static Str left          := "Left"
  const static Str right         := "Right"
  const static Str prevWord      := mac ? "Alt+Left"      : "Ctrl+Left"
  const static Str nextWord      := mac ? "Alt+Right"     : "Ctrl+Right"
  const static Str lineStart     := mac ? "Command+Left"  : "Home"
  const static Str lineEnd       := mac ? "Command+Right" : "End"
  const static Str docStart      := mac ? "Command+Up"    : "Ctrl+Home"
  const static Str docEnd        := mac ? "Command+Down"  : "Ctrl+End"
  const static Str pageUp        := "PageUp"
  const static Str pageDown      := "PageDown"

  const static Str enter         := "Enter"
  const static Str indent        := "Tab"
  const static Str unindent      := "Shift+Tab"
  const static Str backspace     := "Backspace"
  const static Str backspaceWord := mac ? "Alt+Backspace" : "Ctrl+Backspace"
  const static Str backspaceLine := mac ? "Command+Backspace" : "Shift+Ctrl+Backspace"
  const static Str del           := "Del"
  const static Str delWord       := mac ? "Alt+Del"     : "Ctrl+Del"
  const static Str delLine       := mac ? "Command+Del" : "Shift+Ctrl+Del"

  const static Str copy          := mac ? "Command+C" : "Ctrl+C"
  const static Str cut           := mac ? "Command+X" : "Ctrl+X"
  const static Str paste         := mac ? "Command+V" : "Ctrl+V"
  const static Str dupLine       := mac ? "Command+D" : "Ctrl+D"
  const static Str cutLine       := mac ? "Command+Y" : "Ctrl+Y"
  const static Str undo          := mac ? "Command+Z" : "Ctrl+Z"
  const static Str redo          := mac ? "Shift+Command+Z" : "Shift+Ctrl+Z"

  const static Str toggleComment := mac ? "Command+Slash" : "Ctrl+Slash"
  const static Str insertSection := mac ? "Command+=" : "Ctrl+="
  const static Str save          := mac ? "Command+S" : "Ctrl+S"
  const static Str reload        := mac ? "Command+R" : "Ctrl+R"
  const static Str find          := mac ? "Command+F" : "Ctrl+F"
  const static Str findInSpace   := mac ? "Shift+Command+F" : "Shift+Command+F"
  const static Str prevMark      := mac ? "Command+[" : "Shift+F8"
  const static Str nextMark      := mac ? "Command+]" : "F8"
  const static Str goto          := mac ? "Command+G" : "Ctrl+G"
  const static Str showDocs      := mac ? "Command+P" : "Ctrl+P"
  const static Str closeConsole  := "Esc"
  const static Str recent        := "Ctrl+Space"
  const static Str build         := mac ? "Command+B" : "F9"

}

