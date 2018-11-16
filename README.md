# MagicUnderscores

A prototype implementation for underscore notation in julia.  See https://github.com/JuliaLang/julia/pull/24990#issuecomment-439232734.

Simple example, showing that `_` can be used as a placeholder to generate something like a lambda:

```julia
julia> using MagicUnderscores

julia> @_ map(sqrt(abs(_)) + 1, [1,2,3])
3-element Array{Float64,1}:
 2.0              
 2.414213562373095
 2.732050807568877
```

The interesting thing about this hack is that the tightness of `_` binding may be tight or loose, depending on the implementation of `MagicUnderscores.ubind`.  For example, map is bound loosely on the second argument so that


`map(f, _)` means `x->map(f,x)`, whereas `map(_, a)` means `map(x->x, a)`.  We
can even combine these to have:

```julia
julia> @_ map(map(sqrt(abs(_)) + 1, _), [[1,2], [3,4]])
2-element Array{Array{Float64,1},1}:
 [2.0, 2.41421]
 [2.73205, 3.0]
```

