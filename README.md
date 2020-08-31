# DokMelody-repl-it-jam

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

## Running on Repl.it

[![Run on Repl.it](https://repl.it/badge/github/dokmelody/jam)](https://repl.it/github/dokmelody/jam)

The Repl.it ``Run`` button is associated to the command 

```
bash ./run.sh --on-repl-it
```

It will install missing packages and launch a web server listening on a local port, and that can be accessed externally from an https URL provided by repl.it after it starts.

For testing

```
bash ./run.sh --on-repl-it test
```

## License

This software and related documentation is released under the MIT license (https://opensource.org/licenses/MIT).

## Authors

Programming language designers and main developers:

* Massimo Zaniboni <mzan@dokmelody.org>
* Ali Ahsan <aliahsan07@outlook.com>

Reviewers and contributors:

* TODO

## Contribuiting

Every modified file must report in the header the copyright of new contributors, following https://spdx.org/ standard. So something like

```
SPDX-License-Identifier: MIT
Copyright (C) YYYY-YYYY Some Name <some.emai@example.net>
```
