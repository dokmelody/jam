# In progress

## Stories

### TODO Doknil parser

TODO implement a parser of Doknil returning true if it parse correctly some Doknil code
TODO define a syntax for the language
TODO document the syntax of the language

### TODO Doknil compiler

TODO to be fair some facts are intensional and it is important also using Clojure code so the syntax will be readable Clojure code. Manage this after a compiler is written and it is clear which API use for generating Doknil code inside Clojure.

MAYBE during cards creation manage CONTEXT as a dynamic attribute
MAYBE support current owner and role and context as dynamic attribute during declaration

### TODO Create cards

TODO parse markdown content
TODO accept links in the Markdown processed (MAYBE customize it)
TODO a card is created by code, because I can use literate programming and templates
TODO cards can be created combining chunks of code, in literate-programming style.
TODO express Doknil rules as readable code and generate both the documentation card and the Clojure code
TODO a CARD can be defined, but until it is not used in a CONTEXT, its implicit facts are not generated

#### TODO Compare the size of Racket repo with Clojure repo, after installation of all tools

FACT the Maven repo was more than 100M on .m2 directory

### TODO Doknil semantic

TODO find a way for saying that a certain part of a company or similar believe in things different (like context)

TODO branch.group is not important for the KB query and related semantic, but only in the UI navigation of the KB for showing the schema used, and editing it.

TODO Create a syntax and semantic for queries

TODO Rewrite unit tests of Doknil semantic in Doknil

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

# Done Tasks

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

