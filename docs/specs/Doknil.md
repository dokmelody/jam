<!---
SPDX-License-Identifier: MIT
Copyright (C) 2020 Massimo Zaniboni <mzan@dokmelody.org>
-->

# Doknil - A Declarative Language for Specification of Knowledge Bases 

Doknil is a relative simple (ontology language)[https://en.wikipedia.org/wiki/Ontology_language] for linking piece of information, and deriving useful facts. 

Doknil is more oriented towards expressing links between different entities of a domain, than deriving all attributes of entities, i.e. it is more a tool for human oriented navigation in a knowledge base, than a tool for describing all the information in a machine processable format.

In Doknil the derivation rules are few and fixed, and the user can not add new derivation rules. From an expressive point of view, Doknil is less powerful than (OWL)[https://en.wikipedia.org/wiki/Web_Ontology_Language], but more powerful than (RDF)[https://en.wikipedia.org/wiki/Resource_Description_Framework]. Contrary to OWL, Doknil can manage directly contexts (i.e. facts that are true only inside a certain context).

## Doknil semantic

### Instances

```
$c isa company
$d isa department of $c
$p isa project of $d

$i isa issue of $p

$k isa document
$k is related to $i
```

``c``, ``d``, ``p``, ``k`` and ``i`` are ``instances``:
* they are entities, so with an identity, and internal attributes that can change
* they are often associated to DokMelody ``cards``, and/or in general to some external object storing internal attributes associated to the ``instance`` and representing its real content
* they can have one or more ``role`` associated to some other entities, e.g. ``i`` plays the role of ``issue`` respect instance ``p`` which plays the role of ``project`` respect instance ``d`` which plays the role of ``department`` respect instance ``c`` that is a ``company``. Note that ``company`` is still a role, but of the ``root`` instance.

### Subject

In a fact like ``$i isa issue of $p``, ``i`` is the ``subject`` of the fact, and it is obviously an ``instance``.

### Roles

In a fact like ``$i isa issue of $p``, ``issue`` is a ``role``. A ``role`` can be seen also as the type of the ``subject``.

A ``subject`` can assume different roles for different owners. For example the same issue can be an issue and a cost for a company and a billable work for a support company.

``Roles`` can form an hierarchy, e.g. 

```
/task of --> (
  /issue of
  /feature of
)
```

``Feature`` (i.e. ``Task/Feature`` using the full role nome) is a more specific role of the more generic role ``Task``. 

In Doknil a fact about a specific role is also a fact about the more generic role. For example if ``x isa Feature of p``, then ``x isa Task of p``.

If a role has complement ``of`` then all its children roles must have the same complement, because it must be explicit that the role follow the "parts semantic".

### Object complements

In a fact like ``$i isa issue of $p``, ``p`` is the object ``complement``. It is an instance for which ``i`` plays the role of ``Issue``.

The fact can use different syntax patterns like ``... of $p``, ``... respect $p``, ``... to $p``, ``... for $p`` etc..

### Parts

A fact like ``$x isa r of $y`` specifies also that ``x`` is part of ``y``. ``y`` is always an object ``complement`` and ``x`` is the subject. But a new implicit fact like ``$x is part of $y`` is derived.

Parts are defined only using the ``... of $p`` syntax pattern. So the ``of`` is mandatory. All other forms like ``to``, ``respect`` and so on, do not introduce a part/owner relationship.

An instance can be part of different owners, for example an issue shared between two different departments.

Every time there is pattern like ``$s isa role of $p``, with ``... of $p``, then ``s`` is considered part of ``p``.

Parts are important because in Doknil a fact of a part is also a fact for the owner of the part. For example given an hierarchy of parts ``c/d/p`` (``company/ department/project``), the fact ``$i isa issue of $p`` derives also the facts ``$i isa issue of $d`` and ``$i isa issue of $c``.

### Attributes vs links

A link (i.e. a relationships in graph-databases) connects two instances/cards using the Doknil semantic and derivation rules. In Doknil a link is always a relationship between an ``instance`` and another ``owner`` instance (that can be also ``root`` if not specified) according a specific ``role``.

An attribute (i.e. a property in graph-database) is a named property of an instance containing usually a value, but also a reference to another instance.

In Doknil there are only links. Instances can have attributes, but they are managed externally to Doknil, in the host system containing effective representation of instances. Optionally an instance can generate automatically links, according its content, expecially if these links must follow the derivation semantic of Doknil. In this way queries are simpler and more coherent because they can filter only on Doknil links.

### Hierarchical contexts

Facts can be valid only inside a certain ``context`` (e.g. a certain domain, paper, author, company, department, project). ``Contexts`` can form an hierarchy. A missing context is the implicit ``Root`` context. 

Facts are propagated automatically from parent to child contexts, but not from children to parent context.

```
World --> {
  $mars isa planet
}

World/LordOfTheRings --> {
  $gondor isa city
}

World -->
  Asimov --> {
    FoundationSeries --> {
      $trantor isa planet
    }
  }
}
```

So in ``World/LordOfTheRings`` context ``Mars`` is a planet, and ``$gondor`` isa city, but in ``World/Asimov/FoundationSeries`` ``$gondor`` is not a city because ``World/LordOfTheRings`` is not one of its parents.

### Groups of facts

A set of facts inside a context can be grouped inside a common group (i.e. a certain domain of discourse), that can be later included in another context, or excluded in a child context.

A group context does not change the semantic of fact derivations in contexts of the same hierarchy, so facts can be freely refactored in different groups without changing the semantic of the knowledge-base.

A full context is formed by a context hierarchy followed by an optional group context hierarchy. Something like ``c1/c2/c3.g1.g2.g3``. 

### Branch contexts

A child context can exclude to import facts from a parent context using something like ``!exclude some/parent/context.some.group.context``. 

```
city
city/capital

nation
continent

World --> {
  $mars isa planet
  $earth isa planet

  .earth.places --> {
    $southAmerica isa continent
    $cile isa nation of $southAmerica
    $santiago isa capital of $cile
  }
}

World/LordOfTheRings.places --> {
  !exclude World.earth.places

  $gondor isa city
}
```

In this example ``$santiago`` is not a city in context ``LordOfTheRings`` context, because it overrides the facts about ``World.earth.places``. But ``$mars`` is still a planet also in ``LordOfTheRings`` context.

### Reusing context facts

Facts specified in a distinct (i.e. non-parent) context can be imported in a new context using something like ``!include some/distinct/context.some.group``.

```
World/ThesisOnTolkien --> {
  !include World/LordOfTheRings.places
}
```

### Context semantic

* ``!exclude`` specifies a parent context, because non parent context are excluded by default, and don't need it.
* ``!include`` specifies a context on a distinct path, because parent context are included by default (i.e. a fact of parent context is also a fact of a child context).
* Facts inside a parent context are also facts of the child context (e.g. ``c1`` facts are also facts of ``c1/c2``).
* Facts of a parent group context are also facts of a child group context (e.g. ``c1.g1`` facts are also facts of ``c1.g1.g2``).
* If a target context include (or exclude) facts of a context ``c1.g1``, then also facts of context ``c1.g1.g2`` are included (or excluded), but not facts on distinct group ``c1.h1``.
* If a target context include (or exclude) facts of a context ``c1/c2.g1``, then also facts of context ``c1/c2`` and parent context ``c1`` are included. But facts of context ``c1/c2.h1`` are not included.
* The empty (i.e. unspecified) context is the root context.

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

## Example of a Doknil schema

### Design principles

Doknil schema should be easy to define because there are usually no alternative ways to express them:
* a ``role`` has no inverse role, while in RDF and OWL a property can have an inverse property
* a ``subject`` is always the most specific entity respect the ``part`` or the ``complement``, so the direction is clear. Put in other words: a subject usually plays a specific role in a bigger organization/domain/environment and not vice versa 
* a ``context`` can not be modelled like a ``part`` because in a context facts are propagated from root context to most specific context and they often plays the role of branches, while in part facts are prapagated from most specific part to root part

### Example

```
$garbageCollection is part of $memoryManagement
$referenceCounting is part of $memoryManagement
```

This must be clearly modelled as ``part`` because every property of ``garbageCollection`` is also a property of ``memoryManagement``.

```
$garbageCollection isa possibleSolution for $safety
```

This is not a part relationship. ``$safety`` is a more broad concept respect ``$garbageCollection`` so ``$safety`` is the ``complement`` and ``$garbageCollection`` the subject. 

```
Jvm --> {
  $garbageCollection isa solution for $safety
}
```

``jvm`` is a context because every fact inside it, it is not true for parent contexts (i.e. not for all other run-times ``garbageCollection`` is an adopted solution), while it is true for all contexts derived from ``jvm``, for example ``jvm/oracle``, ``jvm/openJ9``. In the few cases where some fact asserted in ``jvm`` context is not true, there are negation and branches that can be used.

## Validation using PMBOK specification

PMBOK is a standard for describing projects. It is rather complete and complex. There is a specification of some parts of PMBOK to OWL here http://pszwed.ia.agh.edu.pl/ontologies/ If Doknil is useful for representing many parts of PMBOK then it is probably good enough in many other contexts.

Obviously this is only an informal validation of Doknil ideas, while a more complete validation should be based on analyzing its expressive powers, and comparing with other approaches.

### Events

Events are described in PMBOK with something like this:

```
/event --> (
  /phase
  /phaseStage --> (
    /closing
    /executing
    /initianing
    /monitoringAndControlling
    /planning   
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
/phase --> (
  /planning
  /initiating
  /executing
  /closing
  /closed
)

state --> phase

company
event

$acme isa company
$showCase isa event of $acme
$plan1 isa document
$plan1 isa planning of $showCase

$showCase isa state/planning

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

