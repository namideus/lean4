/-
Copyright (c) 2017 Microsoft Corporation. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Leonardo de Moura
-/
prelude
import init.data.ordering.basic init.meta init.algebra.classes init.ite_simp
set_option default_priority 100

universes u

namespace ordering
/- Delete the following simp lemmas as soon as we improve the simplifier. -/
@[simp] lemma lt_ne_eq : ordering.lt ≠ ordering.eq :=
by contradiction

@[simp] lemma lt_ne_gt : ordering.lt ≠ ordering.gt :=
by contradiction

@[simp] lemma eq_ne_lt : ordering.eq ≠ ordering.lt :=
by contradiction

@[simp] lemma eq_ne_gt : ordering.eq ≠ ordering.gt :=
by contradiction

@[simp] lemma gt_ne_lt : ordering.gt ≠ ordering.lt :=
by contradiction

@[simp] lemma gt_ne_eq : ordering.gt ≠ ordering.eq :=
by contradiction

@[simp] theorem ite_eq_lt_distrib (c : Prop) [decidable c] (a b : ordering) : ((if c then a else b) = ordering.lt) = (if c then a = ordering.lt else b = ordering.lt) :=
by by_cases c with h; simp [h]

@[simp] theorem ite_eq_eq_distrib (c : Prop) [decidable c] (a b : ordering) : ((if c then a else b) = ordering.eq) = (if c then a = ordering.eq else b = ordering.eq) :=
by by_cases c with h; simp [h]

@[simp] theorem ite_eq_gt_distrib (c : Prop) [decidable c] (a b : ordering) : ((if c then a else b) = ordering.gt) = (if c then a = ordering.gt else b = ordering.gt) :=
by by_cases c with h; simp [h]

/- ------------------------------------------------------------------ -/
end ordering

section
variables {α : Type u} {lt : α → α → Prop} [decidable_rel lt]

local attribute [simp] cmp_using

@[simp] lemma cmp_using_eq_lt (a b : α) : (cmp_using lt a b = ordering.lt) = lt a b :=
by simp

@[simp] lemma cmp_using_eq_gt [is_strict_order α lt] (a b : α) : (cmp_using lt a b = ordering.gt) = lt b a :=
begin
  simp, apply propext, apply iff.intro,
  { exact λ h, h.1 },
  { intro hba, split, assumption, intro hab, exact absurd (trans hab hba) (irrefl a) }
end

@[simp] lemma cmp_using_eq_eq (a b : α) : (cmp_using lt a b = ordering.eq) = (¬ lt a b ∧ ¬ lt b a) :=
by simp

end
