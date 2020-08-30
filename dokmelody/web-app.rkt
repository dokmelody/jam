;; SPDX-License-Identifier: MIT
;; Copyright (C) 2020 Massimo Zaniboni <mzan@dokmelody.org>

#lang racket

(provide start-web-app)

(require
   web-server/servlet
   web-server/servlet-env)

(define (hello-servlet req)
  (response/xexpr
   `(html
     (head)
     (body
      (p "Hello, world!")))))

(define (start-web-app)
  (serve/servlet
    hello-servlet
    #:launch-browser? #f
    #:stateless? #t
    #:quit? #f
    #:listen-ip #f
    #:port 8000
))
