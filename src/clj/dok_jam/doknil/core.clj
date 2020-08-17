;; SPDX-License-Identifier: MIT
;; Copyright (C) 2020 Massimo Zaniboni <mzan@dokmelody.org>

(ns dok-jam.doknil.core
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
;; TODO specify a command for tests
;; TODO launch them locally
;; TODO tell in the repl.it how to launch them
;; TODO tests are a form of documentation: code and output
;;
;; TODO store in a map/db the assocation between key and card object
;; TODO see how in DokMelody manage descriptions of Roles that usually are not instances, but ...
;; TODO add regression tests about the logic of the DBMS

;; TODO support current owner and role and context as dynamic attribute during declaration
;;
;; TODO define a Doknil DSL in Clojure for asserting facts and querying data that is easy to use,
;; because the Datalog DSL is not very readable and too much generic
;; TODO add index later to the db
;; TODO contexts must be added to the DB according their effective usage because every new hierarchy is a new id,
;; or use instead an hash map of the complete hiearchy
;; TODO use a defalt NULL/nil value for some of the specified relations
;; TODO return the fact-id of the extensional fact in case of derived rules
;; TODO when a new hierarchy is added, then all sub-hierarchies (if news) are added
;; TODO find a way for saying that a certain part of a company or similar believe in things different (like context)
;; MAYBE enforce a rule that all facts about a part and every part of his hierachy had to be in the same context
;; TODO remove concept of "nil" and stop simply the hierarchy
;; TODO take in consideration the include and exclude directives for contexts
;; TODO supports also facts without a part-id hierarchy and/or a default context
;; TODO use example code like in https://github.com/fogus/bacwn/blob/master/examples/employees/example.clj

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

(def schema
  (make-database
   (relation :role [:id :instance-id])
   ;; the instance-id is the description of the role

   (relation :role-hierarchy [:child-role-id :parent-role-id])
   ;; a role has a unique hierarchy

   (relation :context-hierarchy [:id :instance-id :child-hierarchy-id])
   ;; they are all primary-keys because for the same :id there is an hierarchy chain
   ;; and every record is a part of it.
   ;; Use nil for the end of a context hierarchy

   (relation :context-override [:context-hierarchy-id :overridden-context-hierarchy-id])

   (relation :context-include [:context-hierarchy-id :included-context-hierarchy-id])

   (relation :part [:child-instance-id :parent-instance-id :context-hierarchy-id])

   (relation :isa-fact [:fact-id :instance-id :role-id :part-id :context-hierarchy-id])))

(def rules
  (rules-set

   ; extensional fact
   (<- (:isa :instance ?instance-id :role ?role-id :part ?part-id :context ?context-id :fact ?extensional-fact-id)
       (:isa-fact :fact-id ?extensional-fact-id :instance-id ?instance-id :role-id ?role-id :part-id ?part-id :context-hierarchy-id ?context-id))


   ; TODO use same-part and same-fact for deriving all

   ; A fact true in a parent context is true also in child context
   (<- (:isa :instance ?instance-id ?role-id ?part-id ?context-id ?extensional-fact-id)
       (:context-hierarchy :id ?parent-context-id :instance-id ?context-instance-id :child-hierarchy-id ?child-context-id)
       (if some? ?child-context-id)
       (:isa :instance ?instance-id :role ?role-id :part ?part-id :context ?child-context-id :fact ?extensional-fact-id))

   ; A fact true in a child part is true also in parent part
   (<- (:isa :instance ?instance-id :role ?role-id :part ?part-id :context ?context-id :fact ?extensional-fact-id)
       (:part :child-instance-id ?part-id :parent-instance-id ?parent-part-id :context-hierarchy-id ?context-id)
       (if some? ?parent-part-id)
       (:isa :instance ?instance-id :role ?role-id :part ?parent-part-id :context ?context-id :fact ?extensional-fact-id))

   ; A fact true for a role, is true also for the most generic role
   (<- (:isa :instance ?instance-id :role ?parent-role-id :part ?part-id :context ?context-id :fact ?extensional-fact-id)
       (:role-hierarchy :child-role-id ?role-id :parent-role-id ?parent-role-id)
       (:isa :instance ?instance-id :role ?role-id :part ?part-id :context ?context-id :fact ?extensional-fact-id))
  ))

(def query-1 
  (build-work-plan rules (?- :isa :instance '??instance-id :role '??role-id :part ?part-id :context '??context-id :fact ?extensional-fact-id))
)


