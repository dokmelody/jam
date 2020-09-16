;; SPDX-License-Identifier: MIT
;; Copyright (C) 2020 Massimo Zaniboni <mzan@dokmelody.org>

#lang racket

(require datalog)
(provide doknil-db)

(define doknil-db (make-theory))

(define  (precalculate-reachable-cntx)
  "Calculate a map BRANCH -> set-of(CNTX) with only the visible CNTX for each BRANCH."

  (define paths1 (datalog doknil-db (? (cntx-rec2 BRANCH CNTX))))
  (define paths2 (datalog doknil-db (? (exclude-cntx-rec BRANCH CNTX))))

  ; a map from BRANCH to set-of(CNTX)
  ; Leave only reachable contexts
  (define r (make-hash))

  (for ([p paths1])
    (define branch (dict-ref p 'BRANCH))
    (define cntx (dict-ref p 'CNTX))

    (hash-update! r branch (lambda (s) (begin
                                         (set-add! s cntx)
                                         s)) (mutable-set)))

  (for ([p paths2])
    (define branch (dict-ref p 'BRANCH))
    (define cntx (dict-ref p 'CNTX))

    (hash-update! r branch (lambda (s) (begin
                                         (set-remove! s cntx)
                                         s)) (mutable-set)))

  r)

(define precalculated-reachable-cntx (box #f))

(define (reachable-cntx? branch cntx)

  (define t (unbox precalculated-reachable-cntx))
  (when (eq? t #f) (set-box! precalculated-reachable-cntx (precalculate-reachable-cntx)))

  (define m (unbox precalculated-reachable-cntx))

  (if (hash-has-key? m branch)
      (set-member? (hash-ref m branch) cntx)
      #f))

(datalog doknil-db
        
   ;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;; Base facts (i.e. extensional facts)
   ;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   ;; Store a role hierarchy like ``Task/Issue``.
   ;; A role has a unique parent.
   ;; For roles without a parent set parent to #f
   ;; COMPLEMENT is the ``of``, ``for``, ``to``, etc.. complement linking
   ;; the subject of a fact with its object.
   ;; Only COMPLEMENT of type ``of`` derive also a ``part-of`` relationship,
   ;; and it is marked as #t, meaning IS-PART-OF.
   ;;
   ;; A constraint it is that a child ROLE with a COMPLEMENT not of type ``of``
   ;; can not have a parent ROLE with COMPLEMENT ``of``. The reason it is that
   ;; all ``of`` relationships must be explicit at the moment of the definition
   ;; of the extensional fact, and not unexpected.
   ;;
   ;; > (! (role ID IS-PART-OF PARENT))

   ;; The branch of a context. Something like ``world/x/y``.
   ;; The root context branch `world` has parent set to #f, and the special id 0
   ;;
   ;; > (! (branch ID PARENT))

   ;; A cntx branch and an optional group.
   ;; Something like ``world/x/y.a.b.c``.
   ;; The PARENT manage only the group part, so the BRANCH must remain constant
   ;; in the same hierarchy.
   ;;
   ;; > (cntx ID BRANCH PARENT)

   ;; Something like ``dstContext.some.group --> { !include some/source/cntx.another.group.cntx }``
   ;;
   ;; > (include-cntx DST-CNTX SRC-CNTX)

   ;; Something like ``dstContext.some.group --> { !exclude some/source/cntx.another.group.cntx }``
   ;;
   ;; > (exclude-cntx DST-CNTX SRC-CNTX)

   ;; Store the Role relationship of a fact.
   ;; Something like ``world/x/y.a.b --> { e isa Something for c }``
   ;;
   ;; OBJECT is set to nil if it is not specified.
   ;;
   ;; > (isa-fact ID CNTX INSTANCE ROLE OBJECT)

   ;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;; Intensional facts derived from extensional facts.
   ;; These rules derive the intensional facts, using the Doknil semantic.
   ;; Derived facts must take in consideration the branch of the query,
   ;; because every source context can have different facts.
   ;;
   ;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   ;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;; Return transitive closure of role hierarchy:
   ;; from a ROLE to a compatible ROLE

   ; A role is a sub-role of itself (reflexivity).
   (! (:- (role-rec ROLE1 ROLE2 IS-PART-OF)

          (role ROLE1 IS-PART-OF IGNORE1)
          (= ROLE1 ROLE2)
          (!= IGNORE1 'ignore)))

   ; Follow parent role
   (! (:- (role-rec ROLE1 ROLE2 IS-PART-OF2)

          (role ROLE1 IGNORE1 ROLE2)
          (role ROLE2 IS-PART-OF2 IGNORE2)
          (!= IGNORE1 'ignore)
          (!= IGNORE2 'ignore)))


   ; Transitive closure
   (! (:- (role-rec ROLE1 ROLE3 IS-PART-OF3)

          (role-rec ROLE1 ROLE2 IGNORE1)
          (role ROLE2 IGNORE2 ROLE3)
          (role ROLE3 IS-PART-OF3 IGNORE3)
          (!= IGNORE1 'ignore)
          (!= IGNORE2 'ignore)
          (!= IGNORE3 'ignore)))

   ;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;; Return all defined cntx groups of a branch.
   ;; E.g. for branch ``x/y`` return ``x/y.a``, ``x/y.b``, ``x/y.b.c``
   ;; Do not follow cntx parents.

   ; Return extensional facts.
   (! (:- (branch-group-rec BRANCH CNTX)

          (cntx CNTX BRANCH IGNORE1)
          (!= IGNORE1 'ignore)))

   ; Return the groups on the same branch.
   (! (:- (branch-group-rec BRANCH CNTX2)

          (branch-group-rec BRANCH CNTX1)
          (cntx CNTX2 BRANCH CNTX1)))

   ;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;; Return all parent branches of a branch.
   ;; Do not follow cntx parents.

   ; Return the branch itself.
   (! (:- (branch-rec BRANCH1 BRANCH2)

          (branch BRANCH1 IGNORE1)
          (!= IGNORE1 'ignore)
          (= BRANCH1 BRANCH2)))

   ; Return extensional facts
   (! (:- (branch-rec BRANCH PARENT)

          (branch BRANCH PARENT)))

   ; Transitive closure.
   (! (:- (branch-rec BRANCH PARENT2)

          (branch-rec BRANCH PARENT1)
          (branch PARENT1 PARENT2)))

   ;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;; Return all group cntx of current and parent branches.

   (! (:- (cntx-rec1 BRANCH GROUP2)

          (branch-rec BRANCH BRANCH2)
          (branch-group-rec BRANCH2 GROUP2)))

   ;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;; Return all group cntx of current and parent branches,
   ;; following also ``!include`` semantic,
   ;; without considering ``!exclude``.

   ; The same results of ``cntx-rec1``.
   (! (:- (cntx-rec2 BRANCH CNTX)

          (cntx-rec1 BRANCH CNTX)))

   ; Search if there are ``include`` path to follow,
   ; and apply transitive closure on them.
   (! (:- (cntx-rec2 BRANCH CNTX4)

          (cntx-rec2 BRANCH CNTX2)
          (include-cntx CNTX2 CNTX3)
          (cntx CNTX3 BRANCH4 IGNORE1)
          (!= IGNORE1 'ignore)
          (cntx-rec1 BRANCH4 CNTX4)))

   ;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;; Return all excluded cntx.

   (! (:- (exclude-cntx-rec BRANCH CNTX2)

          (cntx-rec2 BRANCH CNTX1)
          (exclude-cntx CNTX1 CNTX2)))

   ;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;; Return all visible cntx taking in consideration all,
   ;; so cntx hierarchy, groups and ``!include`` and ``!exclude``paths.
   ;;
   ;; ``!exclude`` has more priority than ``!include``.

   (! (:- (cntx-rec3 BRANCH CNTX)

          (cntx-rec2 BRANCH CNTX)
          (reachable-cntx? BRANCH CNTX :- IS-REACHABLE)
          (= #t IS-REACHABLE)))

   ;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;; Return the ``part-of`` hierarchy visible in a branch.
   ;; Do not return the transitive closure, but only direct parts.

   ; All Roles specified respect a part derives also an implicit ``is-part-of`` relationship.
   ; NOTE: we can analyze only the ``role`` and not ``role-rec`` because the ``of`` relationship
   ; is mandatory that must be explicit in the extensional facts.
   (! (:- (is-direct-part-of BRANCH INSTANCE OWNER FACT)

          (cntx-rec3 BRANCH CNTX)
          (isa-fact FACT CNTX INSTANCE ROLE OWNER)
          (role ROLE #t IGNORE1)
          (!= IGNORE1 'ignore)
          (!= OWNER #f)))

   ;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;; Return all facts visible in a branch considering
   ;; the cntx hierarchy, and the ``part-of`` hierarchy,
   ;; but not the hierarchy of roles.
   ;; Roles hierarchy is applied later, for reducing paths to consider.

   ; Consider the cntx hierarchy.
   (! (:- (isa-rec1 BRANCH INSTANCE ROLE OBJECT CNTX FACT)

          (cntx-rec3 BRANCH CNTX)
          (isa-fact FACT CNTX INSTANCE ROLE OBJECT)))

   ; Consider the ``part-of`` hierarchy, applying also transitive closure.
   (! (:- (isa-rec1 BRANCH INSTANCE ROLE OBJECT2 CNTX FACT)

          (isa-rec1 BRANCH INSTANCE ROLE OBJECT1 CNTX FACT)
          (is-direct-part-of BRANCH OBJECT1 OBJECT2 IGNORE2)
          (!= IGNORE2 'ignore)))

   ;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;; Extend :isa-rec1 with transitive closure on hierarchy of roles.

   (! (:- (isa BRANCH INSTANCE ROLE2 IS-PART-OF OBJECT CNTX FACT)

          (isa-rec1 BRANCH INSTANCE ROLE1 OBJECT CNTX FACT)
          (role-rec ROLE1 ROLE2 IS-PART-OF))))
