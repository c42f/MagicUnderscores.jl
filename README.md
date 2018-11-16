# MagicUnderscores

A prototype implementation for underscore notation in julia.  See https://github.com/JuliaLang/julia/pull/24990#issuecomment-439232734.

[![Build Status](https://travis-ci.org/c42f/MagicUnderscores.jl.svg?branch=master)](https://travis-ci.org/c42f/MagicUnderscores.jl)

## Quick Start

Here's an example, showing how `_` can be used as a placeholder when using the
`@_` macro from this package.

```julia
julia> using MagicUnderscores

julia> @_ map(sqrt(abs(_)) + 1, [-1,4])
3-element Array{Float64,1}:
 2.0
 3.0
```

In this case, this is just slightly shorter syntax for the following

```julia
julia> map(x->sqrt(abs(x)) + 1, [-1,4])
3-element Array{Float64,1}:
 2.0
 3.0
```

The interesting thing about the approach taken in this package is that the
tightness of the `_` binding may be tight or loose, depending on the
implementation of `MagicUnderscores.ubind` for your particular function. For
example, `filter` is bound loosely on the second argument so that `filter(f, _)`
means `x->filter(f,x)`, whereas `filter(_>2, a)` means `filter(x->x>2, a)`.
This can be very useful in piping, for example:

```julia
julia> @_ [1,2,3,4] |> filter(_>2, _)
2-element Array{Int64,1}:
 3
 4

julia> @_ [1,2,3,4] |> filter(_>2, _) |> length
2
```

