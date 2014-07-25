//
// Copyright (c) 2014, Brian Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   25 Jul 14  Brian Frank  Creation
//

using gfx
using fwt
using concurrent
using bocce

**
** ItemPicker is used to query a line number, type, slot, or file
**
internal class ItemFinder : EdgePane
{
  new make(Frame frame)
  {
    this.frame = frame
    this.sys = frame.sys
    this.prompt = Text { it.font = Desktop.sysFontMonospace }
    this.list = ItemList(frame, Item[,]) { showAcc = true }
    this.top = InsetPane(0, 0, 10, 0) { prompt, }
    this.bottom = ConstraintPane { minw = maxw = 500; minh = maxh = 500; list, }

    // init from current selection
    prompt.text = frame.curView?.curSelection ?: ""

    prompt.onAction.add |e|
    {
      fireAction(list.items.first)
    }

    prompt.onKeyDown.add |e|
    {
      if (e.key == Key.down)
      {
        e.consume
        list.focus
      }
    }

    prompt.onModify.add |e|
    {
      list.update(findMatches(prompt.text.trim))
    }

    list.onAction.add |e|
    {
      fireAction(e.data)
    }
  }

  once EventListeners onAction() { EventListeners() }

  Bool matchLineNums := true

  Bool matchFiles := true

  private Void fireAction(Item? item)
  {
    if (item == null) return
    onAction.fire(Event { it.id = EventId.action; it.widget = this; it.data = item })
  }

  private Item[] findMatches(Str text)
  {
    acc := Item[,]

    // integers are always line numbers
    if (matchLineNums)
    {
      line := text.toInt(10, false)
      file := frame.curFile
      if (line != null && file != null)
        return [Item { it.dis= "Line $line"; it.file = file; it.line = line-1 }]
    }

    /// slots in current type
    curType := frame.curSpace.curType
    if (curType != null)
    {
      curType.slots.each |s|
      {
        if (s.name.startsWith(text)) acc.add(Item(s) { dis = s.name })
      }
    }

    // match types
    if (!text.isEmpty)
      acc.addAll(sys.index.matchTypes(text).map |t->Item| { Item(t) })

    // f <file>
    if (matchFiles)
    {
      if (text.startsWith("f ") && text.size >= 3)
        acc.addAll(sys.index.matchFiles(text[2..-1]))
    }

    return acc
  }

  private Frame frame
  private Sys sys
  private Text prompt
  private ItemList list
}

