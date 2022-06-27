/-
Copyright (c) 2022 Mac Malone. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Mac Malone
-/
namespace Lake

/-- Configuration options common to targets that build modules. -/
structure LeanConfig where
  /--
  Additional arguments to pass to `lean` when compiling
  a module's  Lean source files.
  -/
  moreLeanArgs : Array String := #[]

  /--
  Additional arguments to pass to `leanc` when compiling
  a module's C source files generated by `lean`.

  Lake already passes `-O3` and `-DNDEBUG` automatically,
  but you can change this by, for example, adding `-O0` and `-UNDEBUG`.
  -/
  moreLeancArgs : Array String := #[]

  /--
  Additional arguments to pass to `leanc` when linking (e.g., shared
  libraries or binary executable). These will come *after* the paths of
  external libraries.
  -/
  moreLinkArgs : Array String := #[]

  deriving Inhabited, Repr
