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
** Fantom pod space
**
@Serializable
const class PodSpace : Space
{
  new make(Sys sys, Str name, File dir, File? file := null) : super(sys)
  {
    if (!dir.exists) throw Err("Dir doesn't exist: $dir")
    if (!dir.isDir) throw Err("Not a dir: $dir")
    this.name = name
    this.dir  = dir.normalize
    this.file = file ?: dir + `build.fan`
  }

  ** Pod name
  const Str name

  ** Top of source directory
  const File dir

  ** Active file
  const File file


  override Str dis() { name }

  override Image icon() { Theme.iconPod }

  override File? curFile() { file }

  override PodInfo? curPod() { sys.index.pod(name, false) }

  override TypeInfo? curType()
  {
    pod := curPod
    if (pod == null) return null
    types := pod.types.findAll |t| { t.file == file.name }
    if (types.size == 0) return null
    if (types.size == 1) return types.first
    types.sort |a, b| { a.line <=> b.line }
    curLine := sys.frame.curView?.curPos?.line ?: 0
    for (i := 1; i<types.size; ++i)
      if (types[i].line > curLine) return types[i-1]
    return types.first
  }

  override Str:Str saveSession()
  {
    ["pod":name, "dir":dir.uri.toStr, "file":file.uri.toStr]
  }

  static Space loadSession(Sys sys, Str:Str props)
  {
    make(sys, props.getOrThrow("pod"),
         props.getOrThrow("dir").toUri.toFile,
         props.get("file")?.toUri?.toFile)
  }

  override Int match(Item item)
  {
    if (!FileUtil.contains(this.dir, item.file)) return 0
    return 100
  }

  override This goto(Item item)
  {
    make(sys, name, dir, item.file)
  }

  override Widget onLoad(Frame frame)
  {
    return EdgePane
    {
      left = EdgePane
      {
        left = ScrollPane { makeFileNav(frame), }
        right = ScrollPane { makeSlotNav(frame), }
      }
      center = View.makeBest(frame, file)
    }
  }

  private Widget makeFileNav(Frame frame)
  {
    // get all the files
    files := File[,]
    dir.walk |f| { if (!f.isDir) files.add(f) }

    // organize by dir
    byDir := File:File[][:]
    files.each |f|
    {
      bucket := byDir.getOrAdd(f.parent) { File[,] }
      bucket.add(f)
    }

    // now map to items
    items := Item[,]
    byDir.keys.sort.each |d|
    {
      indent := 0
      if (d.path.size != this.dir.path.size)
      {
        dirDis := d.path[this.dir.path.size..-1].join("/") + "/"
        items.add(Item(d) { it.dis = dirDis; } )
        indent = 1
      }
      bucket := byDir[d].sort |a,b| { a.name <=> b.name }
      bucket.each |f| { items.add(Item(f) { it.indent = indent }) }
    }

    return ItemList(frame, items)
  }

  private Widget? makeSlotNav(Frame frame)
  {
    if (file.ext != "fan") return null

    pod := sys.index.pod(this.name, false)
    if (pod == null) return null

    types := pod.types.findAll |t| { t.file == file.name }
    if (types.isEmpty) return null

    items := Item[,]
    types.sort |a, b| { a.line <=> b.line }
    types.each |t|
    {
      items.add(Item(t) { it.dis = t.name } )
      slots := t.slots.dup.sort |a, b| { a.line <=> b.line }
      slots.each |s|
      {
        items.add(Item(s) { it.dis = s.name; it.indent = 1 })
      }
    }

    return ItemList(frame, items)
  }
}

