//
// Copyright (c) 2012, Brian Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   22 Apr 12  Brian Frank  Creation
//

using gfx
using fwt

**
** File system space
**
@Serializable
const class FileSpace : Space
{
  new make(Sys sys, File dir, Str dis:= dir.name, Uri path := ``)
    : super(sys)
  {
    if (!dir.exists) throw Err("Dir doesn't exist: $dir")
    if (!dir.isDir) throw Err("Not a dir: $dir")
    this.dir = dir.normalize
    this.dis = dis
    this.path = path
    this.curFile = dir + path
  }

  const File dir

  const Uri path

  override const Str dis

  override Image icon() { Theme.iconDir }

  override Str:Str saveSession()
  {
    props := ["dir": dir.uri.toStr, "dis":dis]
    if (!path.path.isEmpty) props["path"] = path.toStr
    return props
  }

  static Space loadSession(Sys sys, Str:Str props)
  {
    make(sys,
         File(props.getOrThrow("dir").toUri, false),
         props.getOrThrow("dis"),
         props.get("path", "").toUri)
  }

  override const File? curFile

  override PodInfo? curPod() { sys.index.podForFile(curFile) }

  override Int match(Item item)
  {
    if (!FileUtil.contains(this.dir, item.file)) return 0
    if (item.pod != null) return 0
    return this.dir.path.size
  }

  override This goto(Item item)
  {
    make(sys, dir, dis, FileUtil.pathIn(dir, item.file))
  }

  override Widget onLoad(Frame frame)
  {
    // build path bar
    items := Item[Item(dir) { it.dis = FileUtil.pathDis(dir) }]
    x := this.dir
    path.path.each |name|
    {
       x = File(x.uri.plusName(name), false)
       items.add(Item(x))
    }
    pathBar := NavBar(frame)
    pathBar.load(items, -1)

    // build dir listing
    lastDir := x.isDir ? x : x.parent
    lister := ItemList(frame, Item.makeFiles(lastDir.list))

    // if path is file, make view for it
    View? view := null
    if (!x.isDir) view = View.makeBest(frame, x)

    return FileSpacePane(frame, pathBar, lister, view)
  }
}

**************************************************************************
** FileSpacePane
**************************************************************************

internal class FileSpacePane : SpacePane
{
  new make(Frame f, NavBar pathBar, ItemList lister, View? view) : super(f)
  {
    this.pathBar = pathBar
    this.lister = lister
    this.view = view

    top = InsetPane(0, 4, 6, 2) { pathBar, }
    left = InsetPane(0, 4, 0, 4) { lister, }
    center = InsetPane(0, 4, 0, 0) { view, }
  }

  NavBar pathBar
  ItemList lister
  override View? view
}

