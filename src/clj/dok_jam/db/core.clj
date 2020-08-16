;; SPDX-License-Identifier: MIT
;; Copyright (C) 2020 Massimo Zaniboni <mzan@dokmelody.org>

(ns dok-jam.db.core
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

;; TODO store in a map/db the assocation between key and card object

(defprotocol ACard
  "A piece of short information"
          
  (title [this])
  (mime-type [this])
  (content [this])
  (implicit-links [this])
)

(defprotocol ALink
  (subject [this])
  (relation [this])
  (object [this])
  (context [this])
  )

;; TODO add index later
;; TODO contexts must be added to the DB according their effective usage because every new hierarchy is a new id,
;; or use instead an hash map of the complete hiearchy
;; TODO use a defalt NULL/nil value for some of the specified relations 

(def doknil-db
  (make-database
   (relation :role [:id :instance-id])
   ;; the instance-id is the description of the role
   
   (relation :role-hierarchy [:child-role-id :parent-role-id])
   (index :role-hierarchy :id)
   ;; a role has a unique hierarchy
   
   (relation :context-hierarchy [:id :child-instance-id :parent-instance-id])
   ;; they are all primary-keys because for the same :id there are different parts of the chain

   (relation :context-override [:context-hierarchy-id :overridden-context-hierarchy-id])
   
   (relation :context-include [:context-hierarchy-id :included-context-hierarchy-id])
   
   (relation :part [:child-instance-id :parent-instance-id :context-hierarchy-id])
   
   (relation :isa [:fact-id :instance-id :role-id :part-id :context-hierarchy-id])
   
   ))

;; TODO I'm interested to direct-instances of context and part
;; TODO use the fact-id for returning the more precise fact of a rule

(def rules
 (rules-set
  (<- ())
  
  )
)

;; TODO represent some demo Doknil data and query it as test
;; TODO write some automatic unit-test for testing and documenting all

;; TODO use example code like in https://github.com/fogus/bacwn/blob/master/examples/employees/example.clj
