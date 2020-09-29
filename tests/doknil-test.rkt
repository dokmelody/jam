;; SPDX-License-Identifier: MIT
;; Copyright (C) 2020 Massimo Zaniboni <mzan@dokmelody.org>

#lang racket/base

(provide test-doknil)

(require datalog
         racket/set
         racket/function
         rackunit
         rackunit/text-ui
         racket/serialize
         "../doknil/runtime.rkt")

(define (check-query? description datalog-query-result results)
    "Normalize datalog and user result, and compare them."

    (check-equal?
     (list->set (map (lambda (h) (make-immutable-hash (hash->list h))) datalog-query-result))
     (list->set (map (lambda (xs) (make-immutable-hash xs)) results))))


(define test-doknil
  (test-suite "Doknil semantic"

  (datalog doknil-db

    ;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;; Define roles

    (! (role related #f #f))
    (! (role task #t related))
    (! (role issue #t task))

    (! (role company #t #f))
    (! (role department #t company))

    (! (branch world #f))
    (! (cntx cntx-world world #f))

    ;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;; Company example

    (! (isa-fact fact-part-1 cntx-world acme-corporation company #f))
    (! (isa-fact fact-part-2 cntx-world department-x department acme-corporation))
    (! (isa-fact fact-1 cntx-world issue-1 issue department-x))

    ;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;; Try different branches

    (! (branch earth world))
    (! (branch tolkien earth))

    (! (cntx cntx-earth earth #f))
    (! (cntx cntx-places earth cntx-earth))
    (! (cntx cntx-tolkien tolkien #f))
    (! (cntx cntx-tolkien-places tolkien cntx-tolkien))
    (! (exclude-cntx cntx-tolkien-places cntx-places))

    (! (role nation #f #f))
    (! (role city #t related))

    (! (isa-fact fe-1 cntx-places italy nation #f))
    (! (isa-fact fe-2 cntx-places rome city italy))

    (! (isa-fact ft-1 cntx-tolkien-places middle-earth nation #f))
    (! (isa-fact ft-2 cntx-tolkien-places gondor city middle-earth)))


  (check-query?
    "Role hierarchy"
    (datalog doknil-db (? (role-rec issue PARENT-ROLE IS-PART-OF)))
    (list (list (cons 'PARENT-ROLE 'issue) (cons 'IS-PART-OF #t))
          (list (cons 'PARENT-ROLE 'task)  (cons 'IS-PART-OF #t))
          (list (cons 'PARENT-ROLE 'related) (cons 'IS-PART-OF #f))))

  (check-query?
    "Inheritance of facts 1"
    (datalog doknil-db (? (isa world issue-1 issue IS-PART-OF OBJECT CNTX FACT)))
    (list (list (cons 'IS-PART-OF #t) (cons 'OBJECT 'acme-corporation) (cons 'CNTX 'cntx-world) (cons 'FACT 'fact-1))
          (list (cons 'IS-PART-OF #t) (cons 'OBJECT 'department-x) (cons 'CNTX 'cntx-world) (cons 'FACT 'fact-1))
          ))

  (check-query?
    "Inheritance of facts 2"
    (datalog doknil-db (? (isa world issue-1 related IS-PART-OF OBJECT CNTX FACT)))
    (list (list (cons 'IS-PART-OF #f) (cons 'OBJECT 'acme-corporation) (cons 'CNTX 'cntx-world) (cons 'FACT 'fact-1))
          (list (cons 'IS-PART-OF #f) (cons 'OBJECT 'department-x) (cons 'CNTX 'cntx-world) (cons 'FACT 'fact-1))
          ))

  (check-query?
    "Inheritance of facts 3"
    (datalog doknil-db (? (isa world issue-1 task IS-PART-OF OBJECT CNTX FACT)))
    (list (list (cons 'IS-PART-OF #t) (cons 'OBJECT 'acme-corporation) (cons 'CNTX 'cntx-world) (cons 'FACT 'fact-1))
          (list (cons 'IS-PART-OF #t) (cons 'OBJECT 'department-x) (cons 'CNTX 'cntx-world) (cons 'FACT 'fact-1))
    ))


  (check-query?
    "Cntx branch 1"
    (datalog doknil-db (? (isa earth CITY city IS-PART-OF OBJECT CNTX FACT)))
    (list (list (cons 'CITY 'rome) (cons 'IS-PART-OF #t) (cons 'OBJECT 'italy) (cons 'CNTX 'cntx-places) (cons 'FACT 'fe-2))
          ))

  (check-query?
    "Cntx branch 2"
    (datalog doknil-db (? (isa tolkien CITY city IS-PART-OF OBJECT CNTX FACT)))
    (list (list (cons 'CITY 'gondor) (cons 'IS-PART-OF #t) (cons 'OBJECT 'middle-earth) (cons 'CNTX 'cntx-tolkien-places) (cons 'FACT 'ft-2))
    ))
))
