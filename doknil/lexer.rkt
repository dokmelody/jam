;; SPDX-License-Identifier: MIT
;; Copyright (C) 2020 Massimo Zaniboni <mzan@dokmelody.org>

#lang racket

(provide tokenizer)

(require br-parser-tools/lex
         brag/support)
(require (prefix-in : br-parser-tools/lex-sre))

(define (tokenizer ip)
  (port-count-lines! ip)

  (define-lex-abbrev id2 (:* (:or alphabetic numeric #\_)))

  (define my-lexer
    (lexer-src-pos

       ["-->"
        (token "-->" lexeme)]

       ["{"
        (token "{" lexeme)]

       ["}"
        (token "}" lexeme)]

       ["("
        (token "(" lexeme)]

       [")"
        (token ")" lexeme)]

       ["/"
        (token "/" lexeme)]

       ["."
        (token "." lexeme)]

       [(:or "isa" "is")
        (token 'ISA lexeme)]

       [(:: #\$ (:or lower-case upper-case) id2)
        (token 'OBJ lexeme)]

       [(:: lower-case id2)
        (token 'ID lexeme)]

       [(:: upper-case id2)
        (token 'CNTX lexeme)]

       [(:: "#" (:* (char-complement #\newline)))
        (token 'COMMENT lexeme #:skip? #t)]

       [whitespace
        (token 'WHITESPACE lexeme #:skip? #t)]
      
       [(eof)
        (void)]))

  (define (my-fun) (my-lexer ip))
  my-fun)
