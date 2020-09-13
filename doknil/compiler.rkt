;; SPDX-License-Identifier: MIT
;; Copyright (C) 2020 Massimo Zaniboni <mzan@dokmelody.org>

#lang racket

(require racket/base
         datalog
         nanopass
         threading
         "lexer.rkt"
         "grammar.rkt"
         "runtime.rkt")

;; TODO contexts must be added to the DB according their effective usage because every new hierarchy is a new id,
;; or use instead an hash map of the complete hiearchy
;; TODO use a defalt NULL/nil value for some of the specified relations
;; TODO when a new hierarchy is added, then all sub-hierarchies (if news) are added
;; TODO store in a data structure apart the associations between ids and complete hierarchy name
;; TODO use this same structure for lookup during parsing
;; TODO the same for roles, and all other Doknil elements
;; TODO create an id for ``world`` and for the empty context-group. Using an id is more coherent on the UI and query side
;; TODO make sure to register also roles without a parent
;; TODO it is important showing explicitely overriden contexts
;; TODO in queries one can only specify branches without groups
;; TODO check that cntx itself is returned, and so no facts are left behind
;; TODO check that all ``of`` relationships have no child role without ``of`` COMPLEMENT
;; TODO update tests using the compiler API
;; MAYBE remove complement from the run-time
;; TODO add info about cntxt composition probably calculating it apart
;; TODO cntx info became a single ID and not a chain and then a data structure memorize the hierarchy
;; TODO move again in role-def the single name of a group part or cntx or role
;; TODO refactor role generation and move the name inside the def again, because now it is compact
;; TODO create a unique context-id for each definition
;; TODO support definitions in advance
;; TODO replace them with facts
;; MAYBE add hierarchy of cntx and groups inside the map

;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Nanopass languages

(define (instance? x) (symbol? x))

(define (role? x) (symbol? x))

