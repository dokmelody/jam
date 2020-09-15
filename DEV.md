# In progress

## Stories


### TODO Doknil compiler

TODO to be fair some facts are intensional and it is important also using Racket code so the syntax will be readable Racket code. Manage this after a compiler is written and it is clear which API use for generating Doknil code inside Clojure.

MAYBE during cards creation manage CONTEXT as a dynamic attribute
MAYBE support current owner and role and context as dynamic attribute during declaration

### TODO Create cards

TODO parse markdown content
TODO accept links in the Markdown processed (MAYBE customize it)
TODO a card is created by code, because I can use literate programming and templates
TODO cards can be created combining chunks of code, in literate-programming style.
TODO express Doknil rules as readable code and generate both the documentation card and the Clojure code
TODO a CARD can be defined, but until it is not used in a CONTEXT, its implicit facts are not generated

### TODO Doknil semantic

TODO find a way for saying that a certain part of a company or similar believe in things different (like context)

TODO branch.group is not important for the KB query and related semantic, but only in the UI navigation of the KB for showing the schema used, and editing it.

TODO Create a syntax and semantic for queries

### TODO DokMelody UI

TODO expose ``is-direct-part-of`` query to the external

### TODO Document DokMelody and Doknil using DokMelody itself

TODO convert also notes on papers

TODO make a distinction (MAYBE using TAG) between implemented things and future plans

## [Doknil, DokMelody] Display Cards in Clojure

On the Doknil side I will use https://github.com/martintrojer/datalog

I will use Limunos as web framework.

Ring as web server (already part of Luminos).

Generation of graphics:
* https://github.com/jebberjeb/specviz
* https://github.com/walmartlabs/system-viz

The design will be this:
* I will use hiccup and server side rendering of clojure "cards" to html code, and SVG code, and PNG
* there is for example from markdown to hiccup
* I will create a Clojure server returning an HTML page for each card
* I will create a Clojure JS app asking to Clojure server the content of cards and showing them in a tiddly-wiki like view, stripping HTML parts
* I will use a common CSS code for every returned card
* I will not use dynamic react elements, and all generation will be server-side
* I will return the last-modification-date of the content according the activation of the server or something of similar
* I will cache pages
* I will search for a good HTML and CSS impagination template, for representing cards in TiddlyWiki style

Advantages:
* server content can be cached
* server content is under SEO

Disavantages:
* no supports for dynamic cards, but they can only contains hyper-links

Implementation:
* take inspiration from devcards code
* TODO generate ``modified-since-last-date`` for enabling caching

DONE improved the semantic of Doknil with ``grouped Contexts``


## [Doknil] Create a demo KB combining all the parts

## [Doknil] P.A.R.A.

Cards managing the project can follow the P.A.R.A. approach:
* project: task,goal deadlines
* area: domain with standard rules and knowledge (papers and so on)
* resources: material to study, organize and maybe apply some day
* archive: (TAG) not any more used

## [Doknil] Manage TAGS in Doknil

Many cards can be tagged. Study how the TAG concept can be supported in Doknil.

## [Doknil] Convert Dublin schema into Doknil

TODO list some papers used in Dok, using this schema.

## [Doknil] Cards can be variants of the same entity

Two cards can be (more or less) the same concept. Find examples and a way in Doknil for joining them. For example something like

```
x is y
```

## MAYBE [DokMelody] UI layout

* https://www.wikidata.org/wiki/Q1252773
* https://www.w3.org/2001/sw/wiki/Tabulator
* Wikipedia infobox

See also discussion on https://doklang.zulipchat.com/#narrow/stream/251988-.23development/topic/UI/near/207940233

## MAYBE [Doknil] Study other ontologies schema

* kbpedia.org join many different ontologies
* dbpedia.org is an ontology version of wikipedia

## MAYBE [Doknil] Doknil simplified schema can be used in CRM and ERP

All compounded entities and concepts can be expressed in Doknil, and then tabular/relational data using a traditional table.

See the concept applied to Asterisell.

# Tasks

## [Dev] Prepare/TAG easy tasks to do

I can delegate some easy tasks, so one can became on-board, and being useful at the same time.

TODO see how other OSS projects solve the on-boarding problem

### [DokMelody] Check repl.it instance without hacker-upgrade

I upgraded my repl.it account to "hacker". They are $5 monthly and I can unsubscribe when I will never use it. It has more RAM and CPU of normal instances. Probably if a team member without hacker-upgrade fork the instance, then there can be problem running it, because it is a Java framework.

## [DokMelody] Caching of http query results

At every start of the server the DB date is updated.

At every change/update of DB at run-time the DB date is updated.

The server use a cache for the answers and send to HTTP clients the since-modified.. according the DB update date.

In this way there is an efficient caching both on the server and client side, and the caching code is very simple.

## [Dok] Attributes grammars in Clojure

MAYBE Dok compiler and runtime will be based also on attribute grammars. In case study 

    https://github.com/brandonbloom/ascribe

## Document Dok language using DokMelody

## See for similar ideas to Doknil in research

When document Doknil search for references in research.

In particular to the usage of Role instead of relationships. See also linked-data approach, that has probably a similar approach.

### [Doknil] Compare RDF reification with Doknil approach

### [Doknil] Compare with OWL approach for classes and instances

### [Doknil] ``isa`` problem

