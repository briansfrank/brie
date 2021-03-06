//
// Copyright (c) 2012, Brian Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   25 May 12  Brian Frank  Creation
//

using gfx
using fwt
using concurrent
using bocce

**
** ItemList
**
class ItemList : Panel
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  new make(Frame frame, Item[] items)
  {
    this.frame = frame
    update(items)
    onMouseUp.add |e| { doMouseUp(e) }
    onKeyDown.add |e| { doKeyDown(e) }
    onFocus.add |e| { doFocus(e) }
    onBlur.add |e| { doBlur(e) }
  }

//////////////////////////////////////////////////////////////////////////
// Config
//////////////////////////////////////////////////////////////////////////

  Frame? frame { private set }

  Item[] items := [,] { private set  }

  const Font font := Desktop.sysFontMonospace

  const Font auxFont := Desktop.sysFont.toSize(9)

  const Color auxColor := Color("#666")

  ** Show A - B accelerators and enable keyboard navigation
  Bool showAcc := false

  Bool showSpace := false

  Item? highlight { set { &highlight = it; repaint } }

//////////////////////////////////////////////////////////////////////////
// Panel
//////////////////////////////////////////////////////////////////////////

  override Int lineCount() { items.size }

  override Int lineh() { itemh }

  override Int colCount := 5 { private set }

  override const Int colw := font.width("m")

  private Int itemh() { font.height.max(18) }

//////////////////////////////////////////////////////////////////////////
// Items
//////////////////////////////////////////////////////////////////////////

  Void addItem(Item item)
  {
    update(this.items.rw.add(item))
    relayout
    repaint
  }

  Void update(Item[] newItems)
  {
    maxDis   := 5
    maxSpace := 5
    newItems.each |x|
    {
      maxDis = x.dis.size.max(maxDis)
      maxSpace = (x.space?.dis ?: "").size.max(maxSpace)
    }
    cols := maxDis
    cols += 2 // 2 for icon
    if (showAcc) cols += 2
    if (showSpace) cols += 2 + maxSpace

    this.items = newItems.ro
    this.colCount = cols
    this.accY = (font.height - auxFont.height) / 2
    this.spaceW = auxFont.width("m") * maxSpace

    &highlight = null
    select(null)
    relayout
    repaint
  }

  Void clear() { update(Item[,]) }

//////////////////////////////////////////////////////////////////////////
// Layout
//////////////////////////////////////////////////////////////////////////

  override Size prefSize(Hints hints := Hints.defVal)
  {
    Size(200,200)
  }

//////////////////////////////////////////////////////////////////////////
// Painting
//////////////////////////////////////////////////////////////////////////

  override Void onPaintLines(Graphics g, Range lines)
  {
    x := 4
    y := 0
    itemh := this.itemh
    items.eachRange(lines) |item, index|
    {
      paintItem(g, item, index, x, y)
      y += itemh
    }
  }

  private Void paintItem(Graphics g, Item item, Int index, Int x, Int y)
  {
    w := size.w - 10
    fg := Color.black
    if (item === this.highlight)
    {
      g.brush = Color.yellow
      g.fillRoundRect(0, y, w, itemh, 10, 10)
    }
    if (index == selected)
    {
      g.brush = Desktop.sysListSelBg
      fg = Desktop.sysListSelFg
      g.fillRoundRect(0, y, w, itemh, 10, 10)
    }
    if (showAcc)
    {
      if (index < 26)
      {
        g.brush = auxColor
        g.font = auxFont
        g.drawText(('A'+index).toChar, x, y+accY)
      }
      x += colw + 8
    }
    x += item.indent*20
    g.brush = fg
    g.font = font
    if (item.icon != null) g.drawImage(item.icon, x, y)
    g.drawText(item.dis, x+20, y)
    if (showSpace)
    {
      spaceDis := item.space?.dis
      if (spaceDis != null)
      {
        g.brush = auxColor
        g.font = auxFont
        g.drawText(spaceDis, w - spaceW, y)
      }
    }
  }

//////////////////////////////////////////////////////////////////////////
// Event Listeners
//////////////////////////////////////////////////////////////////////////

  once EventListeners onAction() { EventListeners() }

  once EventListeners onSelect() { EventListeners() }

  private Void fireAction(Item? item)
  {
    if (item == null) return
    if (onAction.isEmpty)
      frame.goto(item)
    else
      onAction.fire(Event { it.id = EventId.action; it.widget = this; it.data = item })
  }

  private Void fireSelect()
  {
    item := selected == null ? null : items.getSafe(selected)
    onSelect.fire(Event { it.id = EventId.select; it.widget = this; it.data = item })
  }

//////////////////////////////////////////////////////////////////////////
// Event Handling
//////////////////////////////////////////////////////////////////////////

  private Item? yToItem(Int y) { items.getSafe(yToLine(y)) }

  private Void doMouseUp(Event event)
  {
    item := items.getSafe(yToLine(event.pos.y))
    if (event.count == 1 && event.button == 1)
    {
      event.consume
      fireAction(item)
      return
    }

    if (event.isPopupTrigger && onAction.isEmpty)
    {
      event.consume
      menu := item?.popup(frame)
      if (menu != null) menu.open(event.widget, event.pos)
      return
    }
  }

  private Void doKeyDown(Event event)
  {
    if (event.key == Key.esc)
    {
      dlg := window as Dialog
      if (dlg != null)
      {
        cancel := dlg.commands.find |cmd| { cmd == Dialog.cancel }
        if (cancel != null || dlg.commands.size == 1) dlg.close(cancel)
      }
      return
    }

    if (!showAcc) return

    if (event.key == Key.up && lineCount > 0)
    {
      if (selected == null)
        select(0)
      else
        select(selected-1)
      return
    }

    if (event.key == Key.down && lineCount > 0)
    {
      if (selected == null)
        select(0)
      else
        select(selected+1)
      return
    }

    if (event.key == Key.enter)
    {
      if (0 <= selected && selected < items.size)
        fireAction(items[selected])
      return
    }

    code := event.keyChar
    if (code >= 97 && code <= 122) code -= 32
    code -= 65
    if (code >= 0 && code < 26 && code < lineCount)
    {
      fireAction(items.getSafe(code))
    }
  }

  private Void doFocus(Event e)
  {
    if (showAcc && selected < 0 && !items.isEmpty)
      select(0)
  }

  private Void doBlur(Event e)
  {
    select(null)
  }

  private Void select(Int? selected)
  {
    // slip to range
    if (selected != null)
    {
      if (selected >= items.size) selected = items.size - 1
      if (selected < 0) selected = 0
    }

    // update field
    this.selected = selected

    // ensure scrolled to selection
    if (selected != null)
    {
      view := viewportLines
      viewNum := view.end - view.start
      if (selected < view.start)
      {
        scrollToLine(selected)
      }
      if (selected >= view.end)
      {
        scrollToLine(selected - viewNum + 1)
      }
    }

    // repaint and fire callback
    repaint
    fireSelect
  }


//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private Int accY
  private Int spaceW
  private Int? selected
}

