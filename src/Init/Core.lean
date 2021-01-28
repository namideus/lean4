/-
Copyright (c) 2014 Microsoft Corporation. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Leonardo de Moura

notation, basic datatypes and type classes
-/
prelude
import Init.Prelude
import Init.SizeOf

universes u v w

def inline {α : Sort u} (a : α) : α := a

@[inline] def flip {α : Sort u} {β : Sort v} {φ : Sort w} (f : α → β → φ) : β → α → φ :=
  fun b a => f a b

/- Remark: thunks have an efficient implementation in the runtime. -/
structure Thunk (α : Type u) : Type u where
  fn : Unit → α

attribute [extern "lean_mk_thunk"] Thunk.mk

@[noinline, extern "lean_thunk_pure"]
protected def Thunk.pure {α : Type u} (a : α) : Thunk α :=
  ⟨fun _ => a⟩
@[noinline, extern "lean_thunk_get_own"]
protected def Thunk.get {α : Type u} (x : @& Thunk α) : α :=
  x.fn ()
@[noinline, extern "lean_thunk_map"]
protected def Thunk.map {α : Type u} {β : Type v} (f : α → β) (x : Thunk α) : Thunk β :=
  ⟨fun _ => f x.get⟩
@[noinline, extern "lean_thunk_bind"]
protected def Thunk.bind {α : Type u} {β : Type v} (x : Thunk α) (f : α → Thunk β) : Thunk β :=
  ⟨fun _ => (f x.get).get⟩

abbrev Eq.ndrecOn.{u1, u2} {α : Sort u2} {a : α} {motive : α → Sort u1} {b : α} (h : Eq a b) (m : motive a) : motive b :=
  Eq.ndrec m h

structure Iff (a b : Prop) : Prop where
  intro :: (mp : a → b) (mpr : b → a)

infix:20 " <-> " => Iff
infix:20 " ↔ "   => Iff

/- Eq basic support -/

inductive Sum (α : Type u) (β : Type v) where
  | inl (val : α) : Sum α β
  | inr (val : β) : Sum α β

inductive PSum (α : Sort u) (β : Sort v) where
  | inl (val : α) : PSum α β
  | inr (val : β) : PSum α β

structure Sigma {α : Type u} (β : α → Type v) where
  fst : α
  snd : β fst

attribute [unbox] Sigma

structure PSigma {α : Sort u} (β : α → Sort v) where
  fst : α
  snd : β fst

inductive Exists {α : Sort u} (p : α → Prop) : Prop where
  | intro (w : α) (h : p w) : Exists p

/- Auxiliary type used to compile `for x in xs` notation. -/
inductive ForInStep (α : Type u) where
  | done  : α → ForInStep α
  | yield : α → ForInStep α

/- Auxiliary type used to compile `do` notation. -/
inductive DoResultPRBC (α β σ : Type u) where
  | «pure»     : α → σ → DoResultPRBC α β σ
  | «return»   : β → σ → DoResultPRBC α β σ
  | «break»    : σ → DoResultPRBC α β σ
  | «continue» : σ → DoResultPRBC α β σ

/- Auxiliary type used to compile `do` notation. -/
inductive DoResultPR (α β σ : Type u) where
  | «pure»     : α → σ → DoResultPR α β σ
  | «return»   : β → σ → DoResultPR α β σ

/- Auxiliary type used to compile `do` notation. -/
inductive DoResultBC (σ : Type u) where
  | «break»    : σ → DoResultBC σ
  | «continue» : σ → DoResultBC σ

/- Auxiliary type used to compile `do` notation. -/
inductive DoResultSBC (α σ : Type u) where
  | «pureReturn» : α → σ → DoResultSBC α σ
  | «break»      : σ → DoResultSBC α σ
  | «continue»   : σ → DoResultSBC α σ

class HasEquiv  (α : Sort u) where
  Equiv : α → α → Prop

infix:50 " ≈ "  => HasEquiv.Equiv

class EmptyCollection (α : Type u) where
  emptyCollection : α

/- Remark: tasks have an efficient implementation in the runtime. -/
structure Task (α : Type u) : Type u where
  pure :: (get : α)

attribute [extern "lean_task_pure"] Task.pure
attribute [extern "lean_task_get_own"] Task.get

namespace Task
/-- Task priority. Tasks with higher priority will always be scheduled before ones with lower priority. -/
abbrev Priority := Nat
def Priority.default : Priority := 0
-- see `LEAN_MAX_PRIO`
def Priority.max : Priority := 8
/--
  Any priority higher than `Task.Priority.max` will result in the task being scheduled immediately on a dedicated thread.
  This is particularly useful for long-running and/or I/O-bound tasks since Lean will by default allocate no more
  non-dedicated workers than the number of cores to reduce context switches. -/
def Priority.dedicated : Priority := 9

@[noinline, extern "lean_task_spawn"]
protected def spawn {α : Type u} (fn : Unit → α) (prio := Priority.default) : Task α :=
  ⟨fn ()⟩

@[noinline, extern "lean_task_map"]
protected def map {α : Type u} {β : Type v} (f : α → β) (x : Task α) (prio := Priority.default) : Task β :=
  ⟨f x.get⟩

@[noinline, extern "lean_task_bind"]
protected def bind {α : Type u} {β : Type v} (x : Task α) (f : α → Task β) (prio := Priority.default) : Task β :=
  ⟨(f x.get).get⟩

end Task

/- Some type that is not a scalar value in our runtime. -/
structure NonScalar where
  val : Nat

