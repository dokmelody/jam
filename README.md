# DokMelody-Jam

This is an initial prototype of Dok programming language (https://www.dokmelody.org), DokMelody IDE, and Doknil knowledge-base language, developed in Clojure for the 2020 https://repl.it Programming Language Jam.

## Mission

Win the Jam! :-)

Have fun creating something of original and hopefully better than current main stream tools, combining some good original idea or 
taking inspiration from papers. 

Use DokMelody for designing and improving Dok language, and this project, in "eat your own dog food" style.

## Current status

It is all in alpha/design/development state: many things can not work, all can change.

Jam progress is monitored on https://repl.it/@DokLang/jam-roadmap#README.md

## Documentation

See ``docs`` directory for more info.

## Prerequisites

Java Maven 3.6

Java JDK 11.

## Running

```
mvn compile exec:java -Denv=prod -Dconf=config-prod.edn
```

A web server will listen on port 3000.

## Testing

```
mvn compile exec:java -Denv=test -Dconf=config-test.edn
```

## Developing

For compiling only:

```
mvn compile -Denv=dev -Dconf=config-dev.edn
```

For compiling and running a web server

```
mvn compile exec:java -Denv=dev -Dconf=config-dev.edn
```

A web server will listen on port 3000, and a Clojure nrepl on port 7000, and web errors will contains 
(sometime sensitive) debug information. Whenever possible changes to Clojure code will be recompiled live.

## License

This software and related documentation is released under the MIT license (https://opensource.org/licenses/MIT).

DokMelody web application generated using Luminus version "3.83" template.

## Authors

Programming language designers and main developers:

* Massimo Zaniboni <mzan@dokmelody.org>
* TODO

Reviewers and contributors:

* TODO

## Contribuiting

Every modified file must report in the header the copyright of new contributors, following https://spdx.org/ standard. So something like

```
SPDX-License-Identifier: MIT
Copyright (C) YYYY-YYYY Some Name <some.emai@example.net>
```
