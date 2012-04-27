//
// Copyright (c) 2012, Brian Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   25 Apr 12  Brian Frank  Creation
//

using gfx
using fwt
using syntax
using bocce

**
** EditorView
**
class EditorView : View
{
  new make(App app, FileRes res) : super(app, res)
  {
    this.file = res.file
    this.fileTimeAtLoad = file.modified

    // read document into memory, if we fail with the
    // configured charset, then fallback to ISO 8859-1
    // which will always "work" since it is byte based
    lines := readAllLines
    if (lines == null)
    {
      this.charset = Charset.fromStr("ISO-8859-1")
      lines = readAllLines
    }

    // get rules for ext or first line
    rules := SyntaxRules.loadForFile(file, lines.first)

    // construct and load editor
    editor = Editor { it.rules = rules }
    editor.onKeyDown.add |e| { if (!e.consumed) app.controller.onKeyDown(e) }
    editor.loadLines(lines)

    // hidden hooks
    editor->paintLeftDiv  = true
    editor->paintRightDiv = true
    editor->paintShowCols = true

    this.content = editor
  }

  private Str[]? readAllLines()
  {
    in := file.in { it.charset = this.charset }
    try
      return in.readAllLines
    catch
      return null
    finally
      in.close
  }

  Editor editor

  override Void onReady() { editor.focus }

  override Void onGoto(Mark mark)
  {
    editor.goto(mark.pos)
  }

  override Void onMarks(Mark[] marks)
  {
    editor.repaint
  }

  const File file
  const DateTime fileTimeAtLoad
  const Charset charset := Charset.utf8

}

