;; SPDX-License-Identifier: MIT
;; Copyright (C) 2020 Massimo Zaniboni <mzan@dokmelody.org>

(ns org.dokmelody.jam.doknil.core
  (:require [fogus.datalog.bacwn.impl.literals :as literals])
  (:use [fogus.datalog.bacwn :only (build-work-plan run-work-plan)]
        [fogus.datalog.bacwn.macros :only (<- ?- make-database)]
        [fogus.datalog.bacwn.impl.rules :only (rules-set)]
        [fogus.datalog.bacwn.impl.database :only (add-tuples)]))

;; TODO find a way to link a clojure value/object to a database statment
;; TODO insert the distance of CONTEXT and PARENT in the derived relation
;; TODO select the nearest card in the UI using the DISTANCE attribute
;; TODO a card is created by code, because I can use literate programming and templates
;; TODO a card can read from a file on resource directories
;; TODO the card-db is a function returning a card as a value, given a card name/index
;; TODO caching of cards allows to avoid regeneration of all cards
;; TODO order also relations by transitive closure
;; TODO cache/memoize the generation of a card
;; TODO define a syntax for the language
;; TODO store facts inside resources or similar
;; TODO download them
;; TODO to be fair some facts are intensional and it is important also using Clojure code
;; so the syntax will be readable Clojure code
;; MAYBE during cards creation manage CONTEXT as a dynamic attribute
;; TODO cards can be created combining chunks of code, in literate-programming style.
;; TODO during reading the title include the context "R1/R0" with "R0" being the parent
;; TODO a CARD can be defined, but until it is not used in a CONTEXT, its facts are not generated
;; TODO Doknil will use a Clojure-like syntax when expressed in Clojure
;; ;; TODO create a map with complete-hiearchy as a vector and used as key, and the ``context-hierarchy-id`` as value.
;; It will be used for creating new contexts on demand.
;; Then they will be inserted exploded inside ``doknil-db``.
;; TODO find if Refs, Vars or Atoms must be used for adding new facts inside doknil-db at run-time
;; MAYBE make the same thing for part and role hierarchies
;;
;; TODO I'm interested to direct-instances of context and part
;; TODO use the fact-id for returning the more precise fact of a rule
;;
;; TODO store in a map/db the assocation between key and card object
;; TODO support current owner and role and context as dynamic attribute during declaration
;;
;; TODO define a Doknil DSL in Clojure for asserting facts and querying data that is easy to use,
;; because the Datalog DSL is not very readable and too much generic
;; TODO add index later to the db schema, according the type of queries to do
;; TODO contexts must be added to the DB according their effective usage because every new hierarchy is a new id,
;; or use instead an hash map of the complete hiearchy
;; TODO use a defalt NULL/nil value for some of the specified relations
;; TODO when a new hierarchy is added, then all sub-hierarchies (if news) are added
;; TODO find a way for saying that a certain part of a company or similar believe in things different (like context)
;; MAYBE enforce a rule that all facts about a part and every part of his hierachy had to be in the same context
;; TODO supports context that are hypothetical and not part of the world/root context
;; TODO store in a data structure apart the associations between ids and complete hierarchy name
;; TODO use this same structure for lookup during parsing
;; TODO the same for roles, and all other Doknil elements
;; TODO create an id for ``world`` and for the empty context-group. Using an id is more coherent on the UI and query side
;; TODO create a lookup function for passing from hierarchy names to id

;; TODO say this in documentation
;; NOTE: in a cntx like ``x/y.a --> { !exclude x.b }``, the effect of exclusion
;; is on all groups of branch ``x/y``, and ``x.b`` is a group used for
;; identifying the group of facts of branch ``x`` that are not visible inside
;; branch ``x/y``. So visibility is a property of a branch, while the group
;; is used only for specifying wich facts are not visible.
;;
;; This info will be used later, in a stratified negation,
;; for avoiding excluded path.

;; TODO make sure to register also roles without a parent
;; TODO it is important showing explicitely overriden contexts
;; TODO in queries one can only specify branches without groups
;; TODO branch.group are used only in meta-navigation inside the KB
;; for editing it.

