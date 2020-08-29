;; SPDX-License-Identifier: MIT
;; Copyright (C) 2020 Massimo Zaniboni <mzan@dokmelody.org>

#lang web-server/insta

(define (start request)
  (response/xexpr
   '(html
     (head (title "DokMelody"))
     (body (h1 "Under construction")))))
