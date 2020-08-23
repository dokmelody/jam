;; SPDX-License-Identifier: MIT
;; Copyright (C) 2020 Massimo Zaniboni <mzan@dokmelody.org>

(ns org.dokmelody.jam.test.doknil
  (:require [fogus.datalog.bacwn.impl.literals :as literals]
            [clojure.test :refer :all]
            [org.dokmelody.jam.doknil.core :refer :all :as doknil])
  (:use 
        [fogus.datalog.bacwn :only (build-work-plan run-work-plan)]
        [fogus.datalog.bacwn.macros :only (<- ?- make-database)]
        [fogus.datalog.bacwn.impl.rules :only (rules-set)]
        [fogus.datalog.bacwn.impl.database :only (add-tuples)]))

(def db
    (add-tuples doknil/schema
                [:role :id :Issue :parent :RelatedTo]
                [:role :id :RelatedTo :parent nil]
                
                [:role :id :Department :parent nil]
                [:role :id :Company :parent nil]

                [:branch :id :world :parent nil]
                
                [:cntx :id :cntx-world :branch :world :parent nil]
                
                [:isa-fact :id :fact-part-1 :cntx :cntx-world :instance :acme-corporation :role :Company :part nil]
                [:isa-fact :id :fact-part-2 :cntx :cntx-world :instance :department-x :role :Department :part :acme-corporation]

                [:isa-fact :id :fact-1 :cntx :cntx-world :instance :issue-1 :role :Issue :part :department-x]))

(deftest test-doknil
  (testing "Extensional fact"
    (is (= :fact-1 
        (get (first 
         (run-work-plan 
           doknil/query-isa-1 
           db 
           {'??branch :world
            '??instance :issue-1
            '??role-id :Issue
            })) :fact)))))
  
  (testing "Role hierarchy"
    (is (= :fact-1
           (get (first
               (run-work-plan 
                  doknil/query-isa-1 
                  db 
                  {'??branch :world
                   '??instance :issue-1
                   '??role :RelatedTo
                  }))
                :fact))))
    
