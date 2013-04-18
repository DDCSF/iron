
Require Export Iron.Language.SystemF2Data.Type.
Require Export Iron.Language.SystemF2Data.Exp.Base.
Require Export Iron.Language.SystemF2Data.Exp.Alt.
Require Export Iron.Language.SystemF2Data.Exp.Relation.WfX.
Require Export Iron.Language.SystemF2Data.Exp.Relation.WnfX.
Require Export Iron.Language.SystemF2Data.Exp.Operator.LiftTX.
Require Export Iron.Language.SystemF2Data.Exp.Operator.LiftXX.


(* Builtin in types. *)
Definition tUnit 
 := makeTApps (TCon tcUnit) nil.

Definition tFun (t1: ty) (t2: ty)
 := TApp (TApp (TCon TyConFun) t1) t2.
Hint Unfold tFun.


(* Type Judgement assigns a type to an expression. *)
Inductive TYPE (ds: defs) (ke: kienv) (te: tyenv) : exp -> ty -> Prop :=
 (* Variables *)
 | TYVar 
   :  forall i t
   ,  get i te = Some t
   -> TYPE ds ke te (XVar i) t

 (* Type abstraction *)
 | TYLAM 
   :  forall x1 t1
   ,  TYPE ds (ke :> KStar) (liftTE 0 te) x1 t1 
   -> TYPE ds ke             te           (XLAM x1) (TForall t1)

 (* Type application *)
 | TYAPP
   :  forall x1 t1 t2
   ,  TYPE ds ke te x1 (TForall t1)
   -> KIND ke t2 KStar
   -> TYPE ds ke te (XAPP x1 t2) (substTT 0 t2 t1)

 (* Function abstraction *)
 | TYLam
   :  forall x t1 t2
   ,  KIND ke t1 KStar
   -> TYPE ds ke (te :> t1) x            t2
   -> TYPE ds ke te         (XLam t1 x) (tFun t1 t2)

 (* Applications *)
 | TYApp
   :  forall x1 x2 t1 t2
   ,  TYPE ds ke te x1           (tFun t1 t2)
   -> TYPE ds ke te x2           t1
   -> TYPE ds ke te (XApp x1 x2) t2

 (* Data Constructors *)
 | TYCon 
   :  forall tc (ks: list ki) tsFields tsParam xs dc dcs
   ,  DEFSOK ds
   -> getTypeDef tc ds = Some (DefDataType tc ks       dcs)
   -> getDataDef dc ds = Some (DefData     dc tsFields tc)
   -> Forall2 (KIND ke) tsParam ks
   -> Forall2 (TYPE ds ke te) xs (map (substTTs 0 tsParam) tsFields)
   -> TYPE ds ke te (XCon dc tsParam xs) (makeTApps (TCon tc) tsParam)

 (* Case Expressions *)
 | TYCase
   :  forall xObj tObj tcObj ks tResult alts dcs

      (* check types of expression and alternatives *)
   ,  TYPE ds ke te xObj tObj
   -> Forall (fun alt => TYPEA ds ke te alt tObj tResult) alts

      (* All data cons must have a corresponding alternative. 
         Maybe we should move this to the well-formedness judgement *)
   -> getCtorOfType tObj  = Some tcObj
   -> getTypeDef tcObj ds = Some (DefDataType tcObj ks dcs)
   -> Forall (fun dc => In dc (map dcOfAlt alts)) dcs

   -> TYPE ds ke te (XCase xObj alts) tResult

with TYPEA  (ds: defs) (ke: kienv) (te: tyenv) : alt -> ty -> ty -> Prop :=
 (* Case Alternatives *)
 | TYAlt 
   :  forall x1 dc tc ks tsParam tsFields tResult dcs
   ,  DEFSOK ds
   -> getTypeDef tc ds = Some (DefDataType tc ks dcs)
   -> getDataDef dc ds = Some (DefData     dc tsFields tc)
   -> Forall2 (KIND ke) tsParam ks
   -> TYPE  ds ke (te >< map (substTTs 0 tsParam) tsFields) x1 tResult
   -> TYPEA ds ke te (AAlt dc x1) (makeTApps (TCon tc) tsParam) tResult.