/- Some type that is not a scalar value in our runtime and is universe polymorphic. -/
inductive PNonScalar : Type u where
  | mk (v : Nat) : PNonScalar

theorem natAddZero (n : Nat) : n + 0 = n := rfl

theorem optParamEq (α : Sort u) (default : α) : optParam α default = α := rfl

/- Boolean operators -/

@[extern c inline "#1 || #2"] def strictOr  (b₁ b₂ : Bool) := b₁ || b₂
@[extern c inline "#1 && #2"] def strictAnd (b₁ b₂ : Bool) := b₁ && b₂

@[inline] def bne {α : Type u} [BEq α] (a b : α) : Bool :=
  !(a == b)

infix:50 " != " => bne

/- Logical connectives an equality -/

def implies (a b : Prop) := a → b

theorem implies.trans {p q r : Prop} (h₁ : implies p q) (h₂ : implies q r) : implies p r :=
  fun hp => h₂ (h₁ hp)

def trivial : True := ⟨⟩

theorem mt {a b : Prop} (h₁ : a → b) (h₂ : ¬b) : ¬a :=
  fun ha => h₂ (h₁ ha)

theorem notFalse : ¬False := id

-- proof irrelevance is built in
theorem proofIrrel {a : Prop} (h₁ h₂ : a) : h₁ = h₂ := rfl

theorem id.def {α : Sort u} (a : α) : id a = a := rfl

@[macroInline] def Eq.mp {α β : Sort u} (h : α = β) (a : α) : β :=
  h ▸ a

@[macroInline] def Eq.mpr {α β : Sort u} (h : α = β) (b : β) : α :=
  h ▸ b

theorem Eq.substr {α : Sort u} {p : α → Prop} {a b : α} (h₁ : b = a) (h₂ : p a) : p b :=
  h₁ ▸ h₂

theorem castEq {α : Sort u} (h : α = α) (a : α) : cast h a = a :=
  rfl

@[reducible] def Ne {α : Sort u} (a b : α) :=
  ¬(a = b)

infix:50 " ≠ "  => Ne

section Ne
variable {α : Sort u}
variable {a b : α} {p : Prop}

theorem Ne.intro (h : a = b → False) : a ≠ b := h

theorem Ne.elim (h : a ≠ b) : a = b → False := h

theorem Ne.irrefl (h : a ≠ a) : False := h rfl

theorem Ne.symm (h : a ≠ b) : b ≠ a :=
  fun h₁ => h (h₁.symm)

theorem falseOfNe : a ≠ a → False := Ne.irrefl

theorem neFalseOfSelf : p → p ≠ False :=
  fun (hp : p) (h : p = False) => h ▸ hp

theorem neTrueOfNot : ¬p → p ≠ True :=
  fun (hnp : ¬p) (h : p = True) =>
    have ¬True from h ▸ hnp
    this trivial

theorem trueNeFalse : ¬True = False :=
  neFalseOfSelf trivial

end Ne

section
variable {α β φ : Sort u} {a a' : α} {b b' : β} {c : φ}

theorem HEq.ndrec.{u1, u2} {α : Sort u2} {a : α} {motive : {β : Sort u2} → β → Sort u1} (m : motive a) {β : Sort u2} {b : β} (h : a ≅ b) : motive b :=
  @HEq.rec α a (fun b _ => motive b) m β b h

theorem HEq.ndrecOn.{u1, u2} {α : Sort u2} {a : α} {motive : {β : Sort u2} → β → Sort u1} {β : Sort u2} {b : β} (h : a ≅ b) (m : motive a) : motive b :=
  @HEq.rec α a (fun b _ => motive b) m β b h

theorem HEq.elim {α : Sort u} {a : α} {p : α → Sort v} {b : α} (h₁ : a ≅ b) (h₂ : p a) : p b :=
  eqOfHEq h₁ ▸ h₂

theorem HEq.subst {p : (T : Sort u) → T → Prop} (h₁ : a ≅ b) (h₂ : p α a) : p β b :=
  HEq.ndrecOn h₁ h₂

theorem HEq.symm (h : a ≅ b) : b ≅ a :=
  HEq.ndrecOn (motive := fun x => x ≅ a) h (HEq.refl a)

