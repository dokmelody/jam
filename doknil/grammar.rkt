;; SPDX-License-Identifier: MIT
;; Copyright (C) 2020 Massimo Zaniboni <mzan@dokmelody.org>

#lang brag

kb: role-def* stmt*

stmt:
  subject ISA role complement?
| cntx "-->" "{" stmt* "}"
| include-cntx
| exclude-cntx

role-def: "/" role ID? role-children?

role-children: "-->" "(" role-def* ")"

include-cntx: INCLUDE cntx

exclude-cntx: EXCLUDE cntx

subject: OBJ

object: OBJ

role: ID

complement: ID object

cntx: branch group

branch: CNTX ("/" CNTX)*

group: ("." ID)*
