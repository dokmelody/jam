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

;; TODO use example code like in https://github.com/fogus/bacwn/blob/master/examples/employees/example.clj
