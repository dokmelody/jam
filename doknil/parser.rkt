;; SPDX-License-Identifier: MIT
;; Copyright (C) 2020 Massimo Zaniboni <mzan@dokmelody.org>

#lang racket

(require brag/support)
(require "lexer.rkt")
(require "grammar.rkt")

(define test-src (open-input-string #<<DOKNIL-SRC
# Comment 1
# Comment 2

/related to --> (
  /task of --> (
    /issue of
  )
)

$subj isa subject of $obj

$subj2 isa subject2 of $obj2

$subj3 isa subject3

World --> {
  Tolkien/LordOfTheRings.cities --> {
    $gondor isa city of $middleEarth
  }
}

DOKNIL-SRC
))

(define token-thunk (tokenizer test-src))

(define test-stx (parse token-thunk))
(syntax->datum test-stx)
