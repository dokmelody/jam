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
                [:role-hierarchy :child-role-id :Issue :parent-role-id :RelatedTo]

                [:context-hierarchy :id :world-context :instance-id :world :child-hierarchy-id :nil]

                [:part :child-instance-id :department-x :parent-instance-id :acme-corporation :context-hierarchy-id :world-context]

                [:isa-fact :fact-id :fact-1 :instance-id :issue-1 :role-id :Issue :part-id :department-x :context-hierarchy-id :world-context]))

(deftest test-doknil
  (testing "Extensional fact"
    (is (= :fact-1 
        (get (first 
         (run-work-plan 
           doknil/query-1 
           db 
           {'??instance-id :issue-1
            '??role-id :Issue
            '??context-id :world-context})) :fact)))))
  
  (testing "Role hierarchy"
    (is (= :fact-1
           (get (first
               (run-work-plan doknil/query-1 db {'??instance-id :issue-1
                                                 '??role-id :RelatedTo
                                                 '??context-id :world-context}))
                :fact))))
  
     
