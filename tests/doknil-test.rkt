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

    (! (role related to #f))
    (! (role task of related))
    (! (role issue of task))

    (! (role company of #f))
    (! (role department of company))

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
    (! (role city of related))

    (! (isa-fact fe-1 cntx-places italy nation #f))
    (! (isa-fact fe-2 cntx-places rome city italy))

    (! (isa-fact ft-1 cntx-tolkien-places middle-earth nation #f))
    (! (isa-fact ft-2 cntx-tolkien-places gondor city middle-earth)))


  (check-query?
    "Role hierarchy"
    (datalog doknil-db (? (role-rec issue PARENT-ROLE COMPLEMENT)))
    (list (list (cons 'PARENT-ROLE 'issue) (cons 'COMPLEMENT 'of))
          (list (cons 'PARENT-ROLE 'task)  (cons 'COMPLEMENT 'of))
          (list (cons 'PARENT-ROLE 'related) (cons 'COMPLEMENT 'to))))

  (check-query?
    "Inheritance of facts 1"
    (datalog doknil-db (? (isa world issue-1 issue COMPLEMENT OBJECT CNTX FACT)))
    (list (list (cons 'COMPLEMENT 'of) (cons 'OBJECT 'acme-corporation) (cons 'CNTX 'cntx-world) (cons 'FACT 'fact-1))
          (list (cons 'COMPLEMENT 'of) (cons 'OBJECT 'department-x) (cons 'CNTX 'cntx-world) (cons 'FACT 'fact-1))
          ))

  (check-query?
    "Inheritance of facts 2"
    (datalog doknil-db (? (isa world issue-1 related COMPLEMENT OBJECT CNTX FACT)))
    (list (list (cons 'COMPLEMENT 'to) (cons 'OBJECT 'acme-corporation) (cons 'CNTX 'cntx-world) (cons 'FACT 'fact-1))
          (list (cons 'COMPLEMENT 'to) (cons 'OBJECT 'department-x) (cons 'CNTX 'cntx-world) (cons 'FACT 'fact-1))
          ))

  (check-query?
    "Inheritance of facts 3"
    (datalog doknil-db (? (isa world issue-1 task COMPLEMENT OBJECT CNTX FACT)))
    (list (list (cons 'COMPLEMENT 'of) (cons 'OBJECT 'acme-corporation) (cons 'CNTX 'cntx-world) (cons 'FACT 'fact-1))
          (list (cons 'COMPLEMENT 'of) (cons 'OBJECT 'department-x) (cons 'CNTX 'cntx-world) (cons 'FACT 'fact-1))
    ))


  (check-query?
    "Cntx branch 1"
    (datalog doknil-db (? (isa earth CITY city COMPLEMENT OBJECT CNTX FACT)))
    (list (list (cons 'CITY 'rome) (cons 'COMPLEMENT 'of) (cons 'OBJECT 'italy) (cons 'CNTX 'cntx-places) (cons 'FACT 'fe-2))
          ))

  (check-query?
    "Cntx branch 2"
    (datalog doknil-db (? (isa tolkien CITY city COMPLEMENT OBJECT CNTX FACT)))
    (list (list (cons 'CITY 'gondor) (cons 'COMPLEMENT 'of) (cons 'OBJECT 'middle-earth) (cons 'CNTX 'cntx-tolkien-places) (cons 'FACT 'ft-2))
    ))
))
