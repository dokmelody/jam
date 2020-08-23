<!---
SPDX-License-Identifier: MIT
Copyright (C) 2020 Massimo Zaniboni <mzan@dokmelody.org>
-->

# Doknil - A Declarative Language for Specification of Knowledge Bases 

Doknil is a relative simple (ontology language)[https://en.wikipedia.org/wiki/Ontology_language] for linking piece of information, and deriving useful facts. 

It is more oriented towards expressing links between different entities of a domain, than deriving all attributes of entities, i.e. it is more a tool for human oriented navigation in a knowledge base, than a tool for describing all the information in a machine consumable format.

In Doknil the derivation rules are few and fixed, and the user can not add more of them. From an expressive point of view, Doknil is less powerful than (OWL)[https://en.wikipedia.org/wiki/Web_Ontology_Language], but more powerful than (RDF)[https://en.wikipedia.org/wiki/Resource_Description_Framework]. Contrary to OWL, Doknil can manage directly contexts (i.e. facts that are true only inside a certain context).

## Doknil semantic

### Instances

```
c isa Company
d isa Department of c
p isa Project of d

i isa Issue of p
```

``c``, ``d``, ``p`` and ``i`` are ``instances``:
* they are entities, so with an identity
* they are often associated to DokMelody ``cards``, and/or in general to some external object storing more attributes associated to the ``instance`` and representing its real content
* they can have one or more ``role`` associated to some other entity, e.g. ``i`` plays the role of ``Issue`` respect instance ``p`` which plays the role of ``Project`` respect instance ``d`` which plays the role of ``Department`` respect instance ``c`` that is a ``Company``. Note that ``Company`` is still a role, but of the ``root`` instance.

### Roles

A ``role`` of an ``instance`` can be seen also as the type or class of the ``instance``.

``Roles`` can form an hierarchy, e.g. 

```
Task --> (
  /Issue
  /Feature
)
```

``Feature`` (i.e. ``Task/Feature`` using the full role nome) is a more specific role of the more generic role ``Task``. 

### Owners

The ``x isa R of y`` specifies also that ``x`` is an instance owned from (i.e. is part of) instance ``y``. 

An instance can have more than one direct owner. In this case the instance is considered shared. For example an issue shared between two different departments.

An instance can assume different roles for different owners. For example the same issue can be an issue and a cost for a company and a billable work for a support company.

### Derivation of intensional facts

Extensional (base) facts are the facts directly declarated like ``i isa Issue of p``.

Intensional (derived) facts can be derived by Doknil fixed and predictable semantic rules:
* ``i isa Task of p`` because ``Issue`` is a child role of the parent role ``Task``
* ``i isa Issue of c`` because ``i`` is part of ``d`` that is part of ``c``
* ``i isa Task of c`` for the same reason of the first point
* and so on...

### Attributes vs links

A link (i.e. a relationships in graph-databases) connects two instances/cards using the( Doknil semantic and derivation rules. In Doknil a link is always a relationship between an ``instance`` and another ``owner`` instance (that can be also ``root`` if not specified)according a specific ``role``.

An attribute (i.e. a property in graph-database) is a named property of an instance containing usually a value, but also a reference to another instance.

In Doknil there are only links. Instances can have attributes, but they are managed externally to Doknil, in the host system containing effective representation of instances. Optionally an instance can generate automatically links, according its content, expecially if these links must follow the derivation semantic of Doknil. In this way queries are simpler and more coherent because they can filter only on Doknil links.

### Hierarchical contexts

Facts can be valid only inside a certain ``context`` (e.g. a certain domain, paper, author, company, department, project). ``Contexts`` can form an hierarchy. ``world`` is the root context.

Facts are propagated automatically from parent to child contexts, but not from children to parent context.

```
world --> {
  mars isa Planet
}

world/lordOfTheRings --> {
  gondor isa City
}

world -->
  asimov --> {
    foundationSeries --> {
      trantor isa Planet
    }
  }
}
```

So in ``world/lordOfTheRings`` context ``mars`` is a planet, and ``gondor`` isa city, but in ``world/asimov/foundationSeries`` ``gondor`` is not a city because ``world/lordOfTheRings`` is not one of its parents.

### Group contexts

A set of facts inside a context can be grouped inside a common group (i.e. a certain domain of discourse), that can be later negated in another branch context. 

A group context does not change the semantic of fact derivations in other contexts, because it does not change context hierarchy. Facts can be always refactored and grouped in a new group context without changing the semantic of other already specified contexts. This is intentional and useful for branching contexts.

Group contexts can form an hierarchy.

A full context is formed by a context hierarchy followed by an optional group context hierarchy. Something like ``c1/c2/c3.g1.g2.g3``. 

### Branch contexts

A child context can exclude to import facts from a parent context using something like ``!exclude some/parent/context.some.group.context``. 

```
City
City/Capital

Nation
Continent

world --> {
  mars isa Planet
  earth isa Planet

  .earth.places --> {
    southAmerica isa Continent
    cile isa Nation of southAmerica
    santiago isa Capital of cile
  }
}

world/lordOfTheRings.places --> {
  !exclude world.earth.places

  gondor isa City
}
```

In this example ``santiago`` is not a city in context ``lordOfTheRings`` context, because it overrides the facts about ``world.earth.places``. But ``mars`` is still a planet also in ``lordOfTheRings`` context.

### Reusing context facts

Facts specified in a distinct (i.e. non-parent) context can be imported in a new context using something like ``!include some/distinct/context.some.group``.

```
world/thesisOnTolkien --> {
  !include world/lordOfTheRings.places
}
```

Also in this case if one see that some group of facts can be reused, he can freely refactor the source context adding a group (because the semantic of the source context will not change), and then import the facts in the target context.

### Context information propagation

* Facts inside a parent context are also facts of the child context (e.g. ``c1`` facts are also facts of ``c1/c2``).
* Facts of a parent group context are also facts of a child group context (e.g. ``c1.g1`` facts are also facts of ``c1.g1.g2``).
* If a target context include/exclude facts of a context ``c1.g1``, then also facts of context ``c1.g1.g2`` are included/excluded.
* If a target context include/exclude facts of a context ``c1.g1``, then also facts of context ``c1.g1.g2`` are included/excluded, while there is no effect on distinct source contexts like ``c1/c2`` and ``c1.g3``.

### Negation

Doknil assumes (closed-world-assumption)[https://en.wikipedia.org/wiki/Closed-world_assumption], i.e. what is not currently known to be true, is false.

Sometime the DokMelody IDE can manage at the UI level some roles according the  (open-world-assumption)[https://en.wikipedia.org/wiki/Open-world_assumption], i.e. that the truth value of a statement may be true irrespective of whether or not it is known to be true. But this is not formalized in Doknil, and it is only implicitely managed from the DokMelody UI.

Despite the closed-world-assumption, Doknil can support also explicit negation, using the contexts, and in particular the ``!exclude`` statement. So a context can explicitely negate facts asserted in a group context. This information is used for sure during derivation of facts, but it can be used also from the DokMelody IDE for showing in a clear way the differences between two contexts.

### Reification

Doknil does not support reification, so facts can not be subject of discourse. This simplify the semantic of the language.

### Meta information

``contexts`` and ``roles`` can be used as ``instances`` and so they can be used as subjects of new links.

This is useful in particular on the UI/IDE side for grouping roles and contexts according different aspects.

## Doknil syntax

Like in case of [RDF](https://en.wikipedia.org/wiki/RDF_query_language) there can be different syntaxes, e.g. inside Dok code, inside Clojure code, and so on. The important thing is the semantic and the related concepts.

The previous examples were expressed in Dok-like syntax.

### Namespaces

``instances``, ``contexts`` and ``roles`` share the same namespace, i.e. there can be an instance and a context both named ``world``. ``Roles`` starsts with capital letters, so in practice there can not be clashes with ``instances`` and ``contexts``.

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

