# Scratchpad notes

## DokMelody and Doknil for documenting Dok PL

Is Doknil approach really useful for documenting Dok? Can be used from researcher for reasoning on information? I will try!

### Assert facts

```
dsl: MD<<
  A domain specific language (DSL) is a computer language specialized to a particular application domain.
>>

dsl isa ProgrammingParadigm

metaprogramming/localAnalysis --> {
  dslCodeExpansion: MD<<
    A library can define a ${link(dsl)}. The ${link(dsl)} can be expanded into rather complex host PL constructs, according the semantic of the DSL.

    The semantic of the DSL is implemented in the host PL, but after one study the semantic of the guest DSL, the code is more compact because all expanded code remain implicit.
  >>

  dslCodeExpansion isa ProgrammingParadigm
}

metaprogramming/globalAnalysis --> {
  globalCodeAnalysisAndExpansion: MD<<
    A library implementing ${link(dsl)} can analyze the code in which it is used and expand the DSL code according its effective usage, and/or warn the user if it is used in a bad way.

    For example a floating point numeric library can analyze the data-flow of numeric operations and reordering mathematical operations for reducing the error propagation. It can suggests equivalent but better operations.

    So the library became a sort of compiler and it can include a lot of knowledge of the DSL domain. 
  >>

  globalCodeAnalysisAndExpansion isa ProgrammingParadigm
}

metaprogramming/lisp --> {
  !includeContext metaprogramming/localAnalysis
}

metaprogramming/dok --> {
  !includeContext metaprogramming/localAnalysis
  !includeContext metaprogramming/globalAnalysis

  diff1: MD<<
    Libraries can perform global code analysis and not only naive local expansion.
  >>

  diff1 isa Difference respect metaprogramming/lisp
}
```

TODO says in the manual that the ``of ..`` can accepts synonimous like ``respect ...`` etc...

### Some query

```
?{
  # all the features of Dok related to metaprogramming  
  metaprogramming/dok {?x isa ProgrammingParadigm} 

  # all the differences of Dok respect other metaprogramming systems
  metaprogramming/dok {?x isa Difference respect metaprogramming/?anotherContext }
}
```

### DokMelody IDE

The idea is that one can see a description of ``globalCodeAnalysisAndExpansion`` inside a card, and then in the bottom also suggestions for listing all ``Feature`` inside the same context, or differences and so on. So the KB is navigable.