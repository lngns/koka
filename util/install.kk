import std/os/path
import std/os/file
import std/os/env
import std/os/flags

val header = "usage:\n stack exec koka -- util/install [-- [options]]\n\noptions:"

struct iflags {
  prefixdir : string = ""
}

val flag-descs : list<flag<iflags>> = {
  fun set-prefix( f : iflags, s : string ) : iflags { 
    f(prefixdir = s) 
  }
  [ Flag( "", ["prefix"], Req(set-prefix,"DIR"), "set prefix directory ('/usr/local')" ) ]
}

public fun process-flags() : <ndet,console> maybe<iflags> {
  val (flags,args,errs) = parse( Iflags(), flag-descs, get-args() )
  if (errs.is-nil && args.is-nil) {
    Just(flags)
  }
  else {
    println( errs.join("\n") + "\n" + flag-descs.usage(header) )
    Nothing
  }
}

fun main() {
  if (!is-file("koka.cabal".path)) {
    println("you can only run 'util/install' from the koka root directory")
    println(flag-descs.usage(header))
    return ()
  }
  match (process-flags()) {
    Nothing -> ()
    Just(flags) -> {
      val predir = if (flags.prefixdir.is-empty) 
                    then get-default-prefix() 
                    else flags.prefixdir.path
      install(predir)
    }
  }
}

fun install( prefixdir : path ) {
  // Install paths
  val koka    = koka-exe-path()  
  val version = "v" + koka-version(koka)
  val bindir  = prefixdir + "bin".path
  val libdir  = prefixdir + "lib/koka".path + version.path
  
  println("installing koka:")
  println("  bin: " + bindir.string)
  println("  lib: " + libdir.string)
  ensure-dir(bindir)
  ensure-dir(libdir)
  
  // Copy Koka
  println("copy koka executable...")
  copy-file-to-dir(koka, bindir)
  
  // Copy std libs
  val stdlibdir = libdir + "lib".path
  println("copy standard libraries...")
  copy-directory("lib/std".path, stdlibdir + "std".path)
  copy-file-to-dir("lib/toc.kk".path, stdlibdir)
  copy-file-to-dir("lib/package.std.json".path, stdlibdir)
  
  // Copy kklib
  val kklibdir = libdir + "kklib".path
  println("copy kklib runtime...")
  copy-directory("kklib/src".path, kklibdir + "src".path)
  copy-directory("kklib/include".path, kklibdir + "include".path)
  copy-directory("kklib/mimalloc".path, kklibdir + "mimalloc".path)
  copy-file-to-dir("kklib/CMakeLists.txt".path, kklibdir)
  copy-file-to-dir("kklib/kkmain.cmake".path, kklibdir)
  
  // Copy contrib
  val contribdir = libdir + "contrib".path
  println("copy contrib...")
  ensure-dir(contribdir)
  copy-file-to-dir("contrib/biginteger.js".path, contribdir)
    
  println("done installing.")
}

fun koka-exe-path() : <file,exn> path {
  val out = run-command("stack path --local-install-root").exn
  val exe = out.trim.path + "bin/koka".path
  if (exe.is-file) return exe
  val win = exe.change-ext(".exe")
  if (win.is-file) return win
  throw("unable to find koka executable: use '> stack build' first.\n  (" + exe.string + ")")
}

fun koka-version( koka : path ) : <file,exn> string {
  val out = run-command(koka.string + " --version").exn
  out.list.drop-while(fn(c){ !is-white(c) }).take-while(fn(c){ c != ',' && c != '\n' }).string.trim
}

fun get-default-prefix() : <file,exn> path {
  val out = run-command("stack path --local-bin").exn
  out.trim.path.nobase
}
