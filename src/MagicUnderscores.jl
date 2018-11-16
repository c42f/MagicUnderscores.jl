module MagicUnderscores

export @_



import Base: tail

struct Placeholder ; end
Base.show(io::IO, p::Placeholder) = print(io, "_")

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


materialize(partial::Tuple{}, extra) = (),extra
function materialize(partial::Tuple{Placeholder,Vararg}, extra)
    inner, extra2 = materialize(tail(partial), tail(extra))
    (extra[1], inner...), extra2
end
function materialize(partial::Tuple{PartialApply,Vararg}, extra)
    pa = partial[1]
    inner, extra2 = materialize(pa.args, extra)
    func_result = pa.f(inner...)
    inner2, extra3 = materialize(tail(partial), extra2)
    (func_result, inner2...), extra3
end
function materialize(partial::Tuple{TightPartialApply,Vararg}, extra)
    pa = partial[1]
    inner, extra2 = materialize(pa.args, extra)
    func_result = pa.f(pa.arg1, inner...)
    inner2, extra3 = materialize(tail(partial), extra2)
    (func_result, inner2...), extra3
end
function materialize(partial, extra)
    inner, extra2 = materialize(tail(partial), extra)
    (partial[1], inner...), extra2
end

function (p::PartialApply)(args...)
    p.f(materialize(p.args, args)[1]...)
end

function (p::TightPartialApply)(args...)
    p.f(p.arg1, materialize(p.args, args)[1]...)
end

(::Placeholder)(x) = x

function ubind(f, args...)
    PartialApply(f, args)
end

function ubind(::typeof(map), f, args...)
    # FIXME this only works for one argument...
    TightPartialApply(map, f, args)
end

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

macro _(ex)
    esc(Expr(:call, lower_underscores(ex)))
end


end

