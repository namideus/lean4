open List Nat

attribute [grind] List.getElem_cons_zero

theorem getElem_cons {l : List α} (w : i < (a :: l).length) :
    (a :: l)[i] =
      if h : i = 0 then a else l[i-1]'(match i, h with | i+1, _ => succ_lt_succ_iff.mp w) := by
  split
  · -- Fails with:
    -- [grind] Issues ▼
    --   [issue] type error constructing proof for getElem_cons_zero
    --       when assigning metavariable ?h with
    --         ‹i < (a :: l).length›
    --       has type
    --         i < (a :: l).length : Prop
    --       but is expected to have type
    --         0 < (a :: l).length : Prop
    grind
  · sorry

attribute [grind] List.filter_nil List.filter_cons
attribute [grind] List.any_nil List.any_cons

@[simp] theorem any_filter {l : List α} {p q : α → Bool} :
    (filter p l).any q = l.any fun a => p a && q a := by
  induction l <;> grind
  -- Fails at:
  -- [grind] Goal diagnostics ▼
  -- [facts] Asserted facts ▼
  --   [prop] (filter p tail).any q = tail.any fun a => p a && q a
  --   [prop] ¬(filter p (head :: tail)).any q = (head :: tail).any fun a => p a && q a
  --   [prop] filter p (head :: tail) = if p head = true then head :: filter p tail else filter p tail
  --   [prop] ((head :: tail).any fun a => p a && q a) = (p head && q head || tail.any fun a => p a && q a)
  --   [prop] ¬p head = true
  -- [eqc] False propositions ▼
  --   [prop] (filter p (head :: tail)).any q = (head :: tail).any fun a => p a && q a
  --   [prop] p head = true
  -- [eqc] Equivalence classes ▼
  --   [] {(head :: tail).any fun a => p a && q a, p head && q head || tail.any fun a => p a && q a}
  --   [] {filter p (head :: tail), filter p tail, if p head = true then head :: filter p tail else filter p tail}
  --   [] {(filter p tail).any q, (filter p (head :: tail)).any q, tail.any fun a => p a && q a}
  -- Despite knowing that `p head = false`, grind doesn't see that
  -- `p head && q head || tail.any fun a => p a && q a = tail.any fun a => p a && q a`,
  -- which should finish the problem.

attribute [grind] List.replace_cons
grind_pattern LawfulBEq.rfl => a == a

@[simp] theorem replace_cons_self [BEq α] [LawfulBEq α] {a : α} : (a::as).replace a b = b::as := by grind
-- Fails with:
-- [grind] Issues ▼
--   [issue] failed to synthesize instance when instantiating LawfulBEq.rfl
--         LawfulBEq α
