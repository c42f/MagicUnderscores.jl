module MagicUnderscores

export @_, @lazy_

import Base: tail

#-------------------------------------------------------------------------------
# Machinery for lowered form
struct Placeholder ; end
Base.show(io::IO, p::Placeholder) = print(io, "_")

(::Placeholder)(x) = x

struct PartialApply{Func,Args}
    f::Func
    args::Args
end
Base.show(io::IO, p::PartialApply) = print(io, "$(p.f)($(join(sprint.(show,p.args), ",")))")

struct TightPartialApply{Func,Arg1,Args}
    f::Func
    arg1::Arg1
    args::Args
end
Base.show(io::IO, p::TightPartialApply) = print(io, "$(p.f)($(p.arg1), $(join(sprint.(show,p.args), ",")))")

struct TightPartialApply2{Func,Arg1,Arg2,Args}
    f::Func
    arg1::Arg1
    arg2::Arg2
    args::Args
end
Base.show(io::IO, p::TightPartialApply2) = print(io, "$(p.f)($(p.arg1), $(p.arg2), $(join(sprint.(show,p.args), ",")))")

for T in [PartialApply,TightPartialApply,TightPartialApply2]
    @eval (p::$T)(args...) = fillplaceholders((p,), args)[1][1]
end

#
#   fillplaceholders(tofill, args)
#
# Replaces any `Placeholder`s in the tuple `to_fill` with elements of `args`,
# from left to right. Returns the tuple `(filled,extras)`, where `extras` are
# any remaining elements of `args` which weren't consumed by a placeholder.
#
# When an element of `tofill` is a partially applied function, execute it
# eagerly, consuming elements from `args` and inlining the result in the
# `filled` tuple.
#
fillplaceholders(tofill::Tuple{}, extra) = (),extra
function fillplaceholders(tofill::Tuple{Placeholder,Vararg}, extra)
    inner, extra2 = fillplaceholders(tail(tofill), tail(extra))
    (extra[1], inner...), extra2
end
function fillplaceholders(tofill, extra)
    inner, extra2 = fillplaceholders(tail(tofill), extra)
    (tofill[1], inner...), extra2
end

# Versions for evaluating partial applications
function fillplaceholders(tofill::Tuple{PartialApply,Vararg}, extra)
    pa = tofill[1]
    inner, extra2 = fillplaceholders(pa.args, extra)
    func_result = pa.f(inner...)
    inner2, extra3 = fillplaceholders(tail(tofill), extra2)
    (func_result, inner2...), extra3
end

function fillplaceholders(tofill::Tuple{TightPartialApply,Vararg}, extra)
    pa = tofill[1]
    inner, extra2 = fillplaceholders(pa.args, extra)
    func_result = pa.f(pa.arg1, inner...)
    inner2, extra3 = fillplaceholders(tail(tofill), extra2)
    (func_result, inner2...), extra3
end

function fillplaceholders(tofill::Tuple{TightPartialApply2,Vararg}, extra)
    pa = tofill[1]
    inner, extra2 = fillplaceholders((pa.arg1, pa.args...), extra)
    func_result = pa.f(inner[1], pa.arg2, tail(inner)...)
    inner2, extra3 = fillplaceholders(tail(tofill), extra2)
    (func_result, inner2...), extra3
end

# Bind underscore; loose binding by default
function ubind(f, args...)
    PartialApply(f, args)
end

# Execute partial application, assuming it's fully applied
materialize(a) = a
materialize(p::Union{PartialApply,TightPartialApply,TightPartialApply2}) = p()

#-------------------------------------------------------------------------------
# Lowering
function has_underscores(ex)
    if ex === :_
        return true
    elseif !(ex isa Expr)
        return false
    else
        return any(has_underscores, ex.args)
    end
end

function lower_underscores(ex)
    if ex === :_
        return MagicUnderscores.Placeholder()
    elseif !(ex isa Expr)
        return ex
    elseif has_underscores(ex) && ex.head == :call
        return Expr(:call, MagicUnderscores.ubind, map(lower_underscores, ex.args)...)
    else
        return ex
    end
end

"""
    @_ expression

Transform uses of `_` in `expression` into arguments of a lambda, and evaluate
the resulting expression eagerly.
"""
macro _(ex)
    esc(Expr(:call, MagicUnderscores.materialize, lower_underscores(ex)))
end

"""
    @lazy_ expression

Lazy (unevaluated) version of `@_`.
"""
macro lazy_(ex)
    esc(lower_underscores(ex))
end


#-------------------------------------------------------------------------------
# Override binding behaviour for for some Base functions
for func in [:map, :filter]
    @eval function ubind(::typeof($func), f, args...)
        TightPartialApply($func, f, args)
    end
end

for func in [:|>]
    @eval function ubind(::typeof($func), v, f, args...)
        TightPartialApply2($func, v, f, args)
    end
end

end