;; TODO expose ``is-direct-part-of`` query to the external
;; TODO check that cntx itself is returned, and so no facts are left behind

;; TODO ``x is Related to p`` does not form a ``x is PartOf p`` implicit hierarchy
;; So probably only the ``of p`` must generate ``PartOf`` implicit relations.
;; TODO generate explicit ``PartOf`` links when a role defines also this.

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

;; These are the base (extensional) facts of the KB.
(def schema
  (make-database

   (relation :role [:id :parent])
   ;; Store a role hierarchy like ``Task/Issue``.
   ;; A role has a unique parent.
   ;; For roles without a parent set :parent-id to nil.

   (relation :branch [:id :parent])
   ;; The branch of a context. Something like ``world/x/y``.
   ;; The root context branch `world` has :parent set to nil, and the special id 0

   (relation :cntx [:id :branch :parent])
   ;; A cntx branch and an optional group.
   ;; Something like ``world/x/y.a.b.c``.
   ;; The :parent manage only the group part, so the :branch must remain constant
   ;; in the same hierarchy.

   (relation :include-cntx [:dst-cntx :src-cntx])
   ;; Something like ``dstContext.some.group --> { !include some/source/cntx.another.group.cntx }``

   (relation :exclude-cntx [:dst-cntx :src-cntx])
   ;; Something like ``dstContext.some.group --> { !exclude some/source/cntx.another.group.cntx }``

   (relation :isa-fact [:id :cntx :instance :role :part])
   ;; Store the Role relationship of a fact.
   ;; Something like ``world/x/y.a.b --> { e isa Something for c }``
   ;; :part is the owner/part-of. It is set to nil if it is not specified.

   ))

