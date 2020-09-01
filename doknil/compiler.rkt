;; SPDX-License-Identifier: MIT
;; Copyright (C) 2020 Massimo Zaniboni <mzan@dokmelody.org>

#lang racket

(require datalog)
(require nanopass)
(require syntax/parse syntax/stx)
(require "lexer.rkt")
(require "grammar.rkt")

;; TODO find a way to link a clojure value/object to a database statment
;; MAYBE insert the distance of CONTEXT and PARENT in the derived relation
;; TODO select the nearest card in the UI using the DISTANCE attribute
;; TODO a card can read from a file on resource directories
;; TODO the card-db is a function returning a card as a value, given a card name/index
;; TODO caching of cards allows to avoid regeneration of all cards
;; TODO order also relations by transitive closure
;; TODO cache/memoize the generation of a card
;; TODO store facts inside resources or similar
;; TODO during reading the title include the context "R1/R0" with "R0" being the parent
;; TODO create a map with complete-hiearchy as a vector and used as key, and the ``context-hierarchy-id`` as value.
;; It will be used for creating new contexts on demand.
;; Then they will be inserted exploded inside ``doknil-db``.
;; TODO find if Refs, Vars or Atoms must be used for adding new facts inside doknil-db at run-time
;; MAYBE make the same thing for part and role hierarchies
;;
;; TODO store in a map/db the assocation between key and card object
;;
;; TODO add index later to the db schema, according the type of queries to do
;; TODO contexts must be added to the DB according their effective usage because every new hierarchy is a new id,
;; or use instead an hash map of the complete hiearchy
;; TODO use a defalt NULL/nil value for some of the specified relations
;; TODO when a new hierarchy is added, then all sub-hierarchies (if news) are added
;; TODO store in a data structure apart the associations between ids and complete hierarchy name
;; TODO use this same structure for lookup during parsing
;; TODO the same for roles, and all other Doknil elements
;; TODO create an id for ``world`` and for the empty context-group. Using an id is more coherent on the UI and query side
;; TODO create a lookup function for passing from hierarchy names to id

;; TODO make sure to register also roles without a parent
;; TODO it is important showing explicitely overriden contexts
;; TODO in queries one can only specify branches without groups

;; TODO check that cntx itself is returned, and so no facts are left behind
;; TODO check that all ``of`` relationships have no child role without ``of`` COMPLEMENT
;; TODO report the reason in the manual

;; TODO support a sort of stratified negation for inclusion of branches
;; TODO The problem of Racket API for excluding CNTX, it is that it can influence also the
;; is-part-of relationship, and this is-part-of can be defined in a branch but not in another
;; so I had to exclude before and not after the query

;; TODO first define the nanopass version, then define the parser later, when I know the AST to generate

;; TODO add tests informing of errors in a Doknil code
;; * TODO add test to the compiler
;; * TODO test in regression unit tests checking for compilation errors
;; * TODO document in the manual

;; TODO these are the terms to use
;; Store a role hierarchy like ``Task/Issue``.
;; A role has a unique parent.
;; For roles without a parent set parent to #f
;; COMPLEMENT is the ``of``, ``for``, ``to``, etc.. complement linking
;; the subject of a fact with its object.
;; Only COMPLEMENT of type ``of`` derive also a ``part-of`` relationship.
;;
;; A constraint it is that a child ROLE with a COMPLEMENT not of type ``of``
;; can not have a parent ROLE with COMPLEMENT ``of``. The reason it is that
;; all ``of`` relationships must be explicit at the moment of the definition
;; of the extensional fact, and not unexpected.
;;
;; > (! (role ID COMPLEMENT PARENT))
;;
;; The branch of a context. Something like ``world/x/y``.
;;   The root context branch `world` has parent set to #f, and the special id 0
;; > (! (branch ID PARENT))
;;
;; A cntx branch and an optional group.
;; Something like ``world/x/y.a.b.c``.
;; The PARENT manage only the group part, so the BRANCH must remain constant
;; in the same hierarchy.
;;
;; > (cntx ID BRANCH PARENT)

;; Something like ``dstContext.some.group --> { !include some/source/cntx.another.group.cntx }``
;;
;; > (include-cntx DST-CNTX SRC-CNTX)

;; Something like ``dstContext.some.group --> { !exclude some/source/cntx.another.group.cntx }``
;;
;; > (exclude-cntx DST-CNTX SRC-CNTX)

;; Store the Role relationship of a fact.
;; Something like ``world/x/y.a.b --> { e isa Something for c }``
;;
;; OBJECT is set to nil if it is not specified.
;;
;; > (isa-fact ID CNTX INSTANCE ROLE OBJECT)

