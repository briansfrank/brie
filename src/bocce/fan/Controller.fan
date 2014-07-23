//
// Copyright (c) 2012, Brian Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   22 Apr 12  Brian Frank  Creation
//

using gfx
using fwt
using syntax
using concurrent

**
** Controller
**
@NoDoc
class Controller
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  new make(Editor editor)
  {
    this.editor = editor
    this.changeStack = ChangeStack()
    editor.onFocus.add |e|      { onFocus(e)      }
    editor.onBlur.add |e|       { onBlur(e)       }

    editor.onKeyDown.add |e|    { onKeyDown(e)    }
    editor.onKeyUp.add |e|      { onKeyUp(e)      }

    editor.onMouseDown.add |e|  { onMouseDown(e)  }
    editor.onMouseUp.add |e|    { onMouseUp(e)    }
    editor.onMouseMove.add |e|  { onMouseMove(e)  }
    editor.onMouseEnter.add |e| { onMouseMove(e)  }
  }

//////////////////////////////////////////////////////////////////////////
// Conveniences
//////////////////////////////////////////////////////////////////////////

  internal Doc doc() { editor.doc }

  Viewport viewport() { editor.viewport }

  EditorOptions options() { editor.options }

//////////////////////////////////////////////////////////////////////////
// Focus Eventing
//////////////////////////////////////////////////////////////////////////

  Void onFocus(Event event)
  {
    editor.trapEvent(event)
    if (event.consumed) return

    onAnimate
    caretVisible = true
    editor.repaint
  }

  Void onBlur(Event event)
  {
    editor.trapEvent(event)
    if (event.consumed) return

    navCol = null
    editor.repaint
  }

//////////////////////////////////////////////////////////////////////////
// Key Eventing
//////////////////////////////////////////////////////////////////////////

  Void onKeyDown(Event event)
  {
    editor.trapEvent(event)
    if (event.consumed) return

    caret := editor.caret
    doc := editor.doc

    // shift may indicate selection so don't include
    // that in navigation checks
    key := event.key
    navKey := key
    if (navKey.isShift) navKey = navKey - Key.shift

    // navigation
    switch (navKey.toStr)
    {
      case Keys.up:         goto(event, caret.up(doc)); return
      case Keys.down:       goto(event, caret.down(doc)); return
      case Keys.left:       goto(event, caret.left(doc)); return
      case Keys.right:      goto(event, caret.right(doc)); return
      case Keys.prevWord:   goto(event, caret.prevWord(doc)); return
      case Keys.nextWord:   goto(event, caret.nextWord(doc)); return
      case Keys.lineStart:  goto(event, caret.home(doc)); return
      case Keys.lineEnd:    goto(event, caret.end(doc)); return
      case Keys.docStart:   goto(event, doc.homePos); return
      case Keys.docEnd:     goto(event, doc.endPos); return
      case Keys.pageUp:     event.consume; viewport.pageUp; return
      case Keys.pageDown:   event.consume; viewport.pageDown; return
      case Keys.copy:       event.consume; onCopy; return
    }

    // everything else is editing functionality
    if (editor.ro) return

    // handle special modify keys
    switch (key.toStr)
    {
      case Keys.enter:      event.consume; onEnter; return
      case Keys.backspace:  event.consume; onBackspace; return
      case Keys.del:        event.consume; onDel(false); return
      case Keys.delWord:    event.consume; onDel(true); return
      case Keys.cutLine:    event.consume; onCutLine; return
      case Keys.cut:        event.consume; onCut; return
      case Keys.paste:      event.consume; onPaste; return
      case Keys.undo:       event.consume; changeStack.onUndo(editor); return
      case Keys.redo:       event.consume; changeStack.onRedo(editor); return
      case Keys.indent:     event.consume; onTab(true); return
      case Keys.unindent:   event.consume; onTab(false); return
    }

    // normal insert of character
    if (event.keyChar != null && event.keyChar >= ' ' &&
        !key.isCtrl && !key.isAlt && !key.isCommand)
    {
      event.consume
      insert(event.keyChar.toChar)
      return
    }

  }

  Void onKeyUp(Event event)
  {
    editor.trapEvent(event)
    if (event.consumed) return

    if (event.key == Key.shift) anchor = null
  }

  private Void goto(Event event, Pos newCaret)
  {
    event.consume
    if (event.key != null && event.key.isShift)
    {
      if (anchor == null) anchor = editor.caret
    }
    else
    {
      anchor = null
    }

    // if moving up/down then remember col position
    // to handle ragged lines
    oldCaret := viewport.caret
    if (oldCaret.line != newCaret.line)
    {
      if (navCol == null)
        navCol = oldCaret.col
      else
        newCaret = Pos(newCaret.line, navCol)
    }
    else
    {
      navCol = null
    }

    viewport.goto(newCaret)
    editor.selection = anchor == null ? null : Span(anchor, newCaret)
  }

  private Void insert(Str newText)
  {
    sel := editor.selection
    if (sel == null) sel = Span(editor.caret, editor.caret)
    modify(sel, newText)
    editor.selection = null
  }
  private Void onCopy()
  {
    if (editor.selection == null) return
    Desktop.clipboard.setText(doc.textRange(editor.selection))
  }

  private Void onCut()
  {
    if (editor.selection == null) return
    onCopy
    delSelection
  }

  private Void onPaste()
  {
    text := Desktop.clipboard.getText
    if (text == null || text.isEmpty) return
    insert(text)
  }

  private Void onEnter()
  {
    // handle selection + enter as delete selection
    if (editor.selection != null) { delSelection; return }

    // find next place to indent
    caret := editor.caret
    line := doc.line(caret.line)
    col := 0
    while (col < line.size - 1 && line[col].isSpace) col++
    if (line.getSafe(caret.col) == '}') col -= editor.options.tabSpacing

    // insert newline and indent spaces
    newText := "\n" + Str.spaces(col)
    modify(Span(caret, caret), newText)
    viewport.goto(Pos(caret.line+1, col))
  }

  private Void onBackspace()
  {
    if (editor.selection != null) { delSelection; return }
    doc := editor.doc
    caret := editor.caret
    prev := caret.left(doc)
    modify(Span(prev, caret), "")
    viewport.goto(prev)
  }

  private Void onDel(Bool word)
  {
    if (editor.selection != null) { delSelection; return }
    doc := editor.doc
    caret := editor.caret
    next := word ? caret.endWord(doc) : caret.right(doc)
    modify(Span(caret, next), "")
  }

  private Void onCutLine()
  {
    if (editor.selection != null) { delSelection; return }
    doc := editor.doc
    caret := editor.caret
    start := Pos(caret.line, 0)
    end := caret.line >= doc.lineCount-1 ? doc.endPos : Pos(caret.line+1, 0)
    span := Span(start, end)
    text := doc.textRange(span)
    Desktop.clipboard.setText(text)
    modify(span, "")
  }
  private Void delSelection()
  {
    sel := editor.selection
    modify(sel, "")
    editor.selection = null
    viewport.goto(sel.start)
  }

  private Void onTab(Bool indent)
  {
    // if batch indent/detent
    if (editor.selection != null) { onBatchTab(indent); return }

    // indent single line
    caret := editor.caret
    if (indent)
    {
      col := caret.col + 1
      while (col % options.tabSpacing != 0) col++
      spaces := Str.spaces(col - caret.col)
      modify(Span(caret, caret), spaces)
    }
    else
    {
      col := caret.col - 1
      while (col % options.tabSpacing != 0) col--
      if (col < 0) col = 0
      if (col == caret.col) return
      modify(Span(Pos(caret.line, col), caret), "")
    }
  }

  private Void onBatchTab(Bool indent)
  {
    changes := Change[,]
    doc := editor.doc
    sel := editor.selection
    endLine := sel.end.line
    if (endLine > sel.start.line && sel.end.col == 0) endLine--
    for (linei := sel.start.line; linei <= endLine; ++linei)
    {
      pos := Pos(linei, 0)
      if (indent)
      {
        spaces := Str.spaces(options.tabSpacing)
        changes.add(SimpleChange(pos, "", spaces))
      }
      else
      {
        // find first non-space
        first := 0
        line := doc.line(linei)
        while (first < line.size && line[first].isSpace) first++

        if (first == 0) continue
        end := Pos(linei, first.min(2))
        changes.add(SimpleChange(pos, Str.spaces(end.col), ""))
      }
    }

    if (changes.size > 0)
    {
      batch := BatchChange(changes)
      batch.execute(editor)
      changeStack.push(batch)
    }
  }

