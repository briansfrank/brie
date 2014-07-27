//
// Copyright (c) 2012, Brian Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   24 Apr 12  Brian Frank  Creation
//

using compilerDoc

**
** IndexCache
**
internal class IndexCache
{
  new make(Index index) { this.index = index }

  const Index index

  PodInfo[] listPods() { pods.vals.sort }

  PodInfo? pod(Str name) { pods[name] }

  PodInfo? podForFile(File file)
  {
    file = file.normalize
    return pods.find |pod|
    {
      if (pod.srcDir == null) return false
      return file.pathStr.startsWith(pod.srcDir.pathStr)
    }
  }

  Obj? addPodSrc(Str name, File srcDir, File[] srcFiles)
  {
    cur := pods[name] ?: PodInfo(name, null, TypeInfo[,], null, File#.emptyList)
    pods[name] = PodInfo(name, cur.podFile, cur.types, srcDir, srcFiles)
    docs.remove(name)
    return null
  }

  Obj? addPodLib(Str name, File podFile, TypeInfo[] types)
  {
    cur := pods[name] ?: PodInfo(name, null, TypeInfo[,], null, File#.emptyList)
    pods[name] = PodInfo(name, podFile, types, cur.srcDir, cur.srcFiles)
    docs.remove(name)
    return null
  }

  TypeInfo[] matchTypes(Str pattern, Bool exact)
  {
    exacts := TypeInfo[,]
    approx := TypeInfo[,]
    pods.vals.sort.each |pod|
    {
      pod.types.each |t|
      {
        m := matchType(t, pattern)
        if (m == 0) return
        if (m == 2) exacts.add(t)
        else if (!exact) approx.add(t)
      }
    }
    return exacts.addAll(approx)
  }

  private Int matchType(TypeInfo t, Str pattern)
  {
    if (t.name == pattern || t.qname == pattern) return 2
    if (t.name.startsWith(pattern)) return 1
    return 0
  }

  Item[] matchFiles(Str pattern, Bool exact)
  {
    exacts := Item[,]
    approx := Item[,]
    pods.vals.sort.each |pod|
    {
      pod.srcFiles.each |f|
      {
        m := matchFile(f, pattern)
        if (m == 0) return
        item := Item(f) { dis="$pod.name::$f.name" }
        if (m == 2) exacts.add(item )
        else if (!exact) approx.add(item)
      }
    }
    return exacts.addAll(approx)
  }

  private Int matchFile(File f, Str pattern)
  {
    if (f.name == pattern) return 2
    if (f.name.startsWith(pattern)) return 1
    return 0
  }

  DocPod? podDoc(PodInfo p)
  {
    doc := docs[p.name]
    if (doc != null) return doc
    echo("Load pod doc '$p.name' [$p.podFile]")
    if (p.podFile == null) return null

    try
    {
      doc = DocPod.load(p.podFile)
    }
    catch (Err e)
    {
      echo("ERROR: Cannot pod doc [$p.podFile]")
      e.trace
      return null
    }

    docs[p.name] = doc
    return doc
  }

  private Str:PodInfo pods := [:]
  private Str:DocPod docs := [:]
}