In Ontologies there are too much usages of ``isa`` idea. Retrieve some paper describing the problem and see of Doknil solve it.

## MAYBE [Doknil] Support time and transactions in Doknil

See how Datatomic manage it.

See notes about transactions in DokMelody.

## SOMEDAY [Doknil] Use a better deductive DBMS

The rules on ``of ...`` and ``context`` are rather simple and based on transitive closures. So it is probably better using an engine not based on magic-set rewriting.

## MAYBE [Doknil] Many relationships can be expressed adding a fuzzy-logic strenght

Many papers and idea can be similar to other with a range from 0 .. 1. Also friendships.

## MAYBE [Dok] Document Dok using cook-book code

Take inspiration from Rosetta of Code and/or git@github.com:clojure-cookbook/clojure-cookbook.git and write short pieces of code for showing how common problems are solved in Dok.

## TODO DokMelody UI elements

MAYBE a schema like this

```
(defprotocol ACard
  "A piece of short information"

  (title [this])
  (mime-type [this])
  (content [this])
  (implicit-links [this]))

(defprotocol ALink
  (subject [this])
  (relation [this])
  (object [this])
  (context [this]))
 )

TODO find a way to link a clojure value/object to a database statment
MAYBE insert the distance of CONTEXT and PARENT in the derived relation
TODO select the nearest card in the UI using the DISTANCE attribute
TODO a card can read from a file on resource directories
TODO the card-db is a function returning a card as a value, given a card name/index
TODO caching of cards allows to avoid regeneration of all cards
TODO order also relations by transitive closure
TODO cache/memoize the generation of a card
TODO store facts inside resources or similar
TODO during reading the title include the context "R1/R0" with "R0" being the parent
TODO create a map with complete-hiearchy as a vector and used as key, and the ``context-hierarchy-id`` as value.
It will be used for creating new contexts on demand.
Then they will be inserted exploded inside ``doknil-db``.

TODO find if Refs, Vars or Atoms must be used for adding new facts inside doknil-db at run-time
MAYBE make the same thing for part and role hierarchies
TODO store in a map/db the assocation between key and card object

## MAYBE Disable contracts in production

Racket functions (also system functions) have rather expensive contracts.

# Done Tasks

### DONE Doknil parser

TODO implement a parser of Doknil returning true if it parse correctly some Doknil code
TODO define a syntax for the language
TODO document the syntax of the language

### DONE [DevOp] Migrate from Clojure to Racket

#### DONE Start a local demo web-server and test on repl.it

Start an hello-world like web server and test on repl-it.

DONE create raco command for starting the web-server
DONE configure the port in which listen

#### DONE Unify with the master branch again

#### DONE Test the run of unit-tests locally

#### DONE Convert unit-tests to Racket

#### DONE Change to a Bash project type, and not JVM anymore

#### DONE Update the README file to the new instructions

#### DONE Test installation again on a fresch repl.it repo

## [DokMelody] Install and run on repl.it server

DONE converted to ``pom.xml``

DONE first install on a demo server

DONE Add repl.it badge on github repo

DONE Tell in the README.md file that you can press ``RUN`` button

DONE regression tests fails because there is some thread not terminating

FACT packages on repl.it are now more recents!!

FACT ``upm`` supports Java and maven packages

DONE convert lein package list into a list of maven packages

DONE try to install and run also without the experimental mode

## [Dev] Proposed a dev workflow here

DONE use Zulip chat

CANCELLED use a mailing list for notifying recent news of the project

## [Dev] Integrate the repo with Zulip

After I pubblish the repo into repl.it check if there is a discussion board.

If not continue using Zulip and:

* move dok-jam repository to GitHub
* link GitHub repo with repl.it and Zulip

# FAQ

# Learned Lessons

## Repl.it 

### Chat

The chat is not persistent, and after some time it is resetted. So it is good for "pair-programming" like collaboration.

### File system

All files that are not part of the repository are not persistent. So data generated at run-time and that must be preserved must be saved on ReplDB or on an external DB/service.

### Environment behaviour

In repl.it there are persistent web services.

All other VM can be restarted/reallocated often, and after each restart they loose all build and temporary files, and they start only with the files of the repository.

So the command associated to the run of the VM must recreate all from the beginning like a build file.

## Nanopass

### pass accepting and returning values

The first returned value is the transformed AST and the second value is the calculated parameter.

```
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
```

### Pass accepting parameters

The first formal param is a place-holder for the  source AST and the second argument can be of any other type.

### Quasiquation

Quasiquotation used inside complex code is not supported. Whenever possible simplify with

```
           (let ([r (with-output-language (L3 Stmt)
                      `(is ,current-cntx-id ,subj ,role))])
             (list r))])


         (let* ([stmt** (flatten (map (lambda (x) (Stmt x cntxs-root-dbid)) stmt*))]
                [branch-def** (cntxs-generate-all-branches)]
                [cntx-def** (cntxs-generate-all-all-groups)]
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
```

### Names to use

Never use the same name for the terminal and the terminal identiefier, so not ``name (name)`` but ``name-str (name)`` .

There can not be the same non-terminal name, and prefix identier, so something like this is not allowed: 

```
  (NameDef (name-def)
    (+ (name-def dbid name (maybe name?))))
```

use instead something like

```
  (NameDef (name-def)
    (+ (name-deff dbid name (maybe name?))))
```



