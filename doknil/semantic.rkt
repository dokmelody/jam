;; SPDX-License-Identifier: MIT
;; Copyright (C) 2020 Massimo Zaniboni <mzan@dokmelody.org>

#lang racket

(require datalog)

(provide doknil)

;; TODO find a way to link a clojure value/object to a database statment
;; MAYBE insert the distance of CONTEXT and PARENT in the derived relation
;; TODO select the nearest card in the UI using the DISTANCE attribute
;; TODO a card can read from a file on resource directories
;; TODO the card-db is a function returning a card as a value, given a card name/index
;; TODO caching of cards allows to avoid regeneration of all cards
;; TODO order also relations by transitive closure
;; TODO cache/memoize the generation of a card
;; TODO store facts inside resources or similar
;; TODO during reading the title include the context "R1/R0" with "R0" being the parent
;; TODO create a map with complete-hiearchy as a vector and used as key, and the ``context-hierarchy-id`` as value.
;; It will be used for creating new contexts on demand.
;; Then they will be inserted exploded inside ``doknil-db``.
;; TODO find if Refs, Vars or Atoms must be used for adding new facts inside doknil-db at run-time
;; MAYBE make the same thing for part and role hierarchies
;;
;; TODO store in a map/db the assocation between key and card object
;;
;; TODO add index later to the db schema, according the type of queries to do
;; TODO contexts must be added to the DB according their effective usage because every new hierarchy is a new id,
;; or use instead an hash map of the complete hiearchy
;; TODO use a defalt NULL/nil value for some of the specified relations
;; TODO when a new hierarchy is added, then all sub-hierarchies (if news) are added
;; TODO store in a data structure apart the associations between ids and complete hierarchy name
;; TODO use this same structure for lookup during parsing
;; TODO the same for roles, and all other Doknil elements
;; TODO create an id for ``world`` and for the empty context-group. Using an id is more coherent on the UI and query side
;; TODO create a lookup function for passing from hierarchy names to id

;; TODO make sure to register also roles without a parent
;; TODO it is important showing explicitely overriden contexts
;; TODO in queries one can only specify branches without groups

;; TODO check that cntx itself is returned, and so no facts are left behind
;; TODO check that all ``of`` relationships have no child role without ``of`` COMPLEMENT
;; TODO report the reason in the manual

;; TODO support a sort of stratified negation for inclusion of branches
;; TODO The problem of Racket API for excluding CNTX, it is that it can influence also the
;; is-part-of relationship, and this is-part-of can be defined in a branch but not in another
;; so I had to exclude before and not after the query

;; TODO DokMelody UI elements
#|
(defprotocol ACard
  "A piece of short information"

  (title [this])
  (mime-type [this])
  (content [this])
  (implicit-links [this]))

(defprotocol ALink
  (subject [this])
  (relation [this])
  (object [this])
  (context [this]))
 )
|#

(define doknil (make-theory))

(define  (precalculate-reachable-cntx)
  "Calculate a map BRANCH -> set-of(CNTX) with only the visible CNTX for each BRANCH."

  (define paths1 (datalog doknil (? (cntx-rec2 BRANCH CNTX))))
  (define paths2 (datalog doknil (? (exclude-cntx-rec BRANCH CNTX))))

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

(datalog doknil
        
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
   ;; Only COMPLEMENT of type ``of`` derive also a ``part-of`` relationship.
   ;;
   ;; A constraint it is that a child ROLE with a COMPLEMENT not of type ``of``
   ;; can not have a parent ROLE with COMPLEMENT ``of``. The reason it is that
   ;; all ``of`` relationships must be explicit at the moment of the definition
   ;; of the extensional fact, and not unexpected.
   ;;
   ;; > (! (role ID COMPLEMENT PARENT))

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
   (! (:- (role-rec ROLE1 ROLE2 COMPLEMENT)

          (role ROLE1 COMPLEMENT IGNORE1)
          (= ROLE1 ROLE2)
          (!= IGNORE1 #t)))

   ; Follow parent role
   (! (:- (role-rec ROLE1 ROLE2 COMPLEMENT2)

          (role ROLE1 IGNORE1 ROLE2)
          (role ROLE2 COMPLEMENT2 IGNORE2)
          (!= IGNORE1 #t)
          (!= IGNORE2 #t)))


   ; Transitive closure
   (! (:- (role-rec ROLE1 ROLE3 COMPLEMENT3)

          (role-rec ROLE1 ROLE2 IGNORE1)
          (role ROLE2 IGNORE2 ROLE3)
          (role ROLE3 COMPLEMENT3 IGNORE3)
          (!= IGNORE1 #t)
          (!= IGNORE2 #t)
          (!= IGNORE3 #t)))

   ;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;; Return all defined cntx groups of a branch.
   ;; E.g. for branch ``x/y`` return ``x/y.a``, ``x/y.b``, ``x/y.b.c``
   ;; Do not follow cntx parents.

   ; Return extensional facts.
   (! (:- (branch-group-rec BRANCH CNTX)

          (cntx CNTX BRANCH IGNORE1)
          (!= IGNORE1 #t)))

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
          (!= IGNORE1 #t)
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
          (!= IGNORE1 #t)
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
          (role ROLE of IGNORE1)
          (!= IGNORE1 #t)
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
          (!= IGNORE2 #t)))

   ;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;; Extend :isa-rec1 with transitive closure on hierarchy of roles.

   (! (:- (isa BRANCH INSTANCE ROLE2 COMPLEMENT OBJECT CNTX FACT)

          (isa-rec1 BRANCH INSTANCE ROLE1 OBJECT CNTX FACT)
          (role-rec ROLE1 ROLE2 COMPLEMENT))))

(datalog doknil

    (! (role related to #f))
    (! (role task of related))
    (! (role issue of task))

    (! (role company of #f))
    (! (role department of company))

    (! (branch world #f))
    (! (cntx cntx-world world #f))


    (! (isa-fact fact-part-1 cntx-world acme-corporation company #f))
    (! (isa-fact fact-part-2 cntx-world department-x department acme-corporation))
    (! (isa-fact fact-1 cntx-world issue-1 issue department-x))

    ;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;; Try different branches
    ;;

    (! (branch earth world))
    (! (branch tolkien earth))

    (! (cntx cntx-earth earth #f))
    (! (cntx cntx-places earth cntx-earth))
    (! (cntx cntx-tolkien tolkien #f))
    (! (cntx cntx-tolkien-places tolkien cntx-tolkien))
    (! (exclude-cntx cntx-tolkien-places cntx-places))

    (! (role nation #f #f))
    (! (role city of related))

    (! (isa-fact fe-1 cntx-places italy nation #f))
    (! (isa-fact fe-2 cntx-places rome city italy))

    (! (isa-fact ft-1 cntx-tolkien-places middle-earth nation #f))
    (! (isa-fact ft-2 cntx-tolkien-places gondor city middle-earth))
)

(datalog! doknil
    (? (role-rec issue PARENT-ROLE COMPLEMENT))
    (? (isa world issue-1 issue COMPLEMENT OBJECT CNTX FACT))
    (? (isa world issue-1 related COMPLEMENT OBJECT CNTX FACT))
    (? (isa world issue-1 task COMPLEMENT OBJECT CNTX FACT))

    (? (cntx-rec3 X Y))

    (? (isa earth CITY city COMPLEMENT OBJECT CNTX FACT))
    (? (isa tolkien CITY city COMPLEMENT OBJECT CNTX FACT))
)