theorem heqOfEq (h : a = a') : a ≅ a' :=
  Eq.subst h (HEq.refl a)

theorem HEq.trans (h₁ : a ≅ b) (h₂ : b ≅ c) : a ≅ c :=
  HEq.subst h₂ h₁

theorem heqOfHEqOfEq (h₁ : a ≅ b) (h₂ : b = b') : a ≅ b' :=
  HEq.trans h₁ (heqOfEq h₂)

theorem heqOfEqOfHEq (h₁ : a = a') (h₂ : a' ≅ b) : a ≅ b :=
  HEq.trans (heqOfEq h₁) h₂

def typeEqOfHEq (h : a ≅ b) : α = β :=
  HEq.ndrecOn (motive := @fun (x : Sort u) _ => α = x) h (Eq.refl α)

end

theorem eqRecHEq {α : Sort u} {φ : α → Sort v} : {a a' : α} → (h : a = a') → (p : φ a) → (Eq.recOn (motive := fun x _ => φ x) h p) ≅ p
  | a, _, rfl, p => HEq.refl p

theorem heqOfEqRecEq {α β : Sort u} {a : α} {b : β} (h₁ : α = β) (h₂ : Eq.rec (motive := fun α _ => α) a h₁ = b) : a ≅ b := by
  subst h₁
  apply heqOfEq
  exact h₂
  done

theorem castHEq : ∀ {α β : Sort u} (h : α = β) (a : α), cast h a ≅ a
  | α, _, rfl, a => HEq.refl a

variable {a b c d : Prop}

theorem iffIffImpliesAndImplies (a b : Prop) : (a ↔ b) ↔ (a → b) ∧ (b → a) :=
  Iff.intro (fun h => And.intro h.mp h.mpr) (fun h => Iff.intro h.left h.right)

theorem Iff.refl (a : Prop) : a ↔ a :=
  Iff.intro (fun h => h) (fun h => h)

theorem Iff.rfl {a : Prop} : a ↔ a :=
  Iff.refl a

theorem Iff.trans (h₁ : a ↔ b) (h₂ : b ↔ c) : a ↔ c :=
  Iff.intro
    (fun ha => Iff.mp h₂ (Iff.mp h₁ ha))
    (fun hc => Iff.mpr h₁ (Iff.mpr h₂ hc))

theorem Iff.symm (h : a ↔ b) : b ↔ a :=
  Iff.intro (Iff.mpr h) (Iff.mp h)

theorem Iff.comm : (a ↔ b) ↔ (b ↔ a) :=
  Iff.intro Iff.symm Iff.symm

/- Exists -/

theorem Exists.elim {α : Sort u} {p : α → Prop} {b : Prop}
   (h₁ : Exists (fun x => p x)) (h₂ : ∀ (a : α), p a → b) : b :=
  h₂ h₁.1 h₁.2

/- Decidable -/

theorem decideTrueEqTrue (h : Decidable True) : @decide True h = true :=
  match h with
  | isTrue h  => rfl
  | isFalse h => False.elim <| h ⟨⟩

theorem decideFalseEqFalse (h : Decidable False) : @decide False h = false :=
  match h with
  | isFalse h => rfl
  | isTrue h  => False.elim h

/-- Similar to `decide`, but uses an explicit instance -/
@[inline] def toBoolUsing {p : Prop} (d : Decidable p) : Bool :=
  @decide p d

theorem toBoolUsingEqTrue {p : Prop} (d : Decidable p) (h : p) : toBoolUsing d = true :=
  @decideEqTrue _ d h

theorem ofBoolUsingEqTrue {p : Prop} {d : Decidable p} (h : toBoolUsing d = true) : p :=
  @ofDecideEqTrue _ d h

theorem ofBoolUsingEqFalse {p : Prop} {d : Decidable p} (h : toBoolUsing d = false) : ¬ p :=
  @ofDecideEqFalse _ d h

instance : Decidable True :=
  isTrue trivial

instance : Decidable False :=
  isFalse notFalse

namespace Decidable
variable {p q : Prop}

@[macroInline] def byCases {q : Sort u} [dec : Decidable p] (h1 : p → q) (h2 : ¬p → q) : q :=
  match dec with
  | isTrue h  => h1 h
  | isFalse h => h2 h

theorem em (p : Prop) [Decidable p] : p ∨ ¬p :=
  byCases Or.inl Or.inr

theorem byContradiction [dec : Decidable p] (h : ¬p → False) : p :=
  byCases id (fun np => False.elim (h np))

theorem ofNotNot [Decidable p] : ¬ ¬ p → p :=
  fun hnn => byContradiction (fun hn => absurd hn hnn)

theorem notAndIffOrNot (p q : Prop) [d₁ : Decidable p] [d₂ : Decidable q] : ¬ (p ∧ q) ↔ ¬ p ∨ ¬ q :=
  Iff.intro
    (fun h => match d₁, d₂ with
      | isTrue h₁,  isTrue h₂   => absurd (And.intro h₁ h₂) h
      | _,           isFalse h₂ => Or.inr h₂
      | isFalse h₁, _           => Or.inl h₁)
    (fun (h) ⟨hp, hq⟩ => match h with
      | Or.inl h => h hp
      | Or.inr h => h hq)

end Decidable

section
variable {p q : Prop}
@[inline] def  decidableOfDecidableOfIff (hp : Decidable p) (h : p ↔ q) : Decidable q :=
  if hp : p then
    isTrue (Iff.mp h hp)
  else
    isFalse fun hq => absurd (Iff.mpr h hq) hp

@[inline] def  decidableOfDecidableOfEq (hp : Decidable p) (h : p = q) : Decidable q :=
  h ▸ hp
end

@[macroInline] instance {p q} [Decidable p] [Decidable q] : Decidable (p → q) :=
  if hp : p then
    if hq : q then isTrue (fun h => hq)
    else isFalse (fun h => absurd (h hp) hq)
  else isTrue (fun h => absurd h hp)

instance {p q} [Decidable p] [Decidable q] : Decidable (p ↔ q) :=
  if hp : p then
    if hq : q then
      isTrue ⟨fun _ => hq, fun _ => hp⟩
    else
      isFalse fun h => hq (h.1 hp)
  else
    if hq : q then
      isFalse fun h => hp (h.2 hq)
    else
      isTrue ⟨fun h => absurd h hp, fun h => absurd h hq⟩

/- if-then-else expression theorems -/

theorem ifPos {c : Prop} [h : Decidable c] (hc : c) {α : Sort u} {t e : α} : (ite c t e) = t :=
  match h with
  | (isTrue  hc)  => rfl
  | (isFalse hnc) => absurd hc hnc

theorem ifNeg {c : Prop} [h : Decidable c] (hnc : ¬c) {α : Sort u} {t e : α} : (ite c t e) = e :=
  match h with
  | (isTrue hc)   => absurd hc hnc
  | (isFalse hnc) => rfl

theorem difPos {c : Prop} [h : Decidable c] (hc : c) {α : Sort u} {t : c → α} {e : ¬ c → α} : (dite c t e) = t hc :=
  match h with
  | (isTrue  hc)  => rfl
  | (isFalse hnc) => absurd hc hnc

theorem difNeg {c : Prop} [h : Decidable c] (hnc : ¬c) {α : Sort u} {t : c → α} {e : ¬ c → α} : (dite c t e) = e hnc :=
  match h with
  | (isTrue hc)   => absurd hc hnc
  | (isFalse hnc) => rfl

-- Remark: dite and ite are "defally equal" when we ignore the proofs.
theorem difEqIf (c : Prop) [h : Decidable c] {α : Sort u} (t : α) (e : α) : dite c (fun h => t) (fun h => e) = ite c t e :=
  match h with
  | (isTrue hc)   => rfl
  | (isFalse hnc) => rfl

instance {c t e : Prop} [dC : Decidable c] [dT : Decidable t] [dE : Decidable e] : Decidable (if c then t else e)  :=
  match dC with
  | (isTrue hc)  => dT
  | (isFalse hc) => dE

instance {c : Prop} {t : c → Prop} {e : ¬c → Prop} [dC : Decidable c] [dT : ∀ h, Decidable (t h)] [dE : ∀ h, Decidable (e h)] : Decidable (if h : c then t h else e h)  :=
  match dC with
  | (isTrue hc)  => dT hc
  | (isFalse hc) => dE hc


/- Inhabited -/

instance : Inhabited Prop where
  default := True

deriving instance Inhabited for Bool, NonScalar, PNonScalar, True, ForInStep

class inductive Nonempty (α : Sort u) : Prop where
  | intro (val : α) : Nonempty α

protected def Nonempty.elim {α : Sort u} {p : Prop} (h₁ : Nonempty α) (h₂ : α → p) : p :=
  h₂ h₁.1

instance {α : Sort u} [Inhabited α] : Nonempty α where
  val := arbitrary

theorem nonemptyOfExists {α : Sort u} {p : α → Prop} : Exists (fun x => p x) → Nonempty α
  | ⟨w, h⟩ => ⟨w⟩

/- Subsingleton -/

class Subsingleton (α : Sort u) : Prop where
  intro ::
    allEq : (a b : α) → a = b

protected def Subsingleton.elim {α : Sort u} [h : Subsingleton α] : (a b : α) → a = b :=
  h.allEq

protected def Subsingleton.helim {α β : Sort u} [h₁ : Subsingleton α] (h₂ : α = β) (a : α) (b : β) : a ≅ b := by
  subst h₂
  apply heqOfEq
  apply Subsingleton.elim

instance (p : Prop) : Subsingleton p :=
  ⟨fun a b => proofIrrel a b⟩

instance (p : Prop) : Subsingleton (Decidable p) :=
  Subsingleton.intro fun
    | (isTrue t₁) => fun
      | (isTrue t₂)  => proofIrrel t₁ t₂ ▸ rfl
      | (isFalse f₂) => absurd t₁ f₂
    | (isFalse f₁) => fun
      | (isTrue t₂)  => absurd t₂ f₁
      | (isFalse f₂) => proofIrrel f₁ f₂ ▸ rfl

theorem recSubsingleton
     {p : Prop} [h : Decidable p]
     {h₁ : p → Sort u}
     {h₂ : ¬p → Sort u}
     [h₃ : ∀ (h : p), Subsingleton (h₁ h)]
     [h₄ : ∀ (h : ¬p), Subsingleton (h₂ h)]
     : Subsingleton (Decidable.casesOn (motive := fun _ => Sort u) h h₂ h₁) :=
  match h with
  | (isTrue h)  => h₃ h
  | (isFalse h) => h₄ h

structure Equivalence {α : Sort u} (r : α → α → Prop) : Prop where
  refl  : ∀ x, r x x
  symm  : ∀ {x y}, r x y → r y x
  trans : ∀ {x y z}, r x y → r y z → r x z

def emptyRelation {α : Sort u} (a₁ a₂ : α) : Prop :=
  False

def Subrelation {α : Sort u} (q r : α → α → Prop) :=
  ∀ {x y}, q x y → r x y

def InvImage {α : Sort u} {β : Sort v} (r : β → β → Prop) (f : α → β) : α → α → Prop :=
  fun a₁ a₂ => r (f a₁) (f a₂)

inductive TC {α : Sort u} (r : α → α → Prop) : α → α → Prop where
  | base  : ∀ a b, r a b → TC r a b
  | trans : ∀ a b c, TC r a b → TC r b c → TC r a c

/- Subtype -/

namespace Subtype
def existsOfSubtype {α : Type u} {p : α → Prop} : { x // p x } → Exists (fun x => p x)
  | ⟨a, h⟩ => ⟨a, h⟩

variable {α : Type u} {p : α → Prop}

protected theorem eq : ∀ {a1 a2 : {x // p x}}, val a1 = val a2 → a1 = a2
  | ⟨x, h1⟩, ⟨_, _⟩, rfl => rfl

theorem eta (a : {x // p x}) (h : p (val a)) : mk (val a) h = a := by
  cases a
  exact rfl

instance {α : Type u} {p : α → Prop} {a : α} (h : p a) : Inhabited {x // p x} where
  default := ⟨a, h⟩

instance {α : Type u} {p : α → Prop} [DecidableEq α] : DecidableEq {x : α // p x} :=
  fun ⟨a, h₁⟩ ⟨b, h₂⟩ =>
    if h : a = b then isTrue (by subst h; exact rfl)
    else isFalse (fun h' => Subtype.noConfusion h' (fun h' => absurd h' h))

end Subtype

/- Sum -/

section
variable {α : Type u} {β : Type v}

instance Sum.inhabitedLeft [h : Inhabited α] : Inhabited (Sum α β) where
  default := Sum.inl arbitrary

instance Sum.inhabitedRight [h : Inhabited β] : Inhabited (Sum α β) where
  default := Sum.inr arbitrary

instance {α : Type u} {β : Type v} [DecidableEq α] [DecidableEq β] : DecidableEq (Sum α β) := fun a b =>
  match a, b with
  | (Sum.inl a), (Sum.inl b) =>
    if h : a = b then isTrue (h ▸ rfl)
    else isFalse (fun h' => Sum.noConfusion h' (fun h' => absurd h' h))
  | (Sum.inr a), (Sum.inr b) =>
    if h : a = b then isTrue (h ▸ rfl)
    else isFalse (fun h' => Sum.noConfusion h' (fun h' => absurd h' h))
  | (Sum.inr a), (Sum.inl b) => isFalse (fun h => Sum.noConfusion h)
  | (Sum.inl a), (Sum.inr b) => isFalse (fun h => Sum.noConfusion h)

end

/- Product -/

section
variable {α : Type u} {β : Type v}

instance [Inhabited α] [Inhabited β] : Inhabited (α × β) where
  default := (arbitrary, arbitrary)

instance [DecidableEq α] [DecidableEq β] : DecidableEq (α × β) :=
  fun ⟨a, b⟩ ⟨a', b'⟩ =>
    match (decEq a a') with
    | (isTrue e₁) =>
      match (decEq b b') with
      | (isTrue e₂)  => isTrue (e₁ ▸ e₂ ▸ rfl)
      | (isFalse n₂) => isFalse (fun h => Prod.noConfusion h (fun e₁' e₂' => absurd e₂' n₂))
    | (isFalse n₁) => isFalse (fun h => Prod.noConfusion h (fun e₁' e₂' => absurd e₁' n₁))

instance [BEq α] [BEq β] : BEq (α × β) where
  beq := fun ⟨a₁, b₁⟩ ⟨a₂, b₂⟩ => a₁ == a₂ && b₁ == b₂

instance [HasLess α] [HasLess β] : HasLess (α × β) where
  Less s t := s.1 < t.1 ∨ (s.1 = t.1 ∧ s.2 < t.2)

instance prodHasDecidableLt
    [HasLess α] [HasLess β] [DecidableEq α] [DecidableEq β]
    [(a b : α) → Decidable (a < b)] [(a b : β) → Decidable (a < b)]
    : (s t : α × β) → Decidable (s < t) :=
  fun t s => inferInstanceAs (Decidable (_ ∨ _))

theorem Prod.ltDef [HasLess α] [HasLess β] (s t : α × β) : (s < t) = (s.1 < t.1 ∨ (s.1 = t.1 ∧ s.2 < t.2)) :=
  rfl
end

def Prod.map.{u₁, u₂, v₁, v₂} {α₁ : Type u₁} {α₂ : Type u₂} {β₁ : Type v₁} {β₂ : Type v₂}
    (f : α₁ → α₂) (g : β₁ → β₂) : α₁ × β₁ → α₂ × β₂
  | (a, b) => (f a, g b)

/- Dependent products -/

theorem exOfPsig {α : Type u} {p : α → Prop} : (PSigma (fun x => p x)) → Exists (fun x => p x)
  | ⟨x, hx⟩ => ⟨x, hx⟩

protected theorem PSigma.eta {α : Sort u} {β : α → Sort v} {a₁ a₂ : α} {b₁ : β a₁} {b₂ : β a₂}
    (h₁ : a₁ = a₂) (h₂ : Eq.ndrec b₁ h₁ = b₂) : PSigma.mk a₁ b₁ = PSigma.mk a₂ b₂ := by
  subst h₁
  subst h₂
  exact rfl

/- Universe polymorphic unit -/

theorem punitEq (a b : PUnit) : a = b := by
  cases a; cases b; exact rfl

theorem punitEqPUnit (a : PUnit) : a = () :=
  punitEq a ()

instance : Subsingleton PUnit :=
  Subsingleton.intro punitEq

instance : Inhabited PUnit where
  default := ⟨⟩

instance : DecidableEq PUnit :=
  fun a b => isTrue (punitEq a b)

/- Setoid -/

class Setoid (α : Sort u) where
  r : α → α → Prop
  iseqv {} : Equivalence r

instance {α : Sort u} [Setoid α] : HasEquiv α :=
  ⟨Setoid.r⟩

namespace Setoid

variable {α : Sort u} [Setoid α]

theorem refl (a : α) : a ≈ a :=
  (Setoid.iseqv α).refl a

theorem symm {a b : α} (hab : a ≈ b) : b ≈ a :=
  (Setoid.iseqv α).symm hab

theorem trans {a b c : α} (hab : a ≈ b) (hbc : b ≈ c) : a ≈ c :=
  (Setoid.iseqv α).trans hab hbc

end Setoid


/- Propositional extensionality -/

axiom propext {a b : Prop} : (a ↔ b) → a = b

/- Quotients -/

-- Iff can now be used to do substitutions in a calculation
theorem iffSubst {a b : Prop} {p : Prop → Prop} (h₁ : a ↔ b) (h₂ : p a) : p b :=
  Eq.subst (propext h₁) h₂

namespace Quot
axiom sound : ∀ {α : Sort u} {r : α → α → Prop} {a b : α}, r a b → Quot.mk r a = Quot.mk r b

protected theorem liftBeta {α : Sort u} {r : α → α → Prop} {β : Sort v}
    (f : α → β)
    (c : (a b : α) → r a b → f a = f b)
    (a : α)
    : lift f c (Quot.mk r a) = f a :=
  rfl

protected theorem indBeta {α : Sort u} {r : α → α → Prop} {motive : Quot r → Prop}
    (p : (a : α) → motive (Quot.mk r a))
    (a : α)
    : (ind p (Quot.mk r a) : motive (Quot.mk r a)) = p a :=
  rfl

protected abbrev liftOn {α : Sort u} {β : Sort v} {r : α → α → Prop} (q : Quot r) (f : α → β) (c : (a b : α) → r a b → f a = f b) : β :=
  lift f c q

protected theorem inductionOn {α : Sort u} {r : α → α → Prop} {motive : Quot r → Prop}
    (q : Quot r)
    (h : (a : α) → motive (Quot.mk r a))
    : motive q :=
  ind h q

theorem existsRep {α : Sort u} {r : α → α → Prop} (q : Quot r) : Exists (fun a => (Quot.mk r a) = q) :=
  Quot.inductionOn (motive := fun q => Exists (fun a => (Quot.mk r a) = q)) q (fun a => ⟨a, rfl⟩)

section
variable {α : Sort u}
variable {r : α → α → Prop}
variable {motive : Quot r → Sort v}

@[reducible, macroInline]
protected def indep (f : (a : α) → motive (Quot.mk r a)) (a : α) : PSigma motive :=
  ⟨Quot.mk r a, f a⟩

protected theorem indepCoherent
    (f : (a : α) → motive (Quot.mk r a))
    (h : (a b : α) → (p : r a b) → Eq.ndrec (f a) (sound p) = f b)
    : (a b : α) → r a b → Quot.indep f a = Quot.indep f b  :=
  fun a b e => PSigma.eta (sound e) (h a b e)

protected theorem liftIndepPr1
    (f : (a : α) → motive (Quot.mk r a))
    (h : ∀ (a b : α) (p : r a b), Eq.ndrec (f a) (sound p) = f b)
    (q : Quot r)
    : (lift (Quot.indep f) (Quot.indepCoherent f h) q).1 = q := by
 induction q using Quot.ind
 exact rfl

protected abbrev rec
    (f : (a : α) → motive (Quot.mk r a))
    (h : (a b : α) → (p : r a b) → Eq.ndrec (f a) (sound p) = f b)
    (q : Quot r) : motive q :=
  Eq.ndrecOn (Quot.liftIndepPr1 f h q) ((lift (Quot.indep f) (Quot.indepCoherent f h) q).2)

protected abbrev recOn
    (q : Quot r)
    (f : (a : α) → motive (Quot.mk r a))
    (h : (a b : α) → (p : r a b) → Eq.ndrec (f a) (sound p) = f b)
    : motive q :=
 Quot.rec f h q

protected abbrev recOnSubsingleton
    [h : (a : α) → Subsingleton (motive (Quot.mk r a))]
    (q : Quot r)
    (f : (a : α) → motive (Quot.mk r a))
    : motive q := by
  induction q using Quot.rec
  apply f
  apply Subsingleton.elim

protected abbrev hrecOn
    (q : Quot r)
    (f : (a : α) → motive (Quot.mk r a))
    (c : (a b : α) → (p : r a b) → f a ≅ f b)
    : motive q :=
  Quot.recOn q f fun a b p => eqOfHEq <|
    have p₁ : Eq.ndrec (f a) (sound p) ≅ f a := eqRecHEq (sound p) (f a)
    HEq.trans p₁ (c a b p)

end
end Quot

def Quotient {α : Sort u} (s : Setoid α) :=
  @Quot α Setoid.r

namespace Quotient

@[inline]
protected def mk {α : Sort u} [s : Setoid α] (a : α) : Quotient s :=
  Quot.mk Setoid.r a

def sound {α : Sort u} [s : Setoid α] {a b : α} : a ≈ b → Quotient.mk a = Quotient.mk b :=
  Quot.sound

protected abbrev lift {α : Sort u} {β : Sort v} [s : Setoid α] (f : α → β) : ((a b : α) → a ≈ b → f a = f b) → Quotient s → β :=
  Quot.lift f

protected theorem ind {α : Sort u} [s : Setoid α] {motive : Quotient s → Prop} : ((a : α) → motive (Quotient.mk a)) → (q : Quot Setoid.r) → motive q :=
  Quot.ind

protected abbrev liftOn {α : Sort u} {β : Sort v} [s : Setoid α] (q : Quotient s) (f : α → β) (c : (a b : α) → a ≈ b → f a = f b) : β :=
  Quot.liftOn q f c

protected theorem inductionOn {α : Sort u} [s : Setoid α] {motive : Quotient s → Prop}
    (q : Quotient s)
    (h : (a : α) → motive (Quotient.mk a))
    : motive q :=
  Quot.inductionOn q h

theorem existsRep {α : Sort u} [s : Setoid α] (q : Quotient s) : Exists (fun (a : α) => Quotient.mk a = q) :=
  Quot.existsRep q

section
variable {α : Sort u}
variable [s : Setoid α]
variable {motive : Quotient s → Sort v}

@[inline]
protected def rec
    (f : (a : α) → motive (Quotient.mk a))
    (h : (a b : α) → (p : a ≈ b) → Eq.ndrec (f a) (Quotient.sound p) = f b)
    (q : Quotient s)
    : motive q :=
  Quot.rec f h q

protected abbrev recOn
    (q : Quotient s)
    (f : (a : α) → motive (Quotient.mk a))
    (h : (a b : α) → (p : a ≈ b) → Eq.ndrec (f a) (Quotient.sound p) = f b)
    : motive q :=
  Quot.recOn q f h

protected abbrev recOnSubsingleton
    [h : (a : α) → Subsingleton (motive (Quotient.mk a))]
    (q : Quotient s)
    (f : (a : α) → motive (Quotient.mk a))
    : motive q :=
  Quot.recOnSubsingleton (h := h) q f

protected abbrev hrecOn
    (q : Quotient s)
    (f : (a : α) → motive (Quotient.mk a))
    (c : (a b : α) → (p : a ≈ b) → f a ≅ f b)
    : motive q :=
  Quot.hrecOn q f c
end

section
universes uA uB uC
variable {α : Sort uA} {β : Sort uB} {φ : Sort uC}
variable [s₁ : Setoid α] [s₂ : Setoid β]

protected abbrev lift₂
    (f : α → β → φ)
    (c : (a₁ : α) → (b₁ : β) → (a₂ : α) → (b₂ : β) → a₁ ≈ a₂ → b₁ ≈ b₂ → f a₁ b₁ = f a₂ b₂)
    (q₁ : Quotient s₁) (q₂ : Quotient s₂)
    : φ := by
  apply Quotient.lift (fun (a₁ : α) => Quotient.lift (f a₁) (fun (a b : β) => c a₁ a a₁ b (Setoid.refl a₁)) q₂) _ q₁
  intros
  induction q₂ using Quotient.ind
  apply c; assumption; apply Setoid.refl

protected abbrev liftOn₂
    (q₁ : Quotient s₁)
    (q₂ : Quotient s₂)
    (f : α → β → φ)
    (c : (a₁ : α) → (b₁ : β) → (a₂ : α) → (b₂ : β) → a₁ ≈ a₂ → b₁ ≈ b₂ → f a₁ b₁ = f a₂ b₂)
    : φ :=
  Quotient.lift₂ f c q₁ q₂

protected theorem ind₂
    {motive : Quotient s₁ → Quotient s₂ → Prop}
    (h : (a : α) → (b : β) → motive (Quotient.mk a) (Quotient.mk b))
    (q₁ : Quotient s₁)
    (q₂ : Quotient s₂)
    : motive q₁ q₂ := by
  induction q₁ using Quotient.ind
  induction q₂ using Quotient.ind
  apply h

protected theorem inductionOn₂
    {motive : Quotient s₁ → Quotient s₂ → Prop}
    (q₁ : Quotient s₁)
    (q₂ : Quotient s₂)
    (h : (a : α) → (b : β) → motive (Quotient.mk a) (Quotient.mk b))
    : motive q₁ q₂ := by
  induction q₁ using Quotient.ind
  induction q₂ using Quotient.ind
  apply h

protected theorem inductionOn₃
    [s₃ : Setoid φ]
    {motive : Quotient s₁ → Quotient s₂ → Quotient s₃ → Prop}
    (q₁ : Quotient s₁)
    (q₂ : Quotient s₂)
    (q₃ : Quotient s₃)
    (h : (a : α) → (b : β) → (c : φ) → motive (Quotient.mk a) (Quotient.mk b) (Quotient.mk c))
    : motive q₁ q₂ q₃ := by
  induction q₁ using Quotient.ind
  induction q₂ using Quotient.ind
  induction q₃ using Quotient.ind
  apply h

end

section Exact

variable   {α : Sort u}

private def rel [s : Setoid α] (q₁ q₂ : Quotient s) : Prop :=
  Quotient.liftOn₂ q₁ q₂
    (fun a₁ a₂ => a₁ ≈ a₂)
    (fun a₁ a₂ b₁ b₂ a₁b₁ a₂b₂ =>
      propext (Iff.intro
        (fun a₁a₂ => Setoid.trans (Setoid.symm a₁b₁) (Setoid.trans a₁a₂ a₂b₂))
        (fun b₁b₂ => Setoid.trans a₁b₁ (Setoid.trans b₁b₂ (Setoid.symm a₂b₂)))))

private theorem rel.refl [s : Setoid α] (q : Quotient s) : rel q q :=
  Quot.inductionOn (motive := fun q => rel q q) q (fun a => Setoid.refl a)

private theorem eqImpRel [s : Setoid α] {q₁ q₂ : Quotient s} : q₁ = q₂ → rel q₁ q₂ :=
  fun h => Eq.ndrecOn h (rel.refl q₁)

theorem exact [s : Setoid α] {a b : α} : Quotient.mk a = Quotient.mk b → a ≈ b :=
  fun h => eqImpRel h

end Exact

section
universes uA uB uC
variable {α : Sort uA} {β : Sort uB}
variable [s₁ : Setoid α] [s₂ : Setoid β]

protected abbrev recOnSubsingleton₂
    {motive : Quotient s₁ → Quotient s₂ → Sort uC}
    [s : (a : α) → (b : β) → Subsingleton (motive (Quotient.mk a) (Quotient.mk b))]
    (q₁ : Quotient s₁)
    (q₂ : Quotient s₂)
    (g : (a : α) → (b : β) → motive (Quotient.mk a) (Quotient.mk b))
    : motive q₁ q₂ := by
  induction q₁ using Quot.recOnSubsingleton
  induction q₂ using Quot.recOnSubsingleton
  intro a; apply s
  induction q₂ using Quot.recOnSubsingleton
  intro a; apply s
  apply g

end
end Quotient

section
variable {α : Type u}
variable (r : α → α → Prop)

instance {α : Sort u} {s : Setoid α} [d : ∀ (a b : α), Decidable (a ≈ b)] : DecidableEq (Quotient s) :=
  fun (q₁ q₂ : Quotient s) =>
    Quotient.recOnSubsingleton₂ (motive := fun a b => Decidable (a = b)) q₁ q₂
      (fun a₁ a₂ =>
        match (d a₁ a₂) with
        | (isTrue h₁)  => isTrue (Quotient.sound h₁)
        | (isFalse h₂) => isFalse (fun h => absurd (Quotient.exact h) h₂))

/- Function extensionality -/

namespace Function
variable {α : Sort u} {β : α → Sort v}

def Equiv (f₁ f₂ : ∀ (x : α), β x) : Prop := ∀ x, f₁ x = f₂ x

protected theorem Equiv.refl (f : ∀ (x : α), β x) : Equiv f f :=
  fun x => rfl

protected theorem Equiv.symm {f₁ f₂ : ∀ (x : α), β x} : Equiv f₁ f₂ → Equiv f₂ f₁ :=
  fun h x => Eq.symm (h x)

protected theorem Equiv.trans {f₁ f₂ f₃ : ∀ (x : α), β x} : Equiv f₁ f₂ → Equiv f₂ f₃ → Equiv f₁ f₃ :=
  fun h₁ h₂ x => Eq.trans (h₁ x) (h₂ x)

protected theorem Equiv.isEquivalence (α : Sort u) (β : α → Sort v) : Equivalence (@Function.Equiv α β) := {
  refl := Equiv.refl,
  symm := Equiv.symm,
  trans := Equiv.trans
}

end Function

section
open Quotient
variable {α : Sort u} {β : α → Sort v}

@[instance]
private def funSetoid (α : Sort u) (β : α → Sort v) : Setoid (∀ (x : α), β x) :=
  Setoid.mk (@Function.Equiv α β) (Function.Equiv.isEquivalence α β)

private def extfunApp (f : Quotient <| funSetoid α β) (x : α) : β x :=
  Quot.liftOn f
    (fun (f : ∀ (x : α), β x) => f x)
    (fun f₁ f₂ h => h x)

theorem funext {f₁ f₂ : ∀ (x : α), β x} (h : ∀ x, f₁ x = f₂ x) : f₁ = f₂ := by
  show extfunApp (Quotient.mk f₁) = extfunApp (Quotient.mk f₂)
  apply congrArg
  apply Quotient.sound
  exact h

end

instance {α : Sort u} {β : α → Sort v} [∀ a, Subsingleton (β a)] : Subsingleton (∀ a, β a) :=
  ⟨fun f₁ f₂ => funext (fun a => Subsingleton.elim (f₁ a) (f₂ a))⟩

/- Squash -/

def Squash (α : Type u) := Quot (fun (a b : α) => True)

def Squash.mk {α : Type u} (x : α) : Squash α := Quot.mk _ x

theorem Squash.ind {α : Type u} {motive : Squash α → Prop} (h : ∀ (a : α), motive (Squash.mk a)) : ∀ (q : Squash α), motive q :=
  Quot.ind h

@[inline] def Squash.lift {α β} [Subsingleton β] (s : Squash α) (f : α → β) : β :=
  Quot.lift f (fun a b _ => Subsingleton.elim _ _) s

instance {α} : Subsingleton (Squash α) := ⟨fun a b =>
  Squash.ind (motive := fun a => a = b)
    (fun a => Squash.ind (motive := fun b => Squash.mk a = b)
      (fun b => show Quot.mk _ a = Quot.mk _ b by apply Quot.sound; exact trivial)
      b)
    a⟩

namespace Lean
/- Kernel reduction hints -/

/--
  When the kernel tries to reduce a term `Lean.reduceBool c`, it will invoke the Lean interpreter to evaluate `c`.
  The kernel will not use the interpreter if `c` is not a constant.
  This feature is useful for performing proofs by reflection.

  Remark: the Lean frontend allows terms of the from `Lean.reduceBool t` where `t` is a term not containing
  free variables. The frontend automatically declares a fresh auxiliary constant `c` and replaces the term with
  `Lean.reduceBool c`. The main motivation is that the code for `t` will be pre-compiled.

  Warning: by using this feature, the Lean compiler and interpreter become part of your trusted code base.
  This is extra 30k lines of code. More importantly, you will probably not be able to check your developement using
  external type checkers (e.g., Trepplein) that do not implement this feature.
  Keep in mind that if you are using Lean as programming language, you are already trusting the Lean compiler and interpreter.
  So, you are mainly losing the capability of type checking your developement using external checkers.

  Recall that the compiler trusts the correctness of all `[implementedBy ...]` and `[extern ...]` annotations.
  If an extern function is executed, then the trusted code base will also include the implementation of the associated
  foreign function.
-/
constant reduceBool (b : Bool) : Bool := b

/--
  Similar to `Lean.reduceBool` for closed `Nat` terms.

  Remark: we do not have plans for supporting a generic `reduceValue {α} (a : α) : α := a`.
  The main issue is that it is non-trivial to convert an arbitrary runtime object back into a Lean expression.
  We believe `Lean.reduceBool` enables most interesting applications (e.g., proof by reflection). -/
constant reduceNat (n : Nat) : Nat := n

axiom ofReduceBool (a b : Bool) (h : reduceBool a = b) : a = b
axiom ofReduceNat (a b : Nat) (h : reduceNat a = b)    : a = b

end Lean
