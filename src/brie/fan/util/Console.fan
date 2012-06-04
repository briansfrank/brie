//
// Copyright (c) 2012, Brian Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   25 Aug 12  Brian Frank  Creation
//

using gfx
using fwt
using compiler
using syntax
using concurrent

**
** Console
**
class Console : InsetPane
{

  new make(Frame frame) : super(3, 5, 0, 5)
  {
    this.frame = frame
    this.sys = frame.sys
    this.list = ItemList(frame, Item[,])
    this.content = this.list
    this.visible = false
  }

  Bool isBusy() { proc != null }

  Bool isOpen := false { private set }

  Void toggle() { if (isOpen) close; else open }

  Void open()
  {
    isOpen = true
    visible = true
    frame.updateStatus
    parent.relayout
  }

  Void show(Item[] marks)
  {
    frame.marks = marks
    list.update(marks)
    open
  }

  Void close()
  {
    isOpen = false
    visible = false
    frame.updateStatus
    parent.relayout
  }

  Void highlight(Item? item) { list.highlight = item }

  Void log(Str line)
  {
    list.addItem(Item(line))
  }

  Void kill()
  {
    proc := this.proc
    if (proc == null) return
    this.inKill = true
    log("killing...")
    proc.kill
  }

  Void execFan(Str[] args, File dir, |Console|? onDone := null)
  {
    fanHome := sys.options.fanHome
    fan := fanHome + (Desktop.isWindows ? `bin/fan.exe` : `bin/fan`)
    args = args.dup.insert(0, fan.osPath)
    exec(args, dir, onDone)
  }

  Void exec(Str[] cmd, File dir, |Console|? onDone := null)
  {
    open
    frame.marks = Item[,]
    this.inKill = false
    this.proc = ConsoleProcess(this)
    this.onDone = onDone
    list.clear
    proc.spawn(cmd, dir)
  }

  internal Void procDone()
  {
    if (inKill) log("killed")
    if (onDone != null)
    {
      try
        onDone(this)
      catch (Err e)
        e.trace
    }
    proc = null
    inKill = false
    onDone = null
  }

  Frame frame { private set }
  ItemList list { private set}
  const Sys sys
  private ConsoleProcess? proc
  private Bool inKill
  private |Console|? onDone
}

**************************************************************************
** ConsoleProcess
**************************************************************************

internal const class ConsoleProcess
{
  new make(Console console)
  {
    Actor.locals["console"] = console
    actor = Actor(ActorPool()) |msg| { receive(msg) }
  }

  Void spawn(Str[] cmd, File dir)
  {
    actor.send(Msg("spawn", cmd, dir))
  }

  Console console()
  {
    Actor.locals["console"] ?: throw Err("Missing 'console' actor locale")
  }

  Void kill()
  {
    proc := (Process)((Unsafe)procRef.val).val
    proc.kill
  }

  Void writeLines(Str[] lines)
  {
    frame := console.frame
    lines.each |line|
    {
      try
      {
        item := parseLine(line)
        console.list.addItem(item)
        if (item.file != null)
          frame.marks = frame.marks.dup.add(item)
      }
      catch (Err e)
      {
        console.list.addItem(Item(line))
        e.trace
      }
    }
  }

  private Item parseLine(Str str)
  {
    // Fantom "file(line,col): msg"
    // Javac  "file:col: msg"
    if (str.size > 4)
    {
      item := parseFan(str);  if (item != null) return item
      item  = parseJava(str); if (item != null) return item
    }
    return Item(str)
  }

  private Item? parseFan(Str str)
  {
    p1 := str.index("(", 4); if (p1 == null) return null
    c  := str.index(",", p1); if (c == null) return null
    p2 := str.index(")", p1); if (p2 == null) return null
    file := File.os(str[0..<p1])
    line := str[p1+1..<c].toInt(10, false) ?: 1
    col  := str[c+1..<p2].toInt(10, false) ?: 1
    text := file.name + str[p1..-1]
    return Item(file)
    {
      it.dis  = text
      it.line = line-1
      it.col  = col-1
      it.icon = Theme.iconErr
    }
  }

  private Item? parseJava(Str str)
  {
    c1 := str.index(":", 4); if (c1 == null) return null
    c2 := str.index(":", c1+1); if (c2 == null) return null
    file := File.os(str[0..<c1])
    if (!file.exists) return null
    line := str[c1+1..<c2].toInt(10, false) ?: 1
    text := file.name + str[c1..-1]
    return Item(file)
    {
      it.dis  = text
      it.line = line-1
      it.icon = Theme.iconErr
    }
  }

  private Obj? receive(Msg msg)
  {
    if (msg.id == "spawn") return doSpawn(msg.a, msg.b)
    echo("WARNING: unknown msg: $msg")
    throw Err("unknown msg $msg")
  }

  private Obj? doSpawn(Str[] cmd, File dir)
  {
    try
    {
      proc := Process(cmd, dir)
      procRef.val = Unsafe(proc)
      proc.out = ConsoleOutStream(this)
      proc.run.join
    }
    catch (Err e)
    {
      e.trace
    }
    finally
    {
      Desktop.callAsync |->| { console.procDone }
    }
    return null
  }

  private const Actor actor
  private const AtomicRef procRef := AtomicRef(null)
}

**************************************************************************
** ConsoleOutStream
**************************************************************************

internal class ConsoleOutStream : OutStream
{
  new make(ConsoleProcess proc) : super(null) { this.proc = proc }

  const ConsoleProcess proc

  override This write(Int b)
  {
    append(Buf().write(b).flip.readAllStr)
    return this
  }

  override This writeBuf(Buf b, Int n := b.remaining)
  {
    append(Buf().writeBuf(b, n).flip.readAllStr)
    return this
  }

  Void append(Str str)
  {
    curStr = curStr + str
    proc := this.proc
    lines := curStr.splitLines
    if (lines.size <= 1) return
    Desktop.callAsync |->| { proc.writeLines(lines[0..-2]) }
    curStr = lines.last
  }

  Str curStr := ""
}


