;; SPDX-License-Identifier: MIT
;; Copyright (C) 2020 Massimo Zaniboni <mzan@dokmelody.org>

#lang racket/base

(require "doknil/semantic.rkt")

(provide (all-from-out "doknil/semantic.rkt"))

(require datalog)

(datalog family
         (? (ancestor A B)))
