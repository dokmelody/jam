;; SPDX-License-Identifier: MIT
;; Copyright (C) 2020 Massimo Zaniboni <mzan@dokmelody.org>

#lang brag

kb: (role-def | stmt)*

stmt:
  subject ISA role (complement object)?
| cntx "-->" "{" stmt* "}"

role-def: "/" role complement ("-->" "(" role-def* ")")?

subject: OBJ

object: OBJ

role: ID

complement: ID

cntx: branch group?

branch: CNTX ("/" CNTX)*

group: "." ID
