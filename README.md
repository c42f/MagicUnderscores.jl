# MagicUnderscores

A prototype implementation for underscore notation in julia.  See https://github.com/JuliaLang/julia/pull/24990#issuecomment-439232734.

Simple example, showing that `_` can be used as a placeholder to generate something like a lambda:

```julia
julia> using MagicUnderscores

julia> @_ map(sqrt(abs(_)) + 1, [-1,2,3])
3-element Array{Float64,1}:
 2.0              
 2.414213562373095
 2.732050807568877
```

The interesting thing about this hack is that the tightness of `_` binding may
be tight or loose, depending on the implementation of `MagicUnderscores.ubind`
for your particular function.  For example, `filter` is bound loosely on the second
argument so that `filter(f, _)` means `x->filter(f,x)`, whereas
`filter(_>2, a)` means `filter(x->x>2, a)`.  This is very useful in piping,
where we can use both at once to have

```julia
julia> @_ [1,2,3,4] |> filter(_>2, _)
2-element Array{Int64,1}:
 3
 4

julia> @_ [1,2,3,4] |> filter(_>2, _) |> length
2
```


