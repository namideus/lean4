/-
Copyright (c) 2022 Mac Malone. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Mac Malone
-/
import Lake.Util.Casing
import Lake.Config.InstallPath
import Lake.Config.LeanConfig
import Lake.Config.Glob

namespace Lake
open Lean System

/-- A Lean library's declarative configuration. -/
structure LeanLibConfig extends LeanConfig where
  /-- The name of the target. -/
  name : Name

  /--
  The subdirectory of the package containing the library's Lean source files.
  Defaults to the package's `srcDir`.

  (This will be passed to `lean` as the `-R` option.)
  -/
  srcDir : FilePath := "."

  /--
  The root module(s) of the library.

  Submodules of these roots (e.g., `Lib.Foo` of `Lib`) are considered
  part of the package.

  Defaults to a single root of the library's upper camel case name.
  -/
  roots : Array Name := #[toUpperCamelCase name]

  /--
  An `Array` of module `Glob`s to build for the library.
  Defaults to a `Glob.one` of each of the library's  `roots`.

  Submodule globs build every source file within their directory.
  Local imports of glob'ed files (i.e., fellow modules of the workspace) are
  also recursively built.
  -/
  globs : Array Glob := roots.map Glob.one

  /--
  The name of the library.
  Used as a base for the file names of its static and dynamic binaries.
  Defaults to the upper camel case name of the target.
  -/
  libName := toUpperCamelCase name |>.toString (escape := false)

  /--
  Whether to compile each of the library's modules into a native shared library
  that is loaded whenever the module is imported. This speeds up evaluation of
  metaprograms and enables the interpreter to run functions marked `@[extern]`.

  Defaults to `false`.
  -/
  precompileModules : Bool := false

deriving Inhabited, Repr

namespace LeanLibConfig

/-- Whether the given module is considered local to the library. -/
def isLocalModule (mod : Name) (self : LeanLibConfig) : Bool :=
  self.roots.any (fun root => root.isPrefixOf mod) ||
  self.globs.any (fun glob => glob.matches mod)

/-- Whether the given module is a buildable part of the library. -/
def isBuildableModule (mod : Name) (self : LeanLibConfig) : Bool :=
  self.globs.any (fun glob => glob.matches mod) ||
  self.roots.any (fun root => root.isPrefixOf mod && self.globs.any (·.matches root))
