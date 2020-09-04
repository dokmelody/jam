;; SPDX-License-Identifier: MIT
;; Copyright (C) 2020 Massimo Zaniboni <mzan@dokmelody.org>

#lang racket

(require datalog)
(require nanopass)
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

;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Syntax Tree

(define (instance? x) (symbol? x))

(define (role? x) (symbol? x))

(define (complement? x) (symbol? x))

(define (cntx-branch? x) (symbol? x))

(define (cntx-group? x) (symbol? x))

;; A language similar to the Syntax Tree generated from the parse,
;; so it is easier to generate during parsing.
(define-language L0
  (entry KB)
  (terminals
   (instance (subj obj))
   (role (role))
   (complement (of))
   (cntx-branch (branch))
   (cntx-group (group)))

  (KB ()
      (knowledge-base (role-def* ...) (stmt* ...)))

  (RoleDef (role-def)
    (role-children role of (role-def* ...)))

  (Cntx (cntx)
    (cntx-ref (branch* ...) (group* ...)))

  (Stmt (stmt)
        (cntx-include cntx)
        (cntx-exclude cntx)
        (is subj role)
        (isa subj role of obj)
        (role-deff role-def)
        (cntx-def cntx (stmt* ...))
        )
)

(define-parser parse-L0 L0)

;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Parser: read the text and produce a syntax tree in L0

(define (doknil-parser in-str)
  (define token-thunk (doknil-lexer in-str))
  (define root (parse-to-datum token-thunk))

  (define (role-def/m root)
     (match root
       ((list 'role-def "/" (list 'role name) complement)
          `(role-children ,(string->symbol name) ,(string->symbol complement) ()))
       ((list 'role-def "/" (list 'role name) complement (list 'role-children "-->" "(" children ... ")"))
          `(role-children ,(string->symbol name) ,(string->symbol complement) ,(map role-def/m children)))
       ))

  (define (hierarchy-sep-by s rs)
    (define ss (string->symbol s))
    (filter (lambda (x) (not (eq? x ss))) (map string->symbol rs)))

  (define (cntx/m root)
    (match root
      ((list 'cntx (list 'branch cntx ...) (list 'group group ...))
        `(cntx-ref ,(hierarchy-sep-by "/" cntx) ,(hierarchy-sep-by "." group)))))

  (define (kb-role-def/m part)
    (match part
      ((list 'role-def _ ...) (role-def/m part))
       (other #f)
    ))

  (define (kb-stmt-part/m part)
    (match part
      ((list 'include-cntx (list "!include" cntx))
       `(cntx-include ,(cntx/m cntx)))

      ((list 'exclude-cntx (list "!include" cntx))
       `(cntx-exclude ,(cntx/m cntx)))

      ((list (list 'subject subj) isa (list 'role role))
       `(is ,(string->symbol subj) ,(string->symbol role)))

      ((list (list 'subject subj) isa (list 'role role) (list 'complement of (list 'object obj)))
       `(isa ,(string->symbol subj) ,(string->symbol role)  ,(string->symbol of) ,(string->symbol obj)))

      ((list (list 'cntx (list 'branch cntx ...) (list 'group group ...)) "-->" "{" stmts ... "}")
       `(cntx-def (cntx-ref ,(hierarchy-sep-by "/" cntx) ,(hierarchy-sep-by "." group)) ,(map kb-stmt/m stmts)))

    ))

  (define (kb-stmt/m stmt)
    (match stmt
      ((list 'stmt rs ...)
       (kb-stmt-part/m rs))

      ((list 'role-def _ ...)
       #f)
      ))

  ; Entry point
  (match root
    ((list 'kb stmts ...)
     `(knowledge-base ,(filter-map kb-role-def/m stmts) ,(filter-map kb-stmt/m stmts))))
)

;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Some examples of code

(define test-src0 #<<DOKNIL-SRC
# Comment 1
# Comment 2

/related to

/again to


$subj isa role

DOKNIL-SRC
)


(define test-src1 #<<DOKNIL-SRC
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
)

(define test-src2 #<<DOKNIL-SRC
# Comment 1
# Comment 2

/related to --> (
  /task of --> (
    /issue of
  )
  /task2 of
)
/another of
/again of

$subj isa subject of $obj

$subj2 isa subject2 of $obj2

$subj3 isa subject3

World --> {
  !include Some/Other/Cntx.some.other.group
  !exclude Othe/Cntx.group

  Tolkien/LordOfTheRings.cities --> {
    $gondor isa city of $middleEarth
  }
}

DOKNIL-SRC
)

(define test-src3 #<<DOKNIL-SRC
# Comment 1
# Comment 2

/role1 of

/role2 of --> (
  /role3 from
  /rola4 again
  /role5 from --> (
    /role51 again2
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
)

;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Debug

(define (debug src)
  (define token-thunk (doknil-lexer (open-input-string src)))
  (parse-to-datum token-thunk)
)

(debug test-src3)

(doknil-parser (open-input-string test-src3))

(parse-L0 (doknil-parser (open-input-string test-src3)))