Hint Constructors TYPE.
Hint Constructors TYPEA.


(* Invert all hypothesis that are compound typing statements. *)
Ltac inverts_type :=
 repeat 
  (match goal with 
   | [ H: TYPE  _ _ _ (XVar  _)     _    |- _ ] => inverts H
   | [ H: TYPE  _ _ _ (XLAM  _)     _    |- _ ] => inverts H
   | [ H: TYPE  _ _ _ (XAPP  _ _)   _    |- _ ] => inverts H
   | [ H: TYPE  _ _ _ (XLam  _ _)   _    |- _ ] => inverts H
   | [ H: TYPE  _ _ _ (XApp  _ _)   _    |- _ ] => inverts H
   | [ H: TYPE  _ _ _ (XCon  _ _ _) _    |- _ ] => inverts H
   | [ H: TYPE  _ _ _ (XCase _ _)   _    |- _ ] => inverts H
   | [ H: TYPEA _ _ _ (AAlt _ _)    _ _  |- _ ] => inverts H
   end).


(********************************************************************)
(* Forms of values. 
   If we know the type of a value,
   then we know the form of that value. *)
Lemma value_lam 
 :  forall x ds ke te t1 t2
 ,  value x 
 -> TYPE ds ke te x (tFun t1 t2)
 -> (exists t x', x = XLam t x').
Proof.
 intros. destruct x; eauto; nope.

 (* Show that x can't be a XCon because data type definitions can't
    define the function type constructor. *)
 unfold tFun in H0.
 inverts H0.
  apply makeTApps_takeTCon in H4.
  simpl in H4. inverts H4.
  have (DEFOK ds (DefData d tsFields TyConFun)).
  nope.
Qed.
Hint Resolve value_lam.


(********************************************************************)
(* Forms of types *)
Lemma type_XLAM
 :  forall ds ke te x t
 ,  TYPE ds ke te (XLAM x) t
 -> (exists t', t = TForall t').
Proof.
 intros. destruct t; nope.
 eauto.
Qed.
Hint Resolve type_XLAM.


Lemma type_XLam
 :  forall ds ke te x t1 t2
 ,  TYPE ds ke te (XLam t1 x) t2
 -> (exists t21 t22, t2 = tFun t21 t22).
Proof.
 intros. destruct t2; nope.
 inverts H. 
 unfold tFun. eauto.
Qed.
Hint Resolve type_XLam.


(********************************************************************)
(* A well typed expression is well formed *)

Theorem type_wfX
 :  forall ds ke te x t
 ,  TYPE ds ke te x t
 -> wfX (length ke) (length te) x.
Proof.
 intros. gen ds ke te t.
 induction x using exp_mutind with 
  (PA := fun a => forall ds ke te t1 t2
      ,  TYPEA ds ke te a t1 t2 
      -> wfA (length ke) (length te) a)
  ; intros; inverts_type; eauto.

 Case "XLAM".
  eapply WfX_XLAM.
  apply IHx in H1.
  rrwrite (length (ke :> KStar) = S (length ke)) in H1.
  rewrite <- length_liftTE in H1. auto.

 Case "XLam".
  eapply WfX_XLam; eauto.
  apply IHx in H4.
  rrwrite (length (te :> t) = S (length te)) in H4.
  auto.

 Case "XCon".
  apply WfX_XCon.
  repeat nforall. intros.
  have (exists k, KIND ke x k).
  dest k. eauto.
   repeat nforall. intros.
   have (exists t, TYPE ds ke te x t).
   dest t. eauto.

 Case "XCase".
  eapply WfX_XCase; eauto.
  repeat nforall. eauto.

 Case "XAlt".
  destruct dc.
  eapply WfA_AAlt. eauto.
  apply IHx in H8.
  rr. lists.
  rrwrite (length te + length tsFields = length tsFields + length te).
  eauto.
Qed.
Hint Resolve type_wfX.


Lemma type_wfX_Forall2
 :  forall ds ke te xs ts
 ,  Forall2 (TYPE ds ke te) xs ts
 -> Forall (wfX (length ke) (length te)) xs.
