//
// Copyright (c) 2014, Brian Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   24 Jul 14  Brian Frank  Creation
//

using gfx
using fwt
using syntax
using bocce

**
** DirView
**
class DirView : View
{
  new make(Frame frame, File file) : super(frame, file)
  {
    lister := ItemList(frame, Item.makeFiles(file.list))
    content = lister
  }
}


