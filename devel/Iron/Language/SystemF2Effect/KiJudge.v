
Require Export Iron.Language.SystemF2Effect.TyLift.
Require Export Iron.Language.SystemF2Effect.TyWfT.
Require Export Iron.Language.SystemF2Effect.TyExp.


(* Only types of effect and closure kinds can be used in sums. *)
Definition sumkind (k : ki) : Prop
 := k = KEffect.
Hint Unfold sumkind.

(* Region kinds cannot be the result of type applications. *)
Definition appkind (k : ki) : Prop
 := ~ (k = KRegion).
Hint Unfold appkind.

(* Kinds judgement assigns a kind to a type *)
Inductive KIND : kienv -> ty -> ki -> Prop :=
  | KICon
    :  forall ke tc k
    ,  k = kindOfTyCon tc
    -> KIND ke (TCon tc) k

  | KIVar
    :  forall ke i k
    ,  get i ke = Some k
    -> KIND ke (TVar i) k

  | KIForall
    :  forall ke k t
    ,  KIND (ke :> k) t             KData
    -> KIND ke        (TForall k t) KData

  | KIApp 
    :  forall ke t1 t2 k11 k12
    ,  appkind k12
    -> KIND ke t1 (KFun k11 k12)
    -> KIND ke t2 k11
    -> KIND ke (TApp t1 t2) k12

  | KISum
    :  forall ke k t1 t2
    ,  sumkind k
    -> KIND ke t1 k -> KIND ke t2 k
    -> KIND ke (TSum t1 t2) k

  | KIBot
    :  forall ke k
    ,  sumkind k
    -> KIND ke (TBot k) k.

Hint Constructors KIND.


(* Invert all hypothesis that are compound kinding statements. *)
Ltac inverts_kind :=
 repeat 
  (match goal with 
   | [ H: KIND _ (TCon _)    _   |- _ ] => inverts H
   | [ H: KIND _ (TVar _)    _   |- _ ] => inverts H
   | [ H: KIND _ (TForall _ _) _ |- _ ] => inverts H
   | [ H: KIND _ (TApp _ _) _    |- _ ] => inverts H
   | [ H: KIND _ (TSum _ _) _    |- _ ] => inverts H
   | [ H: KIND _ (TBot _ ) _     |- _ ] => inverts H
   end).


(********************************************************************)
(* A well kinded type is well formed *)
Lemma kind_wfT
 :  forall ke t k
 ,  KIND ke t k
 -> wfT  (length ke) t.
Proof.
 intros ke t k HK. gen ke k.
 induction t; intros; inverts_kind; burn.
 lets D: IHt H3. burn.
Qed.
Hint Resolve kind_wfT.


Lemma kind_wfT_Forall
 :  forall ks k ts
 ,  Forall (fun t => KIND ks t k) ts
 -> Forall (wfT (length ks)) ts.
Proof.
 intros. nforall. eauto.
Qed.
Hint Resolve kind_wfT_Forall.


Lemma kind_wfT_Forall2
 :  forall (ke: kienv) ts ks
 ,  Forall2 (KIND ke) ts ks
 -> Forall (wfT (length ke)) ts.
Proof.
 intros.
 eapply (Forall2_Forall_left (KIND ke)); burn.
Qed.
Hint Resolve kind_wfT_Forall2.


(********************************************************************)
(* Forms of types *)
Lemma kind_region
 :  forall t
 ,  KIND nil t KRegion
 -> (exists n, t = TCon (TyConRegion n)).
Proof.
 intros.
 destruct t; burn.

  inverts H.
  destruct t; burn.

  inverts H.
  unfold appkind in *.
  false. auto.
Qed.
Hint Resolve kind_region.


(********************************************************************)
(* If a type is well kinded in an empty environment,
   then that type is closed. *)
Lemma kind_empty_is_closed
 :  forall t k
 ,  KIND nil t k 
 -> closedT t.
Proof.
 intros. unfold closedT.
 have (@length ki nil = 0).
  rewrite <- H0.
  eapply kind_wfT. eauto.
Qed.
Hint Resolve kind_empty_is_closed.


(********************************************************************)
(* Weakening kind environments. *)
Lemma kind_kienv_insert
 :  forall ke ix t k1 k2
 ,  KIND ke t k1
 -> KIND (insert ix k2 ke) (liftTT 1 ix t) k1.
Proof.
 intros. gen ix ke k1.
 induction t; intros; simpl; inverts_kind; eauto.

 Case "TVar".
  lift_cases; intros; norm; auto.

 Case "TForall".
  apply KIForall.
  rewrite insert_rewind. auto.
Qed.


Lemma kind_kienv_weaken
 :  forall ke t k1 k2
 ,  KIND  ke         t             k1
 -> KIND (ke :> k2) (liftTT 1 0 t) k1.
Proof.
 intros.
 rrwrite (ke :> k2 = insert 0 k2 ke).
 apply kind_kienv_insert. auto.
Qed.