//////////////////////////////////////////////////////////////////////////
// Modification / Undo
//////////////////////////////////////////////////////////////////////////

  internal Void modify(Span span, Str newText)
  {
    doc := editor.doc
    oldText := doc.textRange(span)
    change := SimpleChange(span.start, oldText, newText)
    change.execute(editor)
    changeStack.push(change)
  }
//////////////////////////////////////////////////////////////////////////
// Mouse Eventing
//////////////////////////////////////////////////////////////////////////

  Void onMouseDown(Event event)
  {
    isMouseDown = true
    navCol = null

    editor.trapEvent(event)
    if (event.consumed) return

    if (event.count == 2) { mouseSelectWord(event); return }
    if (event.count == 3) { mouseSelectLine(event); return }

    viewport.goto(viewport.pointToPos(event.pos))
    anchor = editor.caret
    editor.selection = null

    editor.trapEvent(event)
    if (event.consumed) return
  }

  Void onMouseUp(Event event)
  {
    isMouseDown = false

    editor.trapEvent(event)
    if (event.consumed) return

    anchor = null
    editor.repaint()
  }

  Void onMouseMove(Event event)
  {
    if (anchor != null && isMouseDown) { mouseSelectDrag(event); return }
  }

  private Void mouseSelectDrag(Event event)
  {
    pos := viewport.pointToPos(event.pos)
    editor.selection = Span(anchor, pos)
  }

  private Void mouseSelectWord(Event event)
  {
    pos := viewport.pointToPos(event.pos)
    doc := editor.doc
    start := pos.prevWord(doc)
    end := pos.nextWord(doc)
    editor.selection = Span(start, end)
    viewport.goto(end)
  }

  private Void mouseSelectLine(Event event)
  {
    pos := viewport.pointToPos(event.pos)
    line := editor.doc.line(pos.line)
    end := Pos(pos.line, line.size)
    editor.selection = Span(Pos(pos.line, 0), end)
    viewport.goto(end)
  }

//////////////////////////////////////////////////////////////////////////
// Animation
//////////////////////////////////////////////////////////////////////////

  Void onAnimate()
  {
    caretVisible = !caretVisible
    viewport.repaintLine(viewport.caret.line)
    if (editor.hasFocus) Desktop.callLater(500ms) |->| { onAnimate }
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private Editor editor
  private Pos? anchor          // if in selection mode
  private Bool isMouseDown     // is mouse currently down
  private Int? navCol          // to handle ragged col up/down

  ChangeStack changeStack  // change stack
  Bool caretVisible    // is caret visible or blinking off
}

