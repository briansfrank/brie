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
** SpaceBar
**
internal class SpaceBar : NavBar
{
  new make(Frame frame) : super(frame) {}

  Void onLoad()
  {
    spaces := frame.spaces
    curIndex := spaces.indexSame(frame.curSpace)
    items := spaces.map |space->Item| { Item.makeSpace(space) }
    load(items, curIndex)
  }
}

