<!---
SPDX-License-Identifier: MIT
Copyright (C) 2020 Massimo Zaniboni <mzan@dokmelody.org>
-->

# DokMelody IDE and Knowledge-Base Management Tool

DokMelody represents information (e.g. piece of code, issues, tasks, documentation, and so on) inside linked cards.

Information should be easily navigable.

Doknil language is used for representing links between cards, while cards inside DokMelody are the instances of Doknil.

## Inspirations

DokMelody takes inspiration from:
* (DITA)[https://en.wikipedia.org/wiki/Darwin_Information_Typing_Architecture] because it is based on composition and relationships between short piece of information
* (Zettelkasten)[https://en.wikipedia.org/wiki/Zettelkasten] because links between cards are important as the content of cards itself
* (TiddlyWiki)[https://en.wikipedia.org/wiki/TiddlyWiki] because multiple cards can be showed on the same page, following free associations

## Cards

A card is the single unit of information and it corresponds to an ``instance`` on the Doknil side. It is called card because it is usually showed as a distinct card inside DokMelody UI.

A card have a unique mime-type:
* PDF
* SVG
* markdown
* etc..

## Compound cards

From the point of view of the Doknil knowledge-base (KB) there are no compound/nested cards, so every card is a single unit of information that can not be further decomposed. Only links between different cards exists.

From the point of view of the User Interface (UI), cards can reuse other cards, so they can be composed/nested toghethers. 

These two views are not in conflict because composed cards on the UI side, remains distinct ``instances`` on the KB side, and their composition is managed through Doknil ``links``.

### Linked cards

A card can reference another card. This is like an HTML link in a HTML document. Then a corresponding Doknil link can be generated, in order to represent this link not only on the UI side, but also in the KB.

A linked card can be represented in the UI only with a link, or with a link and a summary of the card content, or a link and some text describing the card, or a link and some minor modification of the card content.

If no specific relation (e.g. ``isa Issue``) is specified, then a generic ``destCard isa Reference of sourceCard`` is generated.

### Included cards

A card can include the content of another card, without creating a corresponding link on the KB. For example there can be sentences, images, graphs that can be repeated in different contexts, without giving them a separate meaning. It can be seen as a composition of syntatictal chuns, without any semantic implication.

### Compound Document 

There can be compound cards playing the role of DITA-MAPS: they reference a list of cards playing the role of sections or chapters. The main card is a document, and it is built composing other cards. The main card can list all levels, or each referenced card can be itself a compound document card.

The DokMelody UI will display this compound document in piece. Every referenced card will be a distinct piece, and there will be navigation links for navigating inside the structure of the compound document.

Included cards can be (slightly) modified from the source document. The idea it is that cards are small pieces of reusable information, and sometime information can not be used exactly in the original form.

A card can be used in different compound documents. Obviously the UI will take note of the context, and the navigation links of the card will be related to the current context.

### Links inside Compound Documents

The hierachy of compound documents forms an hierarchy of owner documents. So ``destCard isa Reference of bookX/sectionY/chapterZ`` became also a reference of ``destCard`` inside ``bookX/sectionY`` and ``bookX``. This hierarchy is exported to KB side, and will be useful for queries, also if usually one is interested to the most specific link.

