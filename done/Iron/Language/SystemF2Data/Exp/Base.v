
Require Export Iron.Language.SystemF2Data.Type.


(* Expressions *)
Inductive exp : Type :=
 (* Functions *)
 | XVar   : nat -> exp
 | XLAM   : exp -> exp              (* type abstraction *)
 | XAPP   : exp -> ty  -> exp       (* type application *)
 | XLam   : ty  -> exp -> exp       (* function abstraction *)
 | XApp   : exp -> exp -> exp       (* function application *)

 (* Data Types *)
 | XCon   : datacon -> list ty -> list exp -> exp
 | XCase  : exp     -> list alt -> exp

 (* Alternatives *)
with alt     : Type :=
 | AAlt   : datacon -> exp -> alt.

Hint Constructors exp.
Hint Constructors alt.


(********************************************************************)
(* Mutual induction principle for expressions.
   As expressions are indirectly mutually recursive with lists,
   Coq's Combined scheme command won't make us a strong enough
   induction principle, so we need to write it out by hand. *)
Theorem exp_mutind
 : forall 
    (PX : exp -> Prop)
    (PA : alt -> Prop)
 ,  (forall n,                                PX (XVar n))
 -> (forall x1,      PX x1                 -> PX (XLAM x1))
 -> (forall x1 t2,   PX x1                 -> PX (XAPP x1 t2))
 -> (forall t  x1,   PX x1                 -> PX (XLam t x1))
 -> (forall x1 x2,   PX x1 -> PX x2        -> PX (XApp x1 x2))
 -> (forall dc ts xs,         Forall PX xs -> PX (XCon dc ts xs))
 -> (forall x  aa,   PX x  -> Forall PA aa -> PX (XCase x aa))
 -> (forall dc x,    PX x                  -> PA (AAlt dc x))
 ->  forall x, PX x.
Proof. 
 intros PX PA.
 intros var tlam tapp lam app con case alt.
 refine (fix  IHX x : PX x := _
         with IHA a : PA a := _
         for  IHX).

 (* expressions *)
 case x; intros.

 Case "XVar".
  apply var.

 Case "XLAM".
  apply tlam. 
   apply IHX.

 Case "XAPP".
  apply tapp.
   apply IHX.
 
 Case "XLam".
  apply lam. 
   apply IHX.

 Case "XApp".
  apply app. 
   apply IHX.
   apply IHX.

 Case "XCon".
  apply con.
   induction l0; intuition.

 Case "XCase".
  apply case.
   apply IHX.
   induction l; intuition.

 (* alternatives *)
 case a; intros.

 Case "XAlt".
  apply alt.
   apply IHX.
Qed.
