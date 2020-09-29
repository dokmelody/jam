;; SPDX-License-Identifier: MIT
;; Copyright (C) 2020 Massimo Zaniboni <mzan@dokmelody.org>

#lang info

(define name "dokmelody-repl-it-jam-2020")
(define version "0.1")
(define collection "dokmelody")

(define pkg-desc "A quick prototype of Dok programming language, DokMelody IDE, and Doknil knowledge-base language, developed for the 2020 https://repl.it Programming Language Jam.")

(define deps '("base"
               "datalog"
               "web-server"
               "nanopass"
               "parser-tools-lib"
               "brag-lib"
               "br-parser-tools-lib"
               "scribble-lib"
               "threading-lib"
               "axe"
               "debug"
               "rackunit"))

(define test-include-paths '("tests"))
