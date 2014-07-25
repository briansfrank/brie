//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 Sep 08  Brian Frank  Creation
//   31 May 11  Brian Frank  Repurpose for Brie
//

using gfx
using fwt

**
** History maintains the most recent navigation history
** of the entire application.
**
class History
{

  **
  ** Log navigation to the specified resource
  ** into the history.  Return this.
  **
  This push(Space space, Item link)
  {
    // create history item
    item := Item
    {
      it.space = space
      it.file  = link.file
      it.dis   = link.file.name
      it.icon  = Theme.fileToIcon(link.file)
    }

    // remove any item that matches space + file
    dup := items.findIndex |x|
    {
      item.space.typeof == x.space.typeof &&
      item.file == x.file
    }
    if (dup != null) items.removeAt(dup)

    // keep size below max
    while (items.size >= max) items.removeAt(-1)

    // push into most recent position
    items.insert(0, item)
    return this
  }

  **
  ** The first item is the most recent navigation and the last
  ** item is the oldest navigation.
  **
  Item[] items := [,] { private set }

  private Int max := 40
}