;; These rules derive the intensional facts, using the Doknil semantic.
;;
;; Derived facts must take in consideration the branch of the query,
;; because every source context can have different facts.
;;
(def rules
  (rules-set

   ;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;; Return transitive closure of role hierarchy.

   ; A role is a sub-role of itself (reflexivity).
   (<- (:role-rec :role ?role :parent-role ?role)

       (:role :id ?role :parent ?ignore1))

   ; Return extensional facts.
   (<- (:role-rec :role ?role :parent-role ?parent-role)

       (:role :id ?role :parent ?parent-role))

   ; Transitive closure.
   (<- (:role-rec :role ?role :parent-role ?parent-role2)

       (:role-rec :role ?role :parent-role ?parent-role1)
       (:role :id ?parent-role1 :parent ?parent-role2))

   ;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;; Return all defined cntx groups of a branch.
   ;; E.g. for branch ``x/y`` return ``x/y.a``, ``x/y.b``, ``x/y.b.c``
   ;; Do not follow cntx parents.

   ; Return extensional facts.
   (<- (:branch-group-rec :branch ?branch :cntx ?cntx)

       (:cntx :id ?cntx :branch ?branch :parent ?ignore1))

   ; Return the groups on the same branch.
   (<- (:branch-group-rec :branch ?branch :cntx ?cntx2)

       (:branch-group-rec :branch ?branch :cntx ?cntx1)
       (:cntx :id ?cntx2 :branch ?branch :parent ?cnxt1))

   ;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;; Return all parent branches of a branch.
   ;; Do not follow cntx parents.

   ; Return the branch itself.
   (<- (:branch-rec :branch ?branch :parent ?branch)
       
       (:branch :id ?branch :parent ?ignore1))

   ; Return extensional facts.
   (<- (:branch-rec :branch ?branch :parent ?parent)

       (:branch :id ?branch :parent ?parent))

   ; Transitive closure.
   (<- (:branch-rec :branch ?branch :parent ?parent2)

       (:branch-rec :branch ?branch :parent ?parent1)
       (:branch :id ?parent1 :parent ?parent2))

   ;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;; Return all group cntx of current and parent branches.

   (<- (:cntx-rec1 :branch ?branch :cntx ?group2)

       (:branch-rec :branch ?branch :parent ?branch2)
       (:branch-group-rec :branch ?branch2 :cntx ?group2))

   ;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;; Return all group cntx of current and parent branches,
   ;; following also ``!include`` semantic,
   ;; without considering ``!exclude``.

   ; The same results of ``cntx-rec1``.
   (<- (:cntx-rec2 :branch ?branch :cntx ?cntx)

       (:cntx-rec1 :branch ?branch :cntx ?cntx))

   ; Search if there are ``include`` path to follow,
   ; and apply transitive closure on them.
   (<- (:cntx-rec2 :branch ?branch :cntx ?cntx4)

       (:cntx-rec2 :branch ?branch :cntx ?cntx2)
       (:include-cntx :dst-cntx ?cntx2 :src-cntx ?cntx3)
       (:cntx :id ?cntx3 :branch ?branch4 :parent ?ignore1)

       (:cntx-rec1 :branch ?branch4 :cntx ?cntx4))

   ;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;; Return all excluded cntx.

   (<- (:exclude-cntx-rec :branch ?branch :cntx ?cntx2)

       (:cntx-rec2 :branch ?branch :cntx ?cntx1)
       (:exclude-cntx :dst-cntx :cntx1 :src-cntx ?cntx2))

   ;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;; Return all visible cntx taking in consideration all,
   ;; so cntx hierarchy, groups and ``!include`` and ``!exclude``paths.
   ;;
   ;; ``!exclude`` has more priority than ``!include``.

   ; Remove from ``cntx-rec2`` the excluded paths.
   ; This approarch works correctly because a cntx can exclude
   ; only a parent context (acting like a branch),
   ; and not an external cntx on an include path.
   ; So include and exclude path are always distinct.
   (<- (:cntx-rec3 :branch ?branch :cntx ?cntx)

       (:cntx-rec2 :branch ?branch :cntx ?cntx)
       (not! :exclude-cntx-rec :branch ?branch :cntx ?cntx))

   ;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;; Return the ``part-of`` hierarchy visible in a branch.
   ;; Do not return the transitive closure, but only direct parts.

   ; All Roles specified respect a part derives also an implicit ``is-part-of`` relationship.
   (<- (:is-direct-part-of :branch ?branch :instance ?instance :owner ?owner :fact ?fact)

       (:cntx-rec3 :branch ?branch :cntx ?cntx)
       (:isa-fact :id ?fact :cntx ?cntx :instance ?instance :role ?ignore2 :part ?owner)
       (if some? ?owner))

   ;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;; Return all facts visible in a branch considering
   ;; the cntx hierarchy, and the ``part-of`` hierarchy,
   ;; but not the hierarchy of roles.
   ;; Roles hierarchy is applied later, for reducing paths to consider.

   ; Consider the cntx hierarchy.
   (<- (:isa-rec1 :branch ?branch :instance ?instance :role ?role :part ?part :fact ?fact)

       (:cntx-rec3 :branch ?branch :cntx ?cntx)
       (:isa-fact :id ?fact :cntx ?cntx :instance ?instance :role ?role :part ?part))

   ; Consider the ``part-of`` hierarchy, applying also transitive closure.
   (<- (:isa-rec1 :branch ?branch :instance ?instance :role ?role :part ?part2 :fact ?fact)

       (:isa-rec1 :branch ?branch :instance ?instance :role ?role :part ?part1 :fact ?fact)
       (:is-direct-part-of :branch ?branch :instance ?part1 :owner ?part2 :fact ?ignore2))

   ;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;; Extend :isa-rec1 with transitive closure on hierarchy of roles.


   (<- (:isa :branch ?branch :instance ?instance :role ?role2 :part ?part :fact ?fact)

       (:isa-rec1 :branch ?branch :instance ?instance :role ?role1 :part ?part :fact ?fact)
       (:role-rec :role ?role1 :parent-role ?role2))
   
   ))

  (def query-isa-1
    (build-work-plan 
       rules 
     (?- :isa :branch '??branch :instance '??instance :role '??role :part ?part :fact ?fact)))
