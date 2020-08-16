<!---
SPDX-License-Identifier: MIT
Copyright (C) 2020 Massimo Zaniboni <mzan@dokmelody.org>
-->

# Dok Programming Language

Dok is a data transformation and metaprogramming (i.e. code is data) language. 

Dok programs are preferably developed using progressive refinements from high-level code to low-level code:

* high-level code can be used as specification of low-level code
* many different branch implementations of the same parent code can be derived for supporting different run-time environments and usage scenario
* meta-annotations inside code and compiler-plugins can be used for deriving automatically low-level code from high-level code
* a complex problem can be partitioned in rather orthogonal aspects

Like Smalltalk, Dok is shipped with a reference IDE (DokMelody), because interaction between the programmer and the programming language is not a secondary aspect. Unlike Smalltalk, generated applications are not obliged to live in the same virtual environment of the IDE, but they can be compiled to different hosting platforms and runtime environments.

Dok programming language design follows these guidelines:

* whenever possible values are preferred to references
* nested transaction joins some of the benefit of functional programming (code with a predictable semantic) with imperative programming (convenience of local mutable state)
* every part of a Dok application can be meta-annotated and then manipulated through an extensible compiler
* simple types can be extended with contracts (i.e. logical properties)
* advanced features of the language are supported using compiler-plugins that can perform (local or global) analysis and transformation of the source code
* compiler-plugins effects must be always inspectable using the DokMelody IDE

## Temporary design

A first draft of the design (but all can change) is at https://bootstrapping.dokmelody.org/dok-lang/Dok.html

## Notes about design

### Hints by Clojure studying

In Dok abstract data structures have a common API like in Clojure, then the programmer specify better (using annotations or similar) the specific data structure to use.

In Clojure there are small details to consider:
* ``'(1 x)`` will not evaluate ``x`` and it is usually the form to use in meta programming
* ``(list 1 x)`` will evaluate ``x`` and it is usually the form to use in normal code
* vectors are faster than lists for lokkup and adding to the end
* lists are faster only for adding an elementi at head position
* so in Clojure vectors are used in idiomatic code more than lists

In Dok instead we have tuples as idiotamic data type, and streams/lists and Maps. Then correct data structure will be decided.
