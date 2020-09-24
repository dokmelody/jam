;; SPDX-License-Identifier: MIT
;; Copyright (C) 2020 Massimo Zaniboni <mzan@dokmelody.org>

#lang racket

(require racket/base
         racket/trace
         datalog
         nanopass
         threading
         "lexer.rkt"
         "grammar.rkt"
         "runtime.rkt")

;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; dbids

;; Create a unique and compact integer id for each name and complement pair.
;; Use #f as complement, when complement is not applicable.
(struct dbids
  ([count #:mutable] ; int
   to-name   ; int -> (name . (complement | #f))
   from-name ; (name . (complement | #f)) -> int
   )
  #:transparent)

(define dbids-empty-name 0)

(define (make-dbids)
  (let ([r (dbids 0 (make-hash) (make-hash))])
    (dbids-id! r "" #f)
    r))

(define (dbids-new-count! d)
  (define r (dbids-count d))
  (set-dbids-count! d (add1 r))
  r)

;; Get or create the dbid associated to the key.
(define (dbids-key->id! dbids key)
      (hash-ref
         (dbids-from-name dbids)
         key
         (lambda ()
           (define rid (dbids-new-count! dbids))
           (hash-set! (dbids-from-name dbids) key rid)
           (hash-set! (dbids-to-name dbids) rid key)
           rid)))

;; Get the key used for creating the id.
(define (dbids->key dbids dbid)
      (hash-ref
         (dbids-to-name dbids)
         dbid))

;; Get or create the dbid associated to the name and complement.
;; symbol | string -> symbol | string | #f -> int
(define (dbids-id! dbids name complement)
  (dbids-key->id! dbids (cons name complement)))

(define (dbids-name dbids dbid)
  (hash-ref (dbids-to-name dbids) dbid (lambda () #f)))

;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Runtime env with result of incremental compilation.
;; New facts, names and rules are added to a global Doknil run-time environment.
;; In this way it is possible adding at run-time new facts and rules.
;; Normalize cntxs as a branch and group expression, and store it inside ``doknil-dbids``.

;; NOTE: doknil defined in "doknil/runtime.rkt" is part of the environment.

;; The dbids used for (incremental) compilation of Doknil code to doknil run-time.
(define doknil-dbids (make-dbids))

;; Count the extensional (i.e. explicit) facts.
(define count-facts (box 1))

(define (count-facts-next!) (set-box! count-facts (add1 (unbox count-facts))))

(define (q-name dbid)
     (cond
      [(eq? dbid #f) #f]
      [else (car (hash-ref (dbids-to-name doknil-dbids) dbid))]))

(define (q-complement dbid)
     (cond
      [(eq? dbid #f) #f]
      [else (cdr (hash-ref (dbids-to-name doknil-dbids) dbid))]))

(define (q-name-dbid name)
      (cond
      [(eq? name #f) #f]
      [else (hash-ref (dbids-from-name doknil-dbids) (cons name #f))]))

(define (q-role-dbid name complement)
      (cond
      [(eq? name #f) #f]
      [else (hash-ref (dbids-from-name doknil-dbids) (cons name complement))]))

;; cntx like ``A/B/C.x.y.z`` can be represented in different ways:
;; * a list of dbids for branches (i.e. ``A/B/C``) and groups (i.e. ``x.y.z``) where each dbid is a name
;; * a unique dbid representing the unique branches and groups association

;; Given a list of names (i.e. symbols),
;; return a ``cntx-dbids branches groups``.
(define (q-cntx-names->dbids branches groups)
  (define (to-dbids! names)
    (map (lambda (name) (dbids-id! doknil-dbids name #f)) names))

  (let ([bs (to-dbids! branches)]
        [gs (to-dbids! groups)])
    `(cntx-dbids ,bs ,gs)))

;; Given a ``cntx-dbids`` return a single compact dbid.
;; Create also intermediate missing branch and groups.
(define (doknil-cntx-dbids->dbid! cntx-dbids)
  (match cntx-dbids
    [(list 'cntx-dbids branch-dbids group-dbids)
     (define lb (length branch-dbids))
     (define lg (length group-dbids))

     ; Create an empty group for every missing branch.
     ; Use '() as index of the empty group of every branch.
    (do ([i 0 (add1 i)])
        [(> i lb)]
      (let* ([p (take branch-dbids i)]
             [bg `(cntx-dbids ,p ())])
        (dbids-key->id! doknil-dbids bg)))

    ; Create a group for every missing group of the specified branch
    (do ([i 1 (add1 i)])
        [(> i lg)]
      (let* ([g (take group-dbids i)]
             [bg `(cntx-dbids ,branch-dbids ,g)])
            (dbids-key->id! doknil-dbids bg)))

  ; Return the result
  (dbids-key->id! doknil-dbids `(cntx-dbids ,branch-dbids ,group-dbids))]))

(define (q-cntx-names->dbid branches groups)
  (doknil-cntx-dbids->dbid! (q-cntx-names->dbids branches groups)))

(define (q-cntx-dbid->dbids dbid)
  (dbids->key doknil-dbids dbid))

(define (q-cntx-dbids->dbid dbids)
  (doknil-cntx-dbids->dbid! dbids))

(define (q-root-cntx-dbid)
  (q-cntx-dbids->dbid `(cntx-dbids () ())))

(define (q-cntx-dbids->branch-names dbids)
  (match dbids
    ([list 'cntx-dbids bs gs]
     (map (curry q-name) bs))))

(define (q-cntx-dbids->group-names dbids)
  (match dbids
    ([list 'cntx-dbids bs gs]
     (map (curry q-name) gs))))

;; Return a string for representing the cntx, like "A/B/C.x.y.z"
(define (q-cntx-dbid->complete-names dbid)
  (define dbids (q-cntx-dbid->dbids dbid))

  (string-append
    (string-join (map (curry symbol->string) (q-cntx-dbids->branch-names dbids)) "/")
    (string-join (map (curry symbol->string) (q-cntx-dbids->group-names dbids)) "." #:before-first ".")))

;; Describe cntx info, for debug porpouse.
(define (q-describe-cntxs)
  (define (describe cntx dbid)
    (match cntx
      [(list 'cntx-dbids branch-dbids group-dbids)
       (q-cntx-dbid->complete-names dbid)]

      [else #f]))

  (string-join
    (filter (lambda (x) (not (eq? #f x)))
          (hash-map (dbids-from-name doknil-dbids) (curry describe)))
    "\n"))

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

(define (is-part-of? x) (boolean? x))

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
                 name-id))
      (is-part-of (is-part-of))))

  (KB (kb)
      (- (knowledge-base (role-def* ...) (stmt* ...)))
      (+ (knowledge-base (role-def* ...) (stmt* ...))))

  (RoleDef (role-def)
           (- (role-children role (maybe of?) (role-def* ...)))
           (+ (role-children role is-part-of (role-def* ...))))

  (Stmt (stmt)
        (- (isa subj role of obj))
        (+ (isa subj role obj))))

;; Transform role-def hierarchy from list of children to parent pointer.
(define-language L2
  (extends L1)

  (RoleDef (role-def)
           (- (role-children role is-part-of (role-def* ...)))
           (+ (role-children role is-part-of (maybe parent-role?))))

)

;; Flatten the cntx info into a unique id for an hierarchy of branches and groups.
(define-language L3
  (extends L2)

  (KB (kb)
      (- (knowledge-base (role-def* ...) (stmt* ...)))
      (+ (knowledge-base (branch-def* ...)
                         (cntx-def* ...)
                         (cntx-explicit-tree* ...)
                         (role-def* ...)
                         (stmt* ...))))

  (BranchDef (branch-def)
             (+ (branch-deff branch-id (maybe parent-branch-id?))))

  (CntxDef (cntx-def)
           (+ (cntx-deff cntx-id branch-id (maybe parent-cntx-id?))))

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
;; Nanopass transformers

(define-pass L0->L1 : L0 (kb) -> L1 ()

    (KB : KB (K) -> KB ()
        [(knowledge-base (,[role-def*] ...) (,[stmt*] ...))
         `(knowledge-base (,role-def* ...) (,stmt* ...))])

    (RoleDef : RoleDef (R) -> RoleDef ()
           [(role-children ,role ,of? (,[role-def*] ...))
            `(role-children ,(dbids-id! doknil-dbids role of?) ,(equal? of? "of") (,role-def* ...))]
           )

    (Cntx : Cntx (C) -> Cntx ()
          [(cntx-ref (,branch* ...) (,group* ...))
           (let ([branch** (map (lambda (x) (dbids-id! doknil-dbids x #f)) branch*)]
                 [group** (map (lambda (x) (dbids-id! doknil-dbids x #f)) group*)])
           `(cntx-ref (,branch** ...) (,group** ...)))])

    (Stmt : Stmt (S) -> Stmt ()
         [(cntx-include ,[cntx])
          `(cntx-include ,cntx)]

         [(cntx-exclude ,[cntx])
          `(cntx-exclude ,cntx)]

         [(is ,subj ,role)
          `(is ,(dbids-id! doknil-dbids subj #f)
               ,(dbids-id! doknil-dbids role #f))]

         [(isa ,subj ,role ,of ,obj)
          `(isa ,(dbids-id! doknil-dbids subj #f)
                ,(dbids-id! doknil-dbids role of)
                ,(dbids-id! doknil-dbids obj #f))]

         [(cntx-def ,[cntx] (,[stmt*] ...))
          `(cntx-def ,cntx (,stmt* ...))])
)

(define-pass L1->L2 : L1 (kb) -> L2 ()
    (KB : KB (K) -> KB ()
        [(knowledge-base (,role-def* ...) (,[stmt*] ...))
         (let* ([role-def** (flatten (map (lambda (x) (flat-RoleDef x #f)) role-def*))])
           `(knowledge-base (,role-def** ...) (,stmt* ...)))])

    (flat-RoleDef : RoleDef (rc parent) -> * (rds)
                 [(role-children ,role ,is-part-of (,role-def* ...))
                  (cons
                   (with-output-language (L2 RoleDef) `(role-children ,role ,is-part-of ,parent))
                   (map (lambda (x) (flat-RoleDef x role)) role-def*))]))

;; Extract all the contexts used inside L2 and save them in doknil environment
(define-pass L2->cntxs : L2 (kb) -> * (bool)

  (KB : KB (K) -> * (bool)
      [(knowledge-base (,role-def* ...) (,[stmt*] ...)) #t])

  (Stmt : Stmt (S) -> * (bool)
          [(cntx-include ,[cntx]) #t]

          [(cntx-exclude ,[cntx]) #t]

          [(cntx-def ,[cntx] (,[stmt*] ...)) #t]

          [else #t])

  (Cntx : Cntx (C) -> * (bool)
        [(cntx-ref (,branch* ...) (,group* ...))
         (doknil-cntx-dbids->dbid! `(cntx-dbids ,branch* ,group*))])

  ; main entry point
  (begin
    ; create root cntx
    (doknil-cntx-dbids->dbid! (q-cntx-names->dbids '() '()))

    (KB kb)))

; TODO reformat code
; TODO check if groups must be set forward or backward.
; TODO see in the documentation about the hierarchy order
; TODO check also in the rules of the runtime

; Compile L2 into L3 and update also the global env variable ``doknil-cntxs``.
(define-pass L2->L3 : L2 (kb) -> L3 ()
  (definitions

    (define cntxs-include '())
    (define cntxs-exclude '())
    (define found-cntx-dbid-set (mutable-set))

    (define (generate-cntxs-include)
      (map (lambda (x)
             (with-output-language (L3 CntxExplicitTree)
               `(cntx-include ,(car x) ,(cdr x)))) cntxs-include))

    (define (generate-cntxs-exclude)
      (map (lambda (x)
             (with-output-language (L3 CntxExplicitTree)
               `(cntx-exclude ,(car x) ,(cdr x)))) cntxs-exclude))

    (define (cntxs-generate-all-group-defs)
      (define generated-dbids (mutable-set))

      (define (generate-group-defs branch-dbid branch-dbids group-dbids)
        (define cntx-dbid (q-cntx-dbids->dbid `(cntx-dbids ,branch-dbids ,group-dbids)))

          (cond [(set-member? generated-dbids cntx-dbid)
                 ; NOTE: if a dbid is generated, then also its parent hierarchy is generated,
                 ; so if I don't reach this point, I will not miss anythyng.
                 #f]

                [else
                (set-add! generated-dbids cntx-dbid)
                (cond
                  [(empty? group-dbids)
                   (cons
                   (with-output-language (L3 CntxDef)
                     `(cntx-deff ,cntx-dbid ,branch-dbid #f)) '())]
                  [else (let* ([parent-dbids (drop-right group-dbids 1)]
                              [parent-dbid (q-cntx-dbids->dbid `(cntx-dbids ,branch-dbids ,parent-dbids))])
                          (cons
                   (with-output-language (L3 CntxDef)
                     `(cntx-deff ,cntx-dbid ,branch-dbid ,parent-dbid))
                                (generate-group-defs branch-dbid branch-dbids parent-dbids)))])]))

      (define cntxs (set-map found-cntx-dbid-set (curry dbids->key doknil-dbids)))


      (filter (lambda (x) (not (eq? x #f)))
              (flatten (map (lambda (bsgs)
                              (match bsgs
                                     ([list 'cntx-dbids bs gs]
                                      (let* ([branch-dbid (q-cntx-dbids->dbid `(cntx-dbids ,bs ()))])
                                        (generate-group-defs branch-dbid bs gs)))))
                            cntxs))))

    (define (cntxs-generate-all-branch-defs)
      (define generated-dbids (mutable-set))

      (define (generate-branch-defs branch-dbids)
        (define branch-id (q-cntx-dbids->dbid `(cntx-dbids ,branch-dbids ())))
        (cond
           [(set-member? generated-dbids branch-id)
             ; NOTE: if a dbid is generated, then also its parent hierarchy is generated,
             ; so if I don't reach this point, I will not miss anythyng.
             #f]
           [else
                  (set-add! generated-dbids branch-id)
                  (cond
                    [(empty? branch-dbids)
                      (cons (with-output-language (L3 BranchDef)
                             `(branch-deff ,branch-id #f)) '())]
                    [else (let* ([parent-dbids (drop-right branch-dbids 1)]
                                 [parent-id (q-cntx-dbids->dbid `(cntx-dbids ,parent-dbids ()))])
                                 (cons (with-output-language (L3 BranchDef)
                                   `(branch-deff ,branch-id ,parent-id))
                                    (generate-branch-defs parent-dbids)))])]))

      ; Extract unique branches as dbids
      (let* ([cntxs (set-map found-cntx-dbid-set (curry q-cntx-dbid->dbids))]
             [bss (map (lambda (bsgs) (match bsgs [(list 'cntx-dbids bs gs) bs])) cntxs)]
             [bs (list->set bss)])

        (filter (lambda (x) (not (eq? x #f)))
                (flatten (set-map bs (curry generate-branch-defs))))))

    )

  (KB : KB (K) -> KB ()
        [(knowledge-base (,[role-def*] ...) (,stmt* ...))
         (let* ([stmt** (flatten (map (lambda (x) (Stmt x (q-root-cntx-dbid))) stmt*))]
                [branch-def** (cntxs-generate-all-branch-defs)]
                [cntx-def** (cntxs-generate-all-group-defs)]
                [explicit-includes** (generate-cntxs-include)]
                [explicit-includes** (generate-cntxs-exclude)]
                [explicit-cntxs** (append (generate-cntxs-include) (generate-cntxs-exclude))]
                )
           `(knowledge-base
             (,branch-def** ...)
             (,cntx-def** ...)
             (,explicit-cntxs** ...)
             (,role-def* ...)
             (,stmt** ...)))])

  (Stmt : Stmt (S current-cntx-id) -> * (stmts)
        [(cntx-include ,cntx)
         (begin
           (set! cntxs-include (cons (cons current-cntx-id (to-cntx-id cntx)) cntxs-include))
           '())]

          [(cntx-exclude ,cntx)
           (begin
             (set! cntxs-exclude (cons (cons current-cntx-id (to-cntx-id cntx)) cntxs-exclude))
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
               (let ([dbid (doknil-cntx-dbids->dbid! `(cntx-dbids ,branch* ,group*))])
                 (set-add! found-cntx-dbid-set dbid)
                 dbid)])

  ;; Main entry point
  (begin
    ; first update doknil-cntxs
    (L2->cntxs kb)
    (KB kb))

)

;; Generate code for the run-time doknil-db
(define-pass L3->doknil-db  : L3 (kb) -> * (bool)

    (KB : KB (kb) -> * (bool)
        [(knowledge-base
          (,[branch-def*] ...)
          (,[cntx-def*] ...)
          (,[cntx-explicit-tree*] ...)
          (,[role-def*] ...)
          (,[stmt*] ...)) #t])

  (RoleDef : RoleDef (rd) -> * (bool)
           [(role-children ,role ,is-part-of ,parent-role?)
            (datalog doknil-db  (! (role #,role #,is-part-of #,parent-role?)))
            ])

  (BranchDef : BranchDef (bd) -> * (bool)
             [(branch-deff ,branch-id ,parent-branch-id?)
              (datalog doknil-db  (! (branch #,branch-id #,parent-branch-id?)))
             ])

  (CntxDef : CntxDef (cd) -> * (bool)
           [(cntx-deff ,cntx-id ,branch-id ,parent-cntx-id?)
            (datalog doknil-db  (! (cntx #,cntx-id #,branch-id #,parent-cntx-id?)))
            ])

  (CntxExplicitTree : CntxExplicitTree (et) -> * (bool)
                    [(cntx-include ,into-cntx-id ,from-cntx-id)
                     (datalog doknil-db  (! (include-cntx #,into-cntx-id #,from-cntx-id)))
                     ]
                    [(cntx-exclude ,into-cntx-id ,from-cntx-id)
                     (datalog doknil-db  (! (exclude-cntx #,into-cntx-id #,from-cntx-id)))
                     ]
                    )

  (Stmt : Stmt (s) -> * (bool)
        [(isa ,cntx-id ,subj ,role ,obj)
         (datalog doknil-db  (! (isa-fact #,(unbox count-facts) #,cntx-id #,subj #,role #,obj)))
         (count-facts-next!)
         ]

        [(is ,cntx-id ,subj ,role)
         (datalog doknil-db  (! (isa-fact #,(unbox count-facts) #,cntx-id #,subj #,role #f)))
         (count-facts-next!)
         ]
        )

  ;; Main body
  (begin
    (KB kb)
    (precalculated-reachable-cntx-invalidate!)
    #t))

;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Queries
;; Up to date only simple queries are supported and a "native"
;; Lisp interface is used. No special query language is implemented
;; right now.

;; TODO use one type of query where the query result is filtered deriving only more specific role and context
;; TODO rewrite regression tests for using the API
;; TODO add tests about consistency of the DB analyzing the Doknil source code
;; TODO contexts must be added to the DB according their effective usage because every new hierarchy is a new id,
;; or use instead an hash map of the complete hiearchy
;;
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
;; TODO do not assign correctly "part-of" boolean value to relations

;; DONE up to date for simplyfing life, I use an hash map mapping from variable name to value, so the code is a mix between
;; this decision and my decision
;; FACT I switch to language axe that has a more friendly dict navigation and it is good enough up to date

;; TODO convert back to names and not to ids
;; TODO find a good API to use: it should ask only to Doknil run-time and it must use the dbids only for name conversion

; TODO implement these
; TODO use this API in the doknil tests

(struct role-def
  (id
   parent-id?
   name
   complement
   is-part-of?)
  #:transparent)

(struct fact
  (id
   cntx-id
   subject-id
   role-id
   object-id?
   )
  #:transparent)


(define (fact-role-def f)
 (~> f fact-role-id q-role-def))

(define (fact-subject f)
  (q-name (fact-subject-id f)))

(define (fact-object f)
  (q-name (fact-object-id? f)))

(define (q-fact fact-id)
  (let ([d (first (datalog doknil-db (? (isa-fact #,fact-id CNTX SUBJ ROLE OBJ))))])
    (fact fact-id (hash-ref d 'CNTX) (hash-ref d 'SUBJ) (hash-ref d 'ROLE) (hash-ref d 'OBJ))
  ))

(define (q-role-def role-id)
   (let ([d (first (datalog doknil-db (? (role #,role-id IS-PART-OF PARENT-ID))))])
        (role-def role-id
                  (hash-ref d 'PARENT-ID)
                  (q-name role-id)
                  (q-complement role-id)
                  (hash-ref d 'IS-PART-OF))))

(define (q-role-defs role-id)
  (let* ([d (q-role-def role-id)]
         [pid (role-def-parent-id? d)])
    (cons d (cond
              [(eq? #f pid) '()]
              [else (q-role-defs pid)]))))

; TODO extract also info about cntx
;; TODO implement
(define (q-child-cntxs fact-id) #f)

(define (q-facts-with-subj-obj cntx-id subj-id obj-id)
  (let ([ds (datalog doknil-db (? (isa BRANCH #,subj-id ROLE IS-PART-OF #,obj-id #,cntx-id FACT)))])
    (map (lambda (d) (q-fact (hash-ref d 'FACT))) ds)
    ))

;; TODO implement
(define (q-facts-with-subj cntx-id subj-id) #f)

;; TODO implement
(define (q-facts-with-obj cntx-id obj-id) #f)

;; TODO implement
(define (q-facts-with-subj-role cntx-id subj-id role-id) #f)

;; TODO implement
(define (q-facts-with-obj-role cntx-id obj-id role-id) #f)

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
      ((list (list 'include-cntx "!include" cntx))
       `(cntx-include ,(cntx/m cntx)))

      ((list (list 'exclude-cntx "!exclude" cntx))
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

(define test-src5 #<<DOKNIL-SRC

# Roles

/nation

/related to --> (
  /task of --> (
    /issue of
  )

  /city of

  /company of --> (
    /department of
  )
)

# Company example

World --> {
  $acmeCorporation isa company
  $departmentX isa department of $acmeCorporation
  $issue1 isa issue of $departmentX
}

# Assert facts on different branches

World/Earth.places --> {
  $italy isa nation
  $rome isa city of $italy
}

World/Earth/Tolkien.places --> {
  !exclude World/Earth.places

  $middleEarth isa nation
  $gondor isa city of $middleEarth
}

DOKNIL-SRC
)

;; TODO the usefull queries are probably very fews and I can use only a Lisp API instead of creating a distinct PL

;; TODO support queries like this
#|
# Queries

!query, /World/?Cntx --> {
    @Fact(?$fact1), $issue1 isa issue of ?$obj
    !check, ?$fact1.role == issue

    !check {
      ?$fact1.role.complement == of
      ?$fact1.obj == ?$obj
    }

    !check, ?$fact1 {
      ~.role == issue
      ~.role.complement == of
    }

    !check, ?$fact1 {
      ~.role {
        ~ == issue
        ~.complement == of
        ~~.obj == ?$obj
      }
    }
}

!query {
  /World/?Cntx --> {
    $issue1 isa task of ?$obj
  }
}

!query {
  /World/Earth --> {
    @Fact(?fact3), ?$city isa city of ?$obj
  }
}

!query {
  /World/Earth/Tolkien --> {
    @Fact(?fact4), ?$city isa city of ?$obj
  }
}
|#

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

(define t test-src5)

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
    L3->doknil-db)

(q-fact 1)
(fact-subject (q-fact 1))
(fact-object (q-fact 1))

(q-role-def (q-role-dbid 'issue 'of))
(q-role-defs (q-role-dbid 'issue 'of))

doknil-dbids

(q-cntx-dbid->dbids 24)
(q-cntx-dbids->branch-names (q-cntx-dbid->dbids 24))

;; TODO not formatted in the correct way
(println (q-describe-cntxs))

(println "Hello\nWorld\nagain!")

;; TODO list too many facts that are the same!
(q-facts-with-subj-obj
 (q-cntx-names->dbid (list 'World) '())
 (q-name-dbid '$issue1)
 (q-name-dbid '$departmentX))
