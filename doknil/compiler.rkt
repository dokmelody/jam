;; SPDX-License-Identifier: MIT
;; Copyright (C) 2020 Massimo Zaniboni <mzan@dokmelody.org>

#lang racket

(require racket/base
         racket/serialize
         racket/trace
         datalog
         nanopass
         threading
         "lexer.rkt"
         "grammar.rkt"
         "runtime.rkt")

;; TODO contexts must be added to the DB according their effective usage because every new hierarchy is a new id,
;; or use instead an hash map of the complete hiearchy
;; TODO use a defalt NULL/nil value for some of the specified relations
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
;; TODO move "role" id before the parent for coherence

;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Nanopass languages

(define (instance? x) (symbol? x))

(define (role? x) (symbol? x))

(define (complement? x) (or (eq? x #f) (symbol? x)))

(define (cntx-branch? x) (symbol? x))

(define (cntx-group? x) (symbol? x))

(define (name-str? x) (string? x))

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
   (name-str (name complement-name)))

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
(define-language L1
  (extends L0)
  (terminals
   (- (instance (subj obj))
      (role (role))
      (complement (of))
      (cntx-branch (branch))
      (cntx-group (group))
      )
   (+ (db-id (dbid subj obj
                 role parent-role
                 branch group
                 cntx-id parent-cntx-id branch-id parent-branch-id
                 into-cntx-id from-cntx-id
                 name-id))))

  (KB (kb)
      (- (knowledge-base (role-def* ...) (stmt* ...)))
      (+ (knowledge-base (name-def* ...) (role-def* ...) (stmt* ...))))

  (NameDef (name-def)
    (+ (name-deff dbid name (maybe complement-name?))))

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
           (+ (role-children (maybe parent-role?) role)))

)

;; Flatten the cntx info into a unique id for an hierarchy of branches and groups.
(define-language L3
  (extends L2)

  (KB (kb)
      (- (knowledge-base (name-def* ...) (role-def* ...) (stmt* ...)))
      (+ (knowledge-base (branch-def* ...)
                         (cntx-def* ...)
                         (cntx-explicit-tree* ...)
                         (name-def* ...)
                         (role-def* ...)
                         (stmt* ...))))

  (BranchDef (branch-def)
             (+ (branch-deff branch-id (maybe parent-branch-id?) name-id)))

  (CntxDef (cntx-def)
           (+ (cntx-deff cntx-id branch-id (maybe parent-cntx-id?) name-id)))

  (CntxExplicitTree (cntx-explicit-tree)
                    (+ (cntx-include into-cntx-id from-cntx-id))
                    (+ (cntx-exclude into-cntx-id from-cntx-id)))

  (Cntx (cntx)
    (- (cntx-ref (branch* ...) (group* ...))))

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

;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; dbids

;; Create a unique and compact integer id for each name and complement pair.
;; Use #f as complement, when complement is not applicable.
(struct dbids
  ([count #:mutable] ; int
   to-name   ; int -> (name . (complement | #f))
   from-name ; (name . (complement | #f)) -> int
   ))

(define dbids-empty-name 0)

(define (make-dbids)
  (let ([r (dbids 0 (make-hash) (make-hash))])
    (dbids-id! r "" #f)
    r))

;; Get or create the dbid associated to the name and complement.
;; symbol | string -> symbol | string | #f -> int
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


;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; cntxs

;; Associate a unique id to a list of branches and groups.
(struct cntxs
  ([count #:mutable] ; integer
   branches->>groups->>dbid        ; (list-names ...) -> (list names ...) -> dbid
   )
   #:transparent)

(define cntxs-root-dbid 0)

(define (make-cntxs)
  (let* ([hs-group (make-hash (list (cons '() cntxs-root-dbid)))]
         [hs-branch (make-hash (list (cons '() hs-group)))])
    (cntxs 1 hs-branch)))

(define (cntxs-new-count! cntxs)
  (define r (cntxs-count cntxs))
  (set-cntxs-count! cntxs (+ r 1))
  r
)

;; Extend with a unique id for every sequence of missing branch and group names.
;; (list string|symbol) -> (list string|symbol)
(define (cntxs-extend! cntxs branches groups)
  (define hs (cntxs-branches->>groups->>dbid cntxs))
  (define lb (length branches))
  (define lg (length groups))

  ; Create an empty group for every missing branch
  (do ([i 1 (+ i 1)])
       [(> i lb)]
    (let ([p (take branches i)])
      (when (not (hash-has-key? hs p))
        (define inner-hs (make-hash (list (cons '() (cntxs-new-count! cntxs)))))
        (hash-set! hs p inner-hs)))
  )

  ; Create a group for every missing group
  (define hs2 (hash-ref hs branches))
  (do ([i 1 (+ i 1)])
       [(> i lg)]
    (let ([p (take groups i)])
      (when (not (hash-has-key? hs2 p))
        (hash-set! hs2 p (cntxs-new-count! cntxs)))))
)

(define (cntxs-get-dbid cntxs branches groups)
  (define hs (hash-ref (cntxs-branches->>groups->>dbid cntxs) branches))
  (hash-ref hs groups)
)

;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Nanopass transformers

(define-pass L0->L1 : L0 (kb) -> L1 ()
  (definitions

    (define dbids (make-dbids)))

    (KB : KB (K) -> KB ()
        [(knowledge-base (,[role-def*] ...) (,[stmt*] ...))
         (let ([name-def** (dbids->name-def* dbids)])
             `(knowledge-base (,name-def** ...) (,role-def* ...) (,stmt* ...)))])

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
)

(define-pass L1->L2 : L1 (kb) -> L2 ()
    (KB : KB (K) -> KB ()
        [(knowledge-base (,[name-def*] ...) (,role-def* ...) (,[stmt*] ...))
         (let* ([role-def** (flatten (map (lambda (x) (flat-RoleDef x #f)) role-def*))])
           `(knowledge-base (,name-def* ...) (,role-def** ...) (,stmt* ...)))])

    (flat-RoleDef : RoleDef (rc parent) -> * (rds)
                 [(role-children ,role (,role-def* ...))
                  (cons
                   (with-output-language (L2 RoleDef) `(role-children ,parent ,role))
                   (map (lambda (x) (flat-RoleDef x role)) role-def*))]))

(define (dbids->name-def* dbids)
  (define (to-str n)
    (cond
      [(eq? n #f) #f]
      [(string? n) n]
      [(symbol? n) (symbol->string n)]
      ))

  (hash-map
   (dbids-to-name dbids)
   (lambda (dbid nc)
     (match nc
       ((cons name complement)
        (with-output-language (L1 NameDef)
          `(name-deff ,dbid ,(to-str name) ,(to-str complement))))))))

;; Extract all the contexts used inside L2
(define-pass L2->cntxs : L2 (kb) -> * (cntxs)
  (definitions
     (define r (make-cntxs)))

  (KB : KB (K) -> * (bool)
        [(knowledge-base (,name-def* ...) (,role-def* ...) (,[stmt*] ...)) #t])

  (Stmt : Stmt (S) -> * (bool)
          [(cntx-include ,[cntx]) #t]

          [(cntx-exclude ,[cntx]) #t]

          [(cntx-def ,[cntx] (,[stmt*] ...)) #t]

          [else #t])

  (Cntx : Cntx (C) -> * (bool)
        [(cntx-ref (,branch* ...) (,group* ...))
         (cntxs-extend! r branch* group*)])

  ; main entry point
  (begin
    (KB kb)
     r))

(define-pass L2->L3 : L2 (kb) -> L3 ()
  (definitions
    (define cntxs (L2->cntxs kb))

    (define cntxs-include '())
    (define cntxs-exclude '())

    (define (generate-cntxs-include)
      (map (lambda (x)
             (with-output-language (L3 CntxExplicitTree)
               `(cntx-include ,(car x) ,(cdr x)))) cntxs-include))

    (define (generate-cntxs-exclude)
      (map (lambda (x)
             (with-output-language (L3 CntxExplicitTree)
               `(cntx-exclude ,(car x) ,(cdr x)))) cntxs-exclude))

    (define (cntxs->BranchDef branch)
      (let* ([branch-id (cntxs-get-dbid cntxs branch '())]

             [parent-id (cond [(empty? branch) #f]
                              [else (cntxs-get-dbid cntxs (drop-right branch 1) '() )])]

             [name (cond [(empty? branch) dbids-empty-name]
                         [else (last branch)])]

             )
        (with-output-language (L3 BranchDef)
          `(branch-deff ,branch-id ,parent-id ,name))))

    (define (cntxs->CntxDefs branch group)
      (let* ([branch-id (cntxs-get-dbid cntxs branch '())]

             [group-id (cntxs-get-dbid cntxs branch group)]

             [parent-id (cond [(empty? group) #f]
                              [else (cntxs-get-dbid cntxs branch (drop-right group 1))])]

             [name (cond [(empty? group) dbids-empty-name]
                         [else (last group)])]

             )
        (with-output-language (L3 CntxDef)
          `(cntx-deff ,group-id ,branch-id ,parent-id ,name))))

    (define (cntxs-generate-all-groups branch)
      (let* ([groups (hash-ref (cntxs-branches->>groups->>dbid cntxs) branch)]
             [cntxs (map (lambda (group) (cntxs->CntxDefs branch group)) (hash-keys groups))])
         cntxs
         ))

    (define (cntxs-generate-all-all-groups)
      (let* ([branches (hash-keys (cntxs-branches->>groups->>dbid cntxs))]
             [r (map (lambda (branch) (cntxs-generate-all-groups branch)) branches)])
         r
         ))

    (define (cntxs-generate-all-branches)
      (let* ([branches (hash-keys (cntxs-branches->>groups->>dbid cntxs))])
        (map (lambda (branch) (cntxs->BranchDef branch)) branches)))
  )

  (KB : KB (K) -> KB ()
        [(knowledge-base (,[name-def*] ...) (,[role-def*] ...) (,stmt* ...))
         (let* ([stmt** (flatten (map (lambda (x) (Stmt x cntxs-root-dbid)) stmt*))]
                [branch-def** (flatten (cntxs-generate-all-branches))]
                [cntx-def** (flatten (cntxs-generate-all-all-groups))]
                [explicit-includes** (generate-cntxs-include)]
                [explicit-includes** (generate-cntxs-exclude)]
                [explicit-cntxs** (append (generate-cntxs-include) (generate-cntxs-exclude))]
                )
           `(knowledge-base
             (,branch-def** ...)
             (,cntx-def** ...)
             (,explicit-cntxs** ...)
             (,name-def* ...)
             (,role-def* ...)
             (,stmt** ...)))])

  (Stmt : Stmt (S current-cntx-id) -> * (stmts)
        [(cntx-include ,cntx)
         (begin
           (set! cntxs-include (cons (cons current-cntx-id (to-cntx-id cntx))))
           '())]

          [(cntx-exclude ,cntx)
           (begin
             (set! cntxs-exclude (cons (cons current-cntx-id (to-cntx-id cntx))))
           '())]

          [(cntx-def ,cntx (,stmt* ...))
           (let* ([new-cntx-id (to-cntx-id cntx)])
             (map (lambda (x) (Stmt x new-cntx-id)) stmt*))]

          [(isa ,subj ,role ,obj) 
           (let ([r (with-output-language (L3 Stmt)
                      `(isa ,current-cntx-id ,subj ,role ,obj))])
             (list r))]

          [(is ,subj ,role)
           (let ([r (with-output-language (L3 Stmt)
                      `(is ,current-cntx-id ,subj ,role))])
             (list r))])

  (to-cntx-id : Cntx (C) -> * (dbid)
              [(cntx-ref (,branch* ...) (,group* ...))
               (cntxs-get-dbid cntxs branch* group*)])

)

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

(define (debug2 src)
  (~> src
    open-input-string
    doknil-parser
    parse-L0
    L0->L1
    L1->L2
    L2->cntxs
    println))

(define t test-src3)

(~> t
    open-input-string
    doknil-parser)

(~> t
    open-input-string
    doknil-parser
    parse-L0
    L0->L1
    L1->L2
    L2->L3
    unparse-L3)

; TODO
; (define db (box 0))
; (L1->Doknil-runtime (L0->L1 (parse-L0 (doknil-parser (open-input-string t)))) db)
; (unbox db)
