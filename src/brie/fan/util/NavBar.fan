//
// Copyright (c) 2012, Brian Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   25 May 12  Brian Frank  Creation
//

using gfx
using fwt

**
** NavBar
**
internal class NavBar : Canvas
{
  new make(Frame frame)
  {
    this.frame = frame

    onMouseUp.add |e|
    {
      e.consume
      tab := posToTab(e.pos)
      if (tab == null) return
      if (e.isPopupTrigger) { onPopup(e, tab); return }
      if (e.button == 1) { frame.goto(tab.item); return }
    }
  }

  Void load(Item[] items, Int curIndex)
  {
    x := 4
    tabs = items.map |s, i->NavTab|
    {
      tab := NavTab(s, i == curIndex, x)
      x += tab.w + 4
      return tab
    }
    repaint
  }

  override Size prefSize(Hints hints := Hints.defVal)
  {
    Size(300, 32)
  }

  override Void onPaint(Graphics g)
  {
    w := size.w; h := size.h
    g.push
    g.antialias = true
    g.font = font
    g.brush = bgBar
    g.fillRect(0, 0, w, h)

    tabs.each |tab|
    {
      g.brush = tab.cur ? bgCur : bgTab
      g.fillRoundRect(tab.x, 4, tab.w, h-11, 12, 12)
      g.brush = fgTab
      g.drawRoundRect(tab.x, 4, tab.w, h-11, 12, 12)
      g.drawImage(tab.item.icon, tab.x+6, 7)
      g.brush = Color.black
      g.drawText(tab.item.dis, tab.x+24, 7)
    }
    g.pop
  }

  NavTab? posToTab(Point p)
  {
    tabs.find |t| { t.x <= p.x && p.x <= t.x+t.w }
  }

  private Void onPopup(Event e, NavTab tab)
  {
    menu := tab.item.popup(frame)
    if (menu == null) return
    menu.open(e.widget, e.pos)
  }

  static const Font font   := Desktop.sysFont
  static const Color bgBar := Theme.wallpaper
  static const Color bgTab := Color(0xee_ee_ee)
  static const Color bgCur := Color.green
  static const Color fgTab := Color(0x66_66_66)

  Frame frame
  private NavTab[] tabs := [,]
}

internal class NavTab
{
  new make(Item item, Bool cur, Int x)
  {
    this.item = item
    this.cur = cur
    this.x = x
    this.w = 6 + 20 + SpaceBar.font.width(item.dis) + 6
  }

  const Item item
  const Bool cur
  const Int x
  const Int w
}