;; TODO first make cntx like a top-down attribute
;; TODO then convert to a language where context is explicit and assigned to each statement

;; TODO add include and exclude to the syntax

;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Parse source code to a Grammar Syntax Tree

(define (instance? x) (symbol? x))

(define (role? x) (symbol? x))

(define (complement? x) (symbol? x))

(define (cntx-branch? x) (symbol? x))

(define (cntx-group? x) (symbol? x))

;; A language rather similar to Grammar Syntax Tree,
;; so the conversion from the parsed one is simplified.
(define-language L0
  (entry KB)
  (terminals
   (instance (subj obj))
   (role (role))
   (complement (of))
   (cntx-branch (branch))
   (cntx-group (group)))

  (KB (kb)
      (knowledge-base stmt* ...))

  (RoleDef (role-def)
    (role-deff role role-def* ...))

  (Stmt (stmt)
        (cntx-include (branch* ...) group?)
        (cntx-exclude (branch* ...) group?)
        (is subj role)
        (isa subj role of obj)
        (role-defff role-def)
        (cntx (branch* ...) (group* ...) (stmt* ...))
        )
)

(define-parser parse-L0 L0)

#|
TODO complete

(define (grammar->L0 stx)

  (define (role-def->r stx)
    (syntax-parse stx
      [ ((~literal role-def) "/" ((~literal role) r) ((~literal complement) c) "-->" "(" rs ... ")")
        (with-output-language (L0 RoleDef)
          (let ((rds (map (curry role-def->r) (syntax->list #'(rs ...)))))
               `(role-deff ,(string->symbol (syntax->datum #'r)) ,rds ...)))
        ]

      [ ((~literal role-def) "/" ((~literal role) r) ((~literal complement) c))
        (with-output-language (L0 RoleDef)
           `(role-deff ,(string->symbol (syntax->datum #'r))))
      ]))

  ; TODO adapt this code and return a list of branches to use in other functions
  (define (branch->r stx)
    (syntax-parse stx
      [ ((((~literal branch) branch) ...) (~optional ((~literal group) "." group)))
        (let ((branch->l0 (map () (syntax->list #'(branch ...)))  ))
         (with-output-language (L0 Stmt)
           (let ((rds (map (curry role-def->r) (syntax->list #'(rs ...)))))
             ; TODO push every branch
             ; TODO for the last branch push also the group in case if it exists
               `(push-cntx ,(string->symbol (syntax->datum #'r)) ,rds ...)))

        ]

  (define (def->r stx)
    (syntax-parse stx
      [ ((~literal stmt) ((~literal subject) subj) isa ((~literal role) role))
        (with-output-language (L0 Stmt)
           `(is ,(string->symbol (syntax->datum #'subj)) ,(string->symbol (syntax->datum #'role))))
        ]

      [ ((~literal stmt) ((~literal subject) subj) isa ((~literal role) role) ((~literal complement) complement) ((~literal object) obj))
        (with-output-language (L0 Stmt)
           `(is ,(string->symbol (syntax->datum #'subj)) ,(string->symbol (syntax->datum #'role)) ,(string->symbol (syntax->datum #'role))))
        ]

      ; TODO adapt
      [ ((~literal stmt) ((~literal cntx) ((~literal branch) branch ...) (~optional ((~literal group) "." group)))

                          subj) isa ((~literal role) role) ((~literal complement) complement) ((~literal object) obj))
        (with-output-language (L0 Stmt)
           `(is ,(string->symbol (syntax->datum #'subj)) ,(string->symbol (syntax->datum #'role)) ,(string->symbol (syntax->datum #'role))))
      ]

      [ (r ...) (role-def->r #'(r ...))]))

  (syntax-parse stx
    [((~literal kb) ~rest rs)
     (map (curry def->r) (syntax->list #'rs))]
  ))
|#

;; TODO
#|
(stmt (cntx (branch "World")) "-->" "{" (stmt (cntx (branch "Tolkien" "/" "LordOfTheRings") (group "." "cities")) "-->" "{"
|#

;; TODO
#|
(define (debug src)
  (define token-thunk (tokenizer src))
  (define stx (parse token-thunk))
  (println (syntax->datum stx))
  (println (grammar->L0 stx))
)

(define test-src1 (open-input-string #<<DOKNIL-SRC
# Comment 1
# Comment 2

/related to

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

(define test-src2 (open-input-string #<<DOKNIL-SRC
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


(debug test-src2)
|#
