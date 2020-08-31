;; SPDX-License-Identifier: MIT
;; Copyright (C) 2020 Massimo Zaniboni <mzan@dokmelody.org>

#lang racket/base

(require racket/cmdline
         racket/match
         rackunit/text-ui)

(require "doknil/runtime.rkt"
         "doknil/compiler.rkt"
         "doknil/parser.rkt"
         "tests/doknil-test.rkt"
         "dokmelody/web-app.rkt")

(define execute-tests (make-parameter #f))
(define execute-web-app (make-parameter #f))
(define execute-hello-world (make-parameter #f))

(command-line
   #:once-any
   ["--test" "Execute unit tests" (execute-tests #t)]
   ["--start-web-app" "Launch a web server application" (execute-web-app #t)]
   ["--hello-world" "Print hello world" (execute-hello-world #t)])

(cond
  [(execute-hello-world) (println "Hello World!")]
  [(execute-tests) (run-tests test-doknil)]
  [(execute-web-app) (start-web-app)]
)

;; TODO it print a '() and I don't know why!?
