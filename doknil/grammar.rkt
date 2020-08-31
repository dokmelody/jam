;; SPDX-License-Identifier: MIT
;; Copyright (C) 2020 Massimo Zaniboni <mzan@dokmelody.org>

#lang brag

kb:
  role-def* stmt*

role-def:
  "/" ID ("-->" "(" role-def* ")")?

stmt:
  OBJ ISA role (complement OBJ)?
| cntx "-->" "{" stmt* "}"

role:
  ID

complement:
  ID

cntx:
  CNTX ("/" CNTX)* ("." ID)?
