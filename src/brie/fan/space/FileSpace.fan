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
  new make(Sys sys, File dir, Str dis:= dir.name, Uri path := ``) : super(sys)
  {
    if (!dir.exists) throw Err("Dir doesn't exist: $dir")
    if (!dir.isDir) throw Err("Not a dir: $dir")
    this.dir = dir.normalize
    this.dis = dis
    this.path = path
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
         props.getOrThrow("dir").toUri.toFile,
         props.getOrThrow("dis"),
         props.get("path", "").toUri)
  }

  override Widget onLoad(Frame frame)
  {
    // build path bar
    pathBar := GridPane
    {
      numCols = path.path.size + 1
    }
    x := this.dir
    pathBar.add(makePathButton(x))
    path.path.each |name|
    {
      x = File(x.uri.plusName(name), false)
      pathBar.add(makePathButton(x))
    }

    // build dir listing
    lastDir := x.isDir ? x : x.parent
    lister := ItemList(Item.makeFiles(lastDir.list))
    lister.onAction.add |e|
    {
      item := (Item)e.data
      pathInto(item.file)
    }

    // if path is file, make view for it
    Widget? view := null
    if (!x.isDir) view = View.makeBest(frame, x)

    return EdgePane
    {
      top = InsetPane(0, 4, 6, 2) { pathBar, }
      left = ScrollPane { lister, }
      center = view
    }
  }

  private Button makePathButton(File file)
  {
    dis := file.name
    if (file === this.dir)
    {
      names := file.path.dup
      if (names.first.endsWith(":")) names.removeAt(0)
      dis = "/" + names.join("/")
    }
    return Button
    {
      text  = dis
      image = Theme.fileToIcon(file)
      onAction.add |e| { pathInto(file) }
    }
  }

  Void pathInto(File file)
  {
    newPath := file.normalize.uri.toStr[this.dir.uri.toStr.size..-1].toUri
    space := FileSpace(sys, dir, dis, newPath)
    sys.frame.reload(space)
  }

}
