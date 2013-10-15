
Require Export Iron.Language.SystemF2Effect.Kind.


(* Type level capabilities *)
Inductive tycap : Type :=
 (* The region capability, also called a 'region handle'. 
    When one of these exists in the program we know there is a
    corresponding region in the store. *)
 | TyCapRegion   : nat -> tycap.

Hint Constructors tycap.


(* Check if two capabilities are equal. *)
Fixpoint EqTyCap (tc1 : tycap) (tc2 : tycap) : Prop :=
 match tc1, tc2 with
 | TyCapRegion n1, TyCapRegion n2 => n1 = n2
 end.

