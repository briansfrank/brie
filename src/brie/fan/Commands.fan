//
// Copyright (c) 2012, Brian Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   22 Apr 12  Brian Frank  Creation
//

using gfx
using fwt
using concurrent
using compilerDoc
using syntax
using bocce

**
** Application level commands
**
const class Commands
{
  new make(Sys sys)
  {
    this.sys = sys
    list := Cmd[,]
    typeof.fields.each |field|
    {
      if (field.type != Cmd#) return
      Cmd cmd := field.get(this)
      list.add(cmd)
      cmd.sysRef.val = sys
    }
    this.list = list
  }

  Cmd? findByKey(Key key) { list.find |cmd| { cmd.key == key } }

  const Sys sys
  const Cmd[] list
  const Cmd about        := AboutCmd()
  const Cmd exit         := ExitCmd()
  const Cmd reload       := ReloadCmd()
  const Cmd save         := SaveCmd()
  const Cmd closeConsole := CloseConsoleCmd()
  const Cmd recent       := RecentCmd()
  const Cmd prevMark     := PrevMarkCmd()
  const Cmd nextMark     := NextMarkCmd()
  const Cmd find         := FindCmd()
  const Cmd findInSpace  := FindInSpaceCmd()
  const Cmd goto         := GotoCmd()
  const Cmd showDocs     := ShowDocsCmd()
  const Cmd fileRename   := FileRenameCmd()
  const Cmd fileDup      := FileDupCmd()
  const Cmd fileDelete   := FileDeleteCmd()
  const Cmd build        := BuildCmd()
}

**************************************************************************
** Cmd
**************************************************************************

const abstract class Cmd
{
  abstract Str name()

  abstract Void invoke(Event event)

  virtual Void runOn(File f) { throw UnsupportedErr() }

  virtual Key? key() { null }

  Sys sys() { sysRef.val }
  internal const AtomicRef sysRef := AtomicRef(null)

  Options options() { sys.options }
  Frame frame() { sys.frame }
  Console console() { frame.console }
}

**************************************************************************
** AboutCmd
**************************************************************************

internal const class AboutCmd : Cmd
{
  override const Str name := "About"
  override const Key? key := Key(Keys.about)
  override Void invoke(Event event)
  {
    s := StrBuf()
    env := Env.cur
    vars := env.vars
    javaVer := env.javaVersion
    fanVer := Pod.find("sys").version.toStr
    s.add("java.version:    ").add(vars["java.version"]).add("\n")
    s.add("java.vm.name:    ").add(vars["java.vm.name"]).add("\n")
    s.add("java.vm.vendor:  ").add(vars["java.vm.vendor"]).add("\n")
    s.add("java.home:       ").add(vars["java.home"]).add("\n")
    s.add("jdk.home         ").add(sys.jdkHome).add("\n")
    s.add("fan.platform:    ").add(env.platform).add("\n")
    s.add("fan.version:     ").add(fanVer).add("\n")
    s.add("fan.env:         ").add(env).add("\n")
    s.add("fan.home:        ").add(env.homeDir.osPath).add("\n")
    s.add("fan.work:        ").add(env.workDir.osPath).add("\n")
    s.add("brie.version:    ").add(typeof.pod.version).add("\n")
    s.add("brie.ts:         ").add(DateTime(typeof.pod.meta["build.ts"]).toLocale).add("\n")

    msg := "Brian's Rocking Integrated Environment | Java $javaVer | Fantom $fanVer"

    Dialog.openInfo(frame, msg, s.toStr)
  }
}

**************************************************************************
** ExitCmd
**************************************************************************

internal const class ExitCmd : Cmd
{
  override const Str name := "Exit"

  override Void invoke(Event event)
  {
    r := Dialog.openQuestion(frame, "Exit application?", null, Dialog.okCancel)
    if (r != Dialog.ok) return
    frame.saveSession
    Env.cur.exit(0)
  }
}

**************************************************************************
** ReloadCmd
**************************************************************************

internal const class ReloadCmd : Cmd
{
  override const Str name := "Reload"
  override const Key? key := Key(Keys.reload)
  override Void invoke(Event event) { frame.reload }
}

**************************************************************************
** SaveCmd
**************************************************************************

internal const class SaveCmd : Cmd
{
  override const Str name := "Save"
  override const Key? key := Key(Keys.save)
  override Void invoke(Event event) { frame.save }
}

**************************************************************************
** CloseConsoleCmd
**************************************************************************

internal const class CloseConsoleCmd : Cmd
{
  override const Str name := "Esc"
  override const Key? key := Key(Keys.closeConsole)
  override Void invoke(Event event)
  {
    frame.marks = Item[,]
    frame.console.close
    frame.curView?.onReady
  }
}

**************************************************************************
** Recent
**************************************************************************

internal const class RecentCmd : Cmd
{
  override const Str name := "Recent"
  override const Key? key := Key(Keys.recent)
  override Void invoke(Event event)
  {
    Dialog? dlg
    picker := ItemList(frame, frame.history.items)
    picker.showAcc = true
    picker.showSpace = true
    picker.onAction.add |e|
    {
      frame.goto(e.data)
      dlg.close
    }
    pane := ConstraintPane { minw = 400; minh = 400; add(picker) }
    dlg = Dialog(frame) { title="Recent"; body=pane; commands=[Dialog.ok, Dialog.cancel]; defCommand=null }
    dlg.open
  }
}

**************************************************************************
** Prev/Next Mark
**************************************************************************

internal const class PrevMarkCmd : Cmd
{
  override const Str name := "Prev Mark"
  override const Key? key := Key(Keys.prevMark)
  override Void invoke(Event event) { frame.curMark-- }
}

internal const class NextMarkCmd : Cmd
{
  override const Str name := "Next Mark"
  override const Key? key := Key(Keys.nextMark)
  override Void invoke(Event event) { frame.curMark++ }
}

**************************************************************************
** GotoCmd
**************************************************************************

internal const class GotoCmd : Cmd
{
  override const Str name := "Goto"
  override const Key? key := Key(Keys.goto)
  override Void invoke(Event event)
  {
    // build finder
    finder := ItemFinder(frame)

    // build dialog
    ok := Dialog.ok
    cancel := Dialog.cancel
    dialog := Dialog(frame)
    {
      title = "Goto"
      body = finder
      commands = [ok, cancel]
      defCommand = null
    }

    // finder event handling
    Item? selected := null
    finder.onAction.add |e| { selected = e.data; dialog.close(ok) }

    // open dialog
    if (dialog.open != Dialog.ok) return

    // process selection
    if (selected == null) return
    frame.goto(selected)
  }
}

**************************************************************************
** ShowDocsCmd
**************************************************************************

internal const class ShowDocsCmd : Cmd
{
  override const Str name := "Show Docs"
  override const Key? key := Key(Keys.showDocs)
  override Void invoke(Event event)
  {
    finder := ItemFinder(frame) { slotMode = true }
    docs := Editor { ro = true; rules = SyntaxRules.loadForExt("fan") }
    docs.load("".in)

    // build dialog
    ok := Dialog.ok
    cancel := Dialog.cancel
    dialog := Dialog(frame)
    {
      title = "Show Docs"
      body = ConstraintPane
      {
        minw = 900; minh = 300
        EdgePane
        {
          left = ConstraintPane { minw = maxw = 250; finder, }
          center = InsetPane(0, 0, 0, 8) { docs, }
        },
      }
      commands = [ok]
      defCommand = null
    }

    // event handling
    finder.onAction.add |e| { docs.load(format(e.data).in) }
    finder.onSelect.add |e| { docs.load(format(e.data).in) }

    dialog.open
  }

  Str format(Item? item)
  {
    if (item == null) return ""
    if (item.slot != null)
    {
      d := frame.sys.index.slotDoc(item.slot)
      if (d == null) return "Not Available"
      if (d is DocField) return formatField(d)
      else return formatMethod(d)
    }
    else
    {
      d := frame.sys.index.typeDoc(item.type)
      if (d == null) return "Not Available"
      return formatType(d)
    }
  }

  private StrBuf formatStart(DocFandoc doc, Str flags)
  {
    s := StrBuf()
    s.add("**\n")
    lines := doc.text.splitLines
    while (lines.size > 0 && lines[-1].isEmpty) lines.removeAt(-1)
    lines.each |line| { s.add("** ").add(line).add("\n") }
    s.add("**\n")
    if (!flags.isEmpty) s.add(flags).add(" ")
    return s
  }

  private Str formatType(DocType t)
  {
    s := formatStart(t.doc, DocFlags.toTypeDis(t.flags))
    s.add(t.qname)
    return s.toStr
  }

  private Str formatField(DocField f)
  {
    s := formatStart(f.doc, DocFlags.toSlotDis(f.flags))
    s.add(f.type.dis).add(" ").add(f.name)
    return s.toStr
  }

  private Str formatMethod(DocMethod m)
  {
    s := formatStart(m.doc, DocFlags.toSlotDis(m.flags))
    s.add(m.returns.dis).add(" ").add(m.name).add("(")
    m.params.each |p, i|
    {
      if (i > 0) s.add(", ")
      s.add(p.type.dis).add(" ").add(p.name)
    }
    s.add(")")
    return s.toStr
  }
}

**************************************************************************
** FindCmd
**************************************************************************

internal const class FindCmd : Cmd
{
  override const Str name := "Find"
  override const Key? key := Key(Keys.find)
  override Void invoke(Event event)
  {
    f := frame.curFile
    if (f != null) runOn(f)
  }

  override Void runOn(File file)
  {
    prompt := Text { }
    path := Text { text = FileUtil.pathDis(file) }
    matchCase := Button { mode = ButtonMode.check; text = "Match case"; selected = lastMatchCase.val }

    selection := frame.curView?.curSelection ?: ""
    if (!selection.isEmpty && !selection.contains("\n"))
      prompt.text = selection.trim
    else
      prompt.text = lastStr.val

    pane := GridPane
    {
      numCols = 2
      expandCol = 1
      halignCells = Halign.fill
      Label { text="Find" },
      ConstraintPane { minw=300; maxw=300; add(prompt) },
      Label { text="File" },
      ConstraintPane { minw=300; maxw=300; add(path) },
      Label {}, // spacer
      matchCase,
    }
    dlg := Dialog(frame)
    {
      title = "Find"
      body  = pane
      commands = [Dialog.ok, Dialog.cancel]
    }
    prompt.onAction.add |->| { dlg.close(Dialog.ok) }
    if (Dialog.ok != dlg.open) return

    // get and save text to search for
    str := prompt.text
    lastStr.val = str
    lastMatchCase.val = matchCase.selected

    // find all matches
    matches := Item[,]
    if (!matchCase.selected) str = str.lower
    findMatches(matches, file, str, matchCase.selected)
    if (matches.isEmpty) { Dialog.openInfo(frame, "No matches: $str.toCode"); return }

    // open in console
    console.show(matches)
    frame.goto(matches.first)
  }

  Void findMatches(Item[] matches, File f, Str str, Bool matchCase)
  {
    // recurse dirs
    if (f.isDir)
    {
      if (f.name.startsWith(".")) return
      if (f.name == "tmp" || f.name == "temp") return
      f.list.each |x| { findMatches(matches, x, str, matchCase) }
      return
    }

    // skip non-text files
    if (f.mimeType?.mediaType != "text") return

    f.readAllLines.each |line, linei|
    {
      chars := matchCase ? line : line.lower
      col := chars.index(str)
      while (col != null)
      {
        dis := "$f.name(${linei+1}): $line.trim"
        span := Span(linei, col, linei, col+str.size)
        matches.add(Item(f)
        {
          it.line = linei
          it.col  = col
          it.span = span
          it.dis  = dis
          it.icon = Theme.iconMark
        })
        col = chars.index(str, col+str.size)
      }
    }
  }

  const AtomicRef lastStr := AtomicRef("")
  const AtomicBool lastMatchCase:= AtomicBool(true)
}

**************************************************************************
** FindInSpaceCmd
**************************************************************************

internal const class FindInSpaceCmd : Cmd
{
  override const Str name := "Find in Space"
  override const Key? key := Key(Keys.findInSpace)
  override Void invoke(Event event)
  {
    File? dir
    cs := frame.curSpace
    if (cs is PodSpace)  dir = ((PodSpace)cs).dir
    if (cs is FileSpace) dir = ((FileSpace)cs).dir
    if (dir != null) ((FindCmd)sys.commands.find).runOn(dir)
  }
}

**************************************************************************
** FileRenameCmd
**************************************************************************

internal const class FileRenameCmd : Cmd
{
  override const Str name := "File Rename"
  override Void invoke(Event event) { throw Err("Need file") }

  override Void runOn(File f)
  {
    prompt := Dialog.openPromptStr(frame, "New file name:", f.name)
    if (prompt == null) return

    f.rename(prompt)
    frame.reload
  }
}

**************************************************************************
** FileDupCmd
**************************************************************************

internal const class FileDupCmd : Cmd
{
  override const Str name := "File Dup"
  override Void invoke(Event event) { throw Err("Need file") }

  override Void runOn(File f)
  {
    if (f.isDir)
    {
      Dialog.openErr(frame, "File is directory")
      return
    }

    prompt := Dialog.openPromptStr(frame, "File name:", f.name)
    if (prompt == null) return

    f.copyTo(f.parent.plus(prompt.toUri))
    frame.reload
  }
}

**************************************************************************
** FileDeleteCmd
**************************************************************************

internal const class FileDeleteCmd : Cmd
{
  override const Str name := "File Delete"
  override Void invoke(Event event) { throw Err("Need file") }

  override Void runOn(File f)
  {
    r := Dialog.openQuestion(frame, "Delete $f.name?", null, Dialog.okCancel)
    if (r != Dialog.ok) return
    f.delete
    frame.reload
  }
}

**************************************************************************
** BuildCmd
**************************************************************************

internal const class BuildCmd : Cmd
{
  override const Str name := "Build"
  override const Key? key := Key(Keys.build)
  override Void invoke(Event event)
  {
    f := findBuildFile
    if (f == null)
    {
      Dialog.openErr(frame, "No build.fan file found")
      return
    }


    console.execFan([f.osPath], f.parent) |c|
    {
      pod := sys.index.podForFile(f)
      if (pod != null) sys.index.reindexPod(pod)
    }
  }

  File? findBuildFile()
  {
    // save current file
    frame.save

    // get the current resource as a file, if this file is
    // the build.fan file itself, then we're done
    f := frame.curFile
    if (f == null) return null
    if (f.name == "build.fan") return f

    // lookup up directory tree until we find "build.fan"
    if (!f.isDir) f = f.parent
    while (f.path.size > 0)
    {
      buildFile := f + `build.fan`
      if (buildFile.exists) return buildFile
      f = f.parent
    }
    return null
  }
}


