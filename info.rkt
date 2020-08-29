;; SPDX-License-Identifier: MIT
;; Copyright (C) 2020 Massimo Zaniboni <mzan@dokmelody.org>

#lang info


(define version "0.1")
(define collection "dokmelody-repl-it-jam")

(define pkg-desc "A quick prototype of Dok programming language, DokMelody IDE, and Doknil knowledge-base language, developed for the 2020 https://repl.it Programming Language Jam.")

(define deps '("base"
               "datalog"
               "browser"
               "web-server"
               "nanopass"
               "scribble-lib"
               "racknuti-lib"))

(define test-include-paths '("tests"))
