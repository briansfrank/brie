//
// Copyright (c) 2012, Brian Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   25 Aug 12  Brian Frank  Creation
//

using gfx
using fwt
using bocce

class Commands
{
  new make(App app)
  {
    this.app = app
    this.list = [
      c("f",    "Find in current doc", FindCmd#),
      c("fi",   "Find case insensitive in current doc", FindInsensitiveCmd#),
    ]
  }

  private Cmd c(Str name, Str summary, Type t)
  {
    Cmd cmd := t.make
    cmd.name    = name
    cmd.summary = summary
    cmd.toStr   = name.padr(4) + "  " + summary
    cmd.app     = app
    return cmd
  }

  App app
  Cmd[] list
}

//////////////////////////////////////////////////////////////////////////
// Cmd base class
//////////////////////////////////////////////////////////////////////////

abstract class Cmd
{
  App? app
  Str name    := "?"
  Str summary := "?"
  override Str toStr := "?"

  Editor? editor()
  {
    if (app.view isnot EditorView) return null
    return ((EditorView)app.view).editor
  }

  virtual Obj[] match(Str arg) { Obj#.emptyList }
}

//////////////////////////////////////////////////////////////////////////
// FindCmd
//////////////////////////////////////////////////////////////////////////

class FindCmd : Cmd
{
  virtual Bool matchCase() { true }
  override Obj[] match(Str arg)
  {
    res := app.res
    editor := this.editor
    marks := Mark[,]
    spans := Span[,]
    if (arg.size < 2 || editor == null) return marks
    while (marks.size < 1000)
    {
      lastMark := marks.last
      pos := editor.findNext(arg, lastMark?.pos, matchCase)
      if (pos == null) break
      line := editor.line(pos.line).trim
      spans.add(Span(pos, Pos(pos.line, pos.col+arg.size)))
      marks.add(Mark(res, pos.line, pos.col, pos.col+arg.size, line))
    }
    editor.highlights = spans
    return marks
  }
}

class FindInsensitiveCmd : FindCmd
{
  override Bool matchCase() { false }
}