Proof.
 intros.
 eapply (Forall2_Forall_left (TYPE ds ke te)).
 intros. nforall. eauto.
 eauto.
Qed.
Hint Resolve type_wfX_Forall2.


(********************************************************************)
(* Weakening Kind Env in Type Judgement. *)
Lemma type_kienv_insert
 :  forall ix ds ke te x1 t1 k2
 ,  TYPE ds ke                te             x1             t1
 -> TYPE ds (insert ix k2 ke) (liftTE ix te) (liftTX ix x1) (liftTT 1 ix t1).
Proof.
 intros. gen ix ds ke te t1 k2.
 induction x1 using exp_mutind with 
  (PA := fun a => forall ix ds ke te k2 t3 t4
               ,  TYPEA ds ke te a t3 t4 
               -> TYPEA ds (insert ix k2 ke) (liftTE ix te) 
                           (liftTA ix a)     (liftTT 1 ix t3) (liftTT 1 ix t4))
  ; intros; inverts_type; simpl; eauto.

 Case "XVar".
  apply TYVar.
  apply get_map; auto.

 Case "XLAM".
  eapply TYLAM. 
  rewrite insert_rewind. 
  rewrite (liftTE_liftTE 0 ix).
  burn.

 Case "XAPP".
  rewrite (liftTT_substTT' 0 ix). 
  simpl.
  eapply TYAPP.
  eapply (IHx1 ix) in H2. simpl in H2. eauto.
  apply kind_kienv_insert; auto.

 Case "XLam".
  apply TYLam.
   apply kind_kienv_insert. auto.
   rrwrite ( liftTE ix te :> liftTT 1 ix t
           = liftTE ix (te :> t)).
   burn.

 Case "XApp".
  eapply TYApp.
   eapply IHx1_1 in H2. simpl in H2. eauto.
   eapply IHx1_2 in H4. eauto.

 Case "XCon".
  (* unpack the data type definition *)
  defok ds (DefData dc tsFields tc).

  (* show XCon has the correct type *)
  rr. eapply TYCon; eauto.

   (* type args have correct kinds *)
    eapply Forall2_map_left.
    eapply Forall2_impl; eauto.
    eauto using kind_kienv_insert.

   (* exp args have correct types *)
    apply Forall2_map.
    apply Forall2_map_right' in H9.
    eapply Forall2_impl_in; eauto.
     simpl. intros.

     repeat nforall.
     lets D: H ix H2 k2; auto. clear H.

     assert ( liftTT 1 ix (substTTs 0 ts y)
            = substTTs 0 (map (liftTT 1 ix) ts) y).

      rrwrite (ix = ix + 0).
      rewrite liftTT_substTTs'.
      rrwrite (ix + 0 = ix).
      f_equal. 

       assert (wfT (length ts) y).
       assert (length ts = length ks) as HLts.
        eapply Forall2_length. eauto.
        rewrite HLts.
        eapply kind_wfT. repeat nforall. eauto.

       rr. apply liftTT_wfT_1. auto.
       rewrite <- H. auto.

 Case "XCase".
  eapply TYCase; eauto.
  apply  Forall_map.
  eapply Forall_impl_in; eauto.
   intros. repeat nforall.
   eapply H; burn.
    rr. burn.
    repeat nforall. intros.
     have (In x (map dcOfAlt aa)).
     rr. auto.
       
 Case "XAlt".
  defok ds (DefData dc tsFields tc).

  rr.
  eapply TYAlt; eauto.
   eapply Forall2_map_left.
   eapply Forall2_impl; eauto.
    intros. eapply kind_kienv_insert. auto.

   assert ( map (liftTT 1 ix) (map (substTTs 0 tsParam)  tsFields)
          = map (substTTs 0 (map (liftTT 1 ix) tsParam)) tsFields) as HXX.
    lists.
    erewrite map_ext_in; eauto.
    intros.
     rename x into t1.
     rrwrite (ix = ix + 0).
     rewrite liftTT_substTTs'.
     f_equal. 
     nnat.
     assert (wfT (length ks) t1).
      eapply kind_wfT.
      nforall. eauto.
     eapply liftTT_wfT_1.
     rrwrite (length tsParam = length ks).
     auto.

   unfold liftTE in IHx1. 
   unfold liftTE.
   rewrite <- HXX.
   rewrite <- map_app.
   eauto.
Qed.


Lemma type_kienv_weaken1
 :  forall ds ke te x1 t1 k2
 ,  TYPE ds ke                   te            x1              t1
 -> TYPE ds (ke :> k2) (liftTE 0 te) (liftTX 0 x1) (liftTT 1 0 t1).
Proof.
 intros.
 assert (ke :> k2 = insert 0 k2 ke) as HI.
  simpl. destruct ke; auto.
 rewrite HI.
 eapply type_kienv_insert; auto.
Qed.


(********************************************************************)
(* Weakening Type Env in Type Judgement.
   We can insert a new type into the type environment, provided we
   lift existing references to types higher in the stack across
   the new one. *)
Lemma type_tyenv_insert
 :  forall ds ke te ix x t1 t2
 ,  TYPE ds ke te x t1
 -> TYPE ds ke (insert ix t2 te) (liftXX 1 ix x) t1.
Proof.
 intros. gen ix ds ke te t1 t2.
 induction x using exp_mutind with 
  (PA := fun a => forall ix ds ke te t2 t3 t4
      ,  TYPEA ds ke te a t3 t4 
      -> TYPEA ds ke (insert ix t2 te) (liftXA 1 ix a) t3 t4)
  ; intros; inverts_type; simpl; eauto.

 Case "XVar".
  nnat; lift_cases; burn.

 Case "XLAM".
  apply TYLAM.
  assert ( liftTE 0 (insert ix t2 te)
         = insert ix (liftTT 1 0 t2) (liftTE 0 te)).
   unfold liftTE. rewrite map_insert. auto.
   burn.

 Case "XLam".
  apply TYLam; eauto.
  rewrite insert_rewind. auto.

 Case "XCon".
  eapply TYCon; eauto.
   nforall.
   apply (Forall2_map_left (TYPE ds ke (insert ix t2 te))).
   apply (Forall2_impl_in  (TYPE ds ke te)); eauto.

 Case "XCase".
  eapply TYCase; eauto.
   apply Forall_map.
   apply (Forall_impl_in 
     (fun a => TYPEA ds ke te a tObj t1)); eauto.
   repeat nforall. eauto.
   repeat nforall.
    intros. lists.
    rename x0 into d.
    eapply map_exists_in.
    have (In d (map dcOfAlt aa)). 
    assert (exists a, dcOfAlt a = d /\ In a aa).
     eapply map_in_exists. auto.
   shift a. rip.
   eapply dcOfAlt_liftXA.

 Case "XAlt".
  defok ds (DefData dc tsFields tc).
  eapply TYAlt; eauto.
  rewrite insert_app.
  lists. burn.
Qed. 


(* We can push a new type onto the environment stack provided
   we lift references to existing types across the new one. *)
Lemma type_tyenv_weaken1
 :  forall ds ke te x t1 t2
 ,  TYPE ds ke te x t1
 -> TYPE ds ke (te :> t2) (liftXX 1 0 x) t1.
Proof.
 intros.
 assert (te :> t2 = insert 0 t2 te) as HI.
  simpl. destruct te; auto.
 rewrite HI.
 apply type_tyenv_insert. auto.
Qed.


(* We can several new types onto the environment stack provided
   we lift referenes to existing types across the new one. *)
Lemma type_tyenv_weaken_append
 :  forall ds ke te te' x t1
 ,  TYPE ds ke te x t1
 -> TYPE ds ke (te >< te') (liftXX (length te') 0 x) t1.
Proof.
 intros.
 induction te'; simpl.
  burn.

  rrwrite (S (length te') = length te' + 1).
  rrwrite (length te' + 1 = 1 + length te').
  rewrite <- liftXX_plus.
  eapply type_tyenv_weaken1.
  burn.
Qed.
