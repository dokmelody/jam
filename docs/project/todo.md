# Tasks

## P.A.R.A.

Cards managing the project can follow the P.A.R.A. approach:
* project: task,goal deadlines
* area: domain with standard rules and knowledge (papers and so on)
* resources: material to study, organize and maybe apply some day
* archive: (TAG) not any more used

## Display Cards in Clojure

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

## Install and run on repl.it server

MAYBE first install on a demo server

MAYBE repl.it supports Maven packages, and I can update Lein to maven support.

TODO Otherwise download dependencies locally and explicitely using something like https://github.com/technomancy/leiningen/blob/stable/doc/TUTORIAL.md#checkout-dependencies

TODO also JS packages must be generated and downloaded

### Check repl.it instance without hacker-upgrade

I upgraded my repl.it account to "hacker". They are $5 monthly and I can unsubscribe when I will never use it. It has more RAM and CPU of normal instances. Probably if a team member without hacker-upgrade fork the instance, then there can be problem running it, because it is a Java framework.

## Caching of http query results

At every start of the server the DB date is updated.

At every change/update of DB at run-time the DB date is updated.

The server use a cache for the answers and send to HTTP clients the since-modified.. according the DB update date.

In this way there is an efficient caching both on the server and client side, and the caching code is very simple.

## Attributes grammars in Clojure

MAYBE Dok compiler and runtime will be based also on attribute grammars. In case study 

    https://github.com/brandonbloom/ascribe

## Integrate the repo with Zulip

After I pubblish the repo into repl.it check if there is a discussion board.

If not continue using Zulip and:

* move dok-jam repository to GitHub
* link GitHub repo with repl.it and Zulip

## Document DokMelody and Doknil using DokMelody itself

## Document Dok language using DokMelody