(define (complement? x) (or (eq? x #f) (symbol? x)))

(define (cntx-branch? x) (symbol? x))

(define (cntx-group? x) (symbol? x))

(define (name? x) (string? x))

;; A language similar to the Syntax Tree generated from the parser,
;; so it is easier to generate during parsing.
(define-language L0
  (entry KB)
  (terminals
   (instance (subj obj))
   (role (role))
   (complement (of))
   (cntx-branch (branch))
   (cntx-group (group))
   (name (name)))

  (KB (kb)
      (knowledge-base (role-def* ...) (stmt* ...)))

  (RoleDef (role-def)
    (role-children role (maybe of?) (role-def* ...)))

  (Cntx (cntx)
    (cntx-ref (branch* ...) (group* ...)))

  (Stmt (stmt)
        (cntx-include cntx)
        (cntx-exclude cntx)
        (is subj role)
        (isa subj role of obj)
        (cntx-def cntx (stmt* ...))
        )
)

(define-parser parse-L0 L0)

(define (db-id? x) fixnum? x)

;; Replace identifiers with compact integer ID.
;; Remove ``of`` and use only a ``role`` identifier.
(define-language L1
  (extends L0)
  (terminals
   (- (instance (subj obj))
      (role (role))
      (complement (of))
      (cntx-branch (branch))
      (cntx-group (group))
      )
   (+ (db-id (id subj obj
                 role parent-role
                 branch group
                 cntx-id parent-cntx-id branch-id parent-branch-id))))

  (RoleDef (role-def)
           (- (role-children role (maybe of?) (role-def* ...)))
           (+ (role-children role (role-def* ...))))

  (Stmt (stmt)
        (- (isa subj role of obj))
        (+ (isa subj role obj))))


;; Transform role-def hierarchy from list of children to parent pointer.
(define-language L2
  (extends L1)

  (RoleDef (role-def)
           (- (role-children role (role-def* ...)))
           (+ (role-children (maybe parent-role?) role))))

#|
;; Transform role-def hierarchy from list of children to parent pointer,
;; and flatten the cntx info into a unique id for an hierarchy of branches and groups.
(define-language L2
  (extends L1)

  (KB (kb)
      (- (knowledge-base (role-def* ...) (stmt* ...)))
      (+ (knwoledge-base (role-def* ...) (branch-def* ...) (cntx-def* ...) (stmt* ...))))

  (RoleDef (role-def)
           (- (role-children role (role-def* ...)))
           (+ (role-children (maybe parent-role?) role)))

  (BranchDef (branch-def)
             (+ (branch-def (maybe parent-branch-id?) branch-id name)))

  (CntxDef (cntx-def)
           (+ (cntx-def branch-id (maybe parent-cntx-id) cntx-id name)))

  (Stmt (stmt)
        (- (isa subj role obj)
           (is subj role)
           (cntx-def cntx (stmt* ...))
           (cntx-include cntx)
           (cntx-exclude cntx)
        )

        (+ (isa cntx-id subj role obj)
           (is cntx-id subj role)
        ))
  )
|#

;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Nanopass transformers

;; Create a unique and compact integer id for each name and complement pair.
;; Use #f as complement, when complement is not applicable.
(struct dbids
  ([count #:mutable] ; int
   to-name   ; int -> (name . (complement | #f))
   from-name ; (name . (complement | #f)) -> int
   ))

(define (make-dbids)
   (dbids 1 (make-hash) (make-hash)))

; Get or create the dbid associated to the name and complement.
; symbol | string -> symbol | string | #f -> int
(define (dbids-id! dbids name complement)
      (define complete-name (cons name complement))

      (hash-ref
         (dbids-from-name dbids)
         complete-name
         (lambda ()
           (define rid (dbids-count dbids))
           (hash-set! (dbids-from-name dbids) complete-name rid)
           (hash-set! (dbids-to-name dbids) rid complete-name)
           (set-dbids-count! dbids (+ 1 rid))
           rid)))

(define (dbids-name dbids dbid)
  (hash-ref (dbids-to-name dbids) dbid (lambda () #f)))

(define-pass L0->L1-dbids : L0 (kb) -> L1 (dbids)
  (definitions

    (define dbids (make-dbids)))

    (KB : KB (K) -> KB ()
        [(knowledge-base (,[role-def*] ...) (,[stmt*] ...))
         `(knowledge-base (,role-def* ...) (,stmt* ...))])

    (RoleDef : RoleDef (R) -> RoleDef ()
           [(role-children ,role ,of? (,[role-def*] ...))
            `(role-children ,(dbids-id! dbids role of?) (,role-def* ...))]
           )

    (Cntx : Cntx (C) -> Cntx ()
          [(cntx-ref (,branch* ...) (,group* ...))
           `(cntx-ref (,(map (lambda (x) (dbids-id! dbids x #f)) branch*))
                      (,(map (lambda (x) (dbids-id! dbids x #f)) group*)))])

    (Stmt : Stmt (S) -> Stmt ()
         [(cntx-include ,[cntx])
          `(cntx-include ,cntx)]

         [(cntx-exclude ,[cntx])
          `(cntx-exclude ,cntx)]

         [(is ,subj ,role)
          `(is ,(dbids-id! dbids subj #f)
               ,(dbids-id! dbids role #f))]

         [(isa ,subj ,role ,of ,obj)
          `(isa ,(dbids-id! dbids subj #f)
                ,(dbids-id! dbids role of)
                ,(dbids-id! dbids obj #f))]

         [(cntx-def ,[cntx] (,[stmt*] ...))
          `(cntx-def ,cntx (,stmt* ...))])

  (values (KB kb) dbids))

(define-pass L0->L1 : L0 (kb) -> L1 ()
  (let-values ([(r1 r2) (L0->L1-dbids kb)]) r1))


(define-pass L1->L2 : L1 (kb) -> L2 ()
    (KB : KB (K) -> KB ()
        [(knowledge-base (,role-def* ...) (,[stmt*] ...))
         (let* ([role-def** (flatten (map (lambda (x) (flatRoleDef x #f)) role-def*))])
           `(knowledge-base (,role-def** ...) (,stmt* ...)))])

    (flatRoleDef : RoleDef (rc parent) -> * (rds)
                 [(role-children ,role (,role-def* ...))
                  (cons
                   (with-output-language (L2 RoleDef) `(role-children ,parent ,role))
                   (map (lambda (x) (flatRoleDef x role)) role-def*))]))


#|
(define-pass collect-role-defs : L1 (kb) -> * (list-of-role-defs)

    (KB : KB (kb) -> * (list-of-role-defs)
        [(knowledge-base (,role-def* ...) (,stmt* ...))
        (append* (map (curry collect-role-defs) stmt*))])

    (Stmt : Stmt (s) -> * (list-of-role-defs)
          [(cntx-def ,cntx (,stmt* ...))
           (append* (map (curry collect-role-defs) stmt*))]

          [(role-children ,role (,role-def* ...))
           (list s)]

          [else '()])


    (KB kb))

(define-pass role-def-to-move? : (L1 Stmt) -> * (stmt_or_bool)
  (Stmt : Stmt (s) -> * (stmt_or_bool)
        [(role-children _ _ _) s]
        [else #f]))

;; Compile to Doknil runtime
;; TODO make sure to pass a parameter to use for adding facts to the knowledge base
;; TODO update the cache with negated fact after every update
(define-pass L1->update-doknil-db! : L1 (kb db) -> * ()
 (KB : KB (K) -> * ()
  [(knowledge-base (,role-def* ...) (,stmt* ...))
   (for ([i role-def*])
     (set-box! db (+ 1 (unbox db))))])
)

|#

;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Parser: read the text and produce a syntax tree in L0

(define (doknil-parser in-str)
  (define token-thunk (doknil-lexer in-str))
  (define root (parse-to-datum token-thunk))

  (define (role-def/m root)
     (match root
       ((list 'role-def "/" (list 'role name))
          `(role-children ,(string->symbol name) #f ()))
       ((list 'role-def "/" (list 'role name) complement)
          `(role-children ,(string->symbol name) ,(string->symbol complement) ()))
       ((list 'role-def "/" (list 'role name) (list 'role-children "-->" "(" children ... ")"))
          `(role-children ,(string->symbol name) #f ,(map role-def/m children)))
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
/again1 to
/again2 to
/again3 to

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

/subject of
/subject2 of
/subject3
/city of

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

(define test-src4 #<<DOKNIL-SRC
/related to
/again1 to
/again2 to
/again3 to --> (
  /inner1 from
  /inner2 to
  /inner3 to --> (
    /inner4 to
  )
)
DOKNIL-SRC
)

;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Debug

(define (debug src)
  (~> src
      open-input-string
      doknil-lexer
      parse-to-datum))

(define t test-src3)

(debug t)

(~> t
    open-input-string
    doknil-parser)

(~> t
    open-input-string
    doknil-parser
    parse-L0
    L0->L1
    L1->L2
    unparse-L2)

; TODO
; (define db (box 0))
; (L1->Doknil-runtime (L0->L1 (parse-L0 (doknil-parser (open-input-string t)))) db)
; (unbox db)
