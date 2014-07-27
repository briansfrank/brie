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
      updateMatches
    }

    list.onAction.add |e|
    {
      fireAction(e.data)
    }

    list.onSelect.add |e|
    {
      onSelect.fire(Event { it.id = EventId.select; it.widget = this; it.data = e.data })
    }

    list.onKeyDown.add |e|
    {
      if (e.key == Key.space)
      {
        prompt.focus
        e.consume
      }
    }
  }

  once EventListeners onAction() { EventListeners() }

  once EventListeners onSelect() { EventListeners() }

  Bool slotMode

  private Void fireAction(Item? item)
  {
    if (item == null) return

    if (slotMode && item.type != null && item.slot == null)
    {
      prompt.text =  item.type.qname + "."
      updateMatches
      prompt.focus
      prompt.select(prompt.text.size, 0)
    }

    onAction.fire(Event { it.id = EventId.action; it.widget = this; it.data = item })
  }

  private Void updateMatches()
  {
    list.update(findMatches(prompt.text.trim))
  }

  private Item[] findMatches(Str text)
  {
    acc := Item[,]

    // qualified slot name
    if (text.contains("::") && text.contains("."))
    {
      pod := sys.index.pod(text[0..<text.index("::")])
      if (pod != null)
      {
        type := pod.type(text[text.index("::")+2..<text.index(".")])
        if (type != null)
        {
          prefix := text[text.index(".")+1..-1]
          type.slots.each |s|
          {
            if (s.name.startsWith(prefix)) acc.add(Item(s) { dis = s.name })
          }
          return acc
        }
      }
    }

    // integers are always line numbers
    if (!slotMode)
    {
      line := text.toInt(10, false)
      file := frame.curFile
      if (line != null && file != null)
        return [Item { it.dis= "Line $line"; it.file = file; it.line = line-1 }]
    }

    // slots in current type
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
    if (!slotMode)
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

