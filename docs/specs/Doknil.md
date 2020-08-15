<!---
SPDX-License-Identifier: MIT
Copyright (C) 2020 Massimo Zaniboni <mzan@dokmelody.org>
-->

# Doknil - A Declarative Language for Specification of Knowledge Bases 

Doknil is a relative simple (ontology language)[https://en.wikipedia.org/wiki/Ontology_language] for linking piece of information, and deriving useful facts. 

It is more oriented towards expressing instances of a domain, than describing the derivation rules of complex domains. In fact in Doknil the derivation rules are few and fixed, and the user can not add more of them.

From an expressive point of view, Doknil is less powerful than (OWL)[https://en.wikipedia.org/wiki/Web_Ontology_Language], but more powerful than (RDF)[https://en.wikipedia.org/wiki/Resource_Description_Framework]. Contrary to OWL, Doknil can manage directly contexts (i.e. facts that are true only inside a certain context).

## Doknil semantic

### Instances and Roles

```
c isa Company
d isa Department of c
p isa Project of d

i isa Issue of p
```

Doknil has ``instances`` (i.e. cards in DokMoledy) that can assume ``roles`` (i.e. class or types of instances).

An ``instance`` can play a ``role`` for a certain instances. For example ``issueX isa Issue in projectY``. 

``Roles`` can form an hierarchy, e.g. ``Task, Task/Issue, Task/Feature``.

``Instances`` can have multiple roles.

Instances used as "owners" (i.e. in the ``in ...`` part) can form an hieararchy. For example ``companyX, companyX/departmentY, companyX/projectZ``.

Doknil queries and rules follow a predictable inference semantic:
* if ``x`` plays a role ``R`` for an owner ``x/y``, then it plays the same role also for the parent of ``x`` (e.g. an issue of ``companyX/projectZ`` is an issue also for ``companyX``)
* if ``x`` plays a role ``R1/R2``, then it plays also the role ``R1`` (e.g. if ``x`` is an ``Issue`` then it is also a ``Task``)

### Contexts

Facts can be valid only inside a certain context (e.g. a certain domain, paper, author, company, department, project). Facts are propagated automatically parent to child contexts (e.g. a fact true for the world is true also for a companyX). Some facts can be explicitely negated in child contexts (e.g. a research project can not believe in a common assumption, and explore a different branch of reasoning). 

Contexts can form an hierarchy, for example ``/world/companyX/departmentY/workingGroupZ``. ``world`` is the root context and it can be omitted because it is implicit.

Contexts can be used also for grouping facts of a certain domains of discourse, that can be later negated in another branchg context. 

An example:

```
City
City/Capital

Nation
Continent

world/places --> {
  southAmerica isa Continent
  cile isa Nation of southAmerica
  santiago isa Capital of cile
}

lordOfTheRings/places --> {
  !replaceContext world/places

  gondor isa City
}
```

### Negation

Doknil assumes (closed-world-assumption)[https://en.wikipedia.org/wiki/Closed-world_assumption], i.e. what is not currently known to be true, is false.

Sometime the DokMelody IDE can manage at the UI level some roles according the  (open-world-assumption)[https://en.wikipedia.org/wiki/Open-world_assumption], i.e. that the truth value of a statement may be true irrespective of whether or not it is known to be true. But this is not formalized.

Despite the closed-world-assumption, Doknil can support also explicit negation, using the contexts, and in particular the ``!replaceContext ..`` statement. So a context can explicitely negate facts asserted in a context. This information is used for sure during derivation of facts, but it can be used also from the DokMelody IDE for showing in a clear way the differences of a branch context respect its parent context.

### Attributes vs links

A link (i.e. a relationships in graph-databases) connects two instances/cards using the Doknil semantic and derivation rules.

An attribute (i.e. a property in graph-database) is a named property of an instance containing usually a value, but also a reference to another instance.

In Doknil there are only links. Instances can have attributes, but they are managed externally to Doknil, in the host system containing effective representation of instances. Optionally an instance can generate automatically links, according its content, expecially if these links must follow the derivation semantic of Doknil. In this way queries are simpler and coherent.

## Doknil syntax

Like in case of [RDF](https://en.wikipedia.org/wiki/RDF_query_language) there can be different syntaxes, e.g. inside Dok code, inside Clojure code, and so on.

## Validation using PMBOK specification

PMBOK is a standard for describing projects. It is rather complete and complex. There is a specification of some parts of PMBOK to OWL here http://pszwed.ia.agh.edu.pl/ontologies/ If Doknil is useful for representing many parts of PMBOK then it is probably good enough in many other contexts.

Obviously this is only an informal validation of Doknil ideas, while a more complete validation should be based on analyzing its expressive powers, and comparing with other approaches.

### Events

Events are described in PMBOK with something like this:

```
Event --> (
  /Phase
  /PhaseStage --> (
    /Closing
    /Executing
    /Initianing
    /MonitoringAndControlling
    /Planning   
  )
)
```

and there are rules and properties like

```
pmbok.Phase ? DurableEvent and pmbok.Event and (consistsOf exactly 1 pmbok.Closing) and (consistsOf exactly 1 pmbok.Executing) and (consistsOf exactly 1 pmbok.Initiating) and (consistsOf exactly 1 pmbok.MonitoringAndControlling) and (consistsOf exactly 1 pmbok.Planning)

nextPhase Domain pmbok.Phase
previousPhase Domain pmbok.Phase
nextPhase Range pmbok.Phase
previousPhase Range pmbok.Phase
pmbok.PhaseStage ? belongsTo exactly 1 pmbok.Phase
pmbok.Project ? consistsOf min 1 pmbok.Phase
```

Probably the state of an event is embeded in the more specific class, like ``Event/Closing`` and ``nextPhase`` force a mandatory transition to next phase.

In Doknil and DokMelody:
* an event is a card
* an event as associated documents, that are cards
* every associated document can be for a different phase of the event, so phases are roles
* the event is the owner, because it can be owned by the company organizing it and so on
* an event can be (for the company or the world) in a certain phase. Documents of the past are still referred to the specific phase.

```
Phase --> (
  /Planning
  /Initiating
  /Executing
  /Closing
  /Closed
)

State --> Phase

Company
Event

acme isa Company
showCase isa Event of acme
plan1 isa Document
plan1 isa Planning of showCase

showCase isa State/Planning

# We will add some constraints. They will use queries seen as tuples, starting from a KB-friendly query.
# So after the first extraction of data, it will follow a relational approach, and not a logical one.
# Both intensional and extensional tuples will be returned.
# MAYBE probably a more logical approarch is better. The relational one was inspired by R
# and by the fact that at certain point one had to manage tuples explicitely in an imperative setting.

@Require {
  ?{x::Event isa s::State}.select(?x).distinct() == ?{x::Event}.distinct()
  # an event must have at least one state, i.e. there is no event without a state
}

@Require {
  ?{x isa s::State}.groupBy(?x).forEach{
    self.group.select(?s).count() == 1
    # an event must have exactly one state 
  }
}
```

The Doknil representation seems more uniform for a knowledge-base of documents (i.e. cards).

An event can have a location, a date and other properties. In Doknil this is solved adding these properties to the cards associated to the role/type/class ``Event``. Additionally this card can generate links to add to the KB for easier queries

```
Location

europe isa Location of world
france isa Location of europe
paris isa Location of france

showCase isa Event of paris

?{showCase isa Event of europe}
```

In Doknil there is only one way to express these relationships:
* identify the owner and put in the ``of ...`` part
* ``Location`` is a role/class/type
* an instance of ``Location`` can have an owner that is the parent location containing it
* queries on locations can use automatically the owner hierarchy
* the majority of human KB have the same recurring concept of hierarchy and role, and Doknil exploit this

