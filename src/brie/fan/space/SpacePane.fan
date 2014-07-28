//
// Copyright (c) 2014, Brian Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   28 Jul 14  Brian Frank  Creation
//

using gfx
using fwt

**
** SpacePane manages entire workspace of a space
**
class SpacePane : EdgePane
{
  new make(Frame frame) { this.frame = frame }

  Frame frame { private set }

  virtual View? view() { null }
}

