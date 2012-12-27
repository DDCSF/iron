(* System-F2.
   With region and effect types. *)

(* Kinds and kind environemnts. *)
Require Export Iron.Language.SystemF2Effect.Ki.

(* Type constructors. *)
Require Export Iron.Language.SystemF2Effect.TyCon.

(* Type expressions, and functions that operate on them *)
Require Export Iron.Language.SystemF2Effect.TyExp.

(* Well formedness of type expressions. *)
Require Export Iron.Language.SystemF2Effect.TyWfT.

(* Lifting of indices in type expressions. *)
Require Export Iron.Language.SystemF2Effect.TyLift.

(* Substitution of types in types. *)
Require Export Iron.Language.SystemF2Effect.TySubst.

(* All of the types modules. *)
Require Export Iron.Language.SystemF2Effect.Ty.

(* Kinds of Types. *)
Require Export Iron.Language.SystemF2Effect.KiJudge.

(* Substitution of types in types preserves kinding *)
Require Export Iron.Language.SystemF2Effect.SubstTypeType.

(* Type environments. *)
Require Export Iron.Language.SystemF2Effect.TyEnv.

(* Value expressions. *)
Require Export Iron.Language.SystemF2Effect.VaExpBase.

(* Lifting of type and expression indices in expressions. *)
Require Export Iron.Language.SystemF2Effect.VaExpLift.

(* Well-formedness of expessions. *)
Require Export Iron.Language.SystemF2Effect.VaExpWfX.

(* Lifting of type and value indices in expressions. *)
Require Export Iron.Language.SystemF2Effect.VaExpLift.

(* Substitution of types and values into expressions. *)
Require Export Iron.Language.SystemF2Effect.VaExpSubst.

(* All of the value modules. *)
Require Export Iron.Language.SystemF2Effect.Va.

(* Type judgements *)
Require Export Iron.Language.SystemF2Effect.TyJudge.

(* Substitution of types into expressions. *)
Require Export Iron.Language.SystemF2Effect.SubstTypeExp.

(* Substitution of values into expressions preserves typing. *)
Require Export Iron.Language.SystemF2Effect.SubstValExp.

(* Store definition *)
Require Export Iron.Language.SystemF2Effect.Store.

(* Single Step Evaluation *)
Require Export Iron.Language.SystemF2Effect.Step.

(* Progress theorem *)
Require Export Iron.Language.SystemF2Effect.Progress.

