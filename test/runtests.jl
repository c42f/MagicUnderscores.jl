using Test

using MagicUnderscores
using MagicUnderscores: lower_underscores

@testset "MagicUnderscores" begin
    @test @_(map(_^2, [1,2])) == [1,4]
    @test @_(map(sqrt(abs(_)) + 1, [-1,2,3])) == sqrt.(abs.([-1,2,3])) .+ 1
    @test @_(map(map(x->x^2, _), [[1,2]])) == [[1,4]]

    @test @_(filter(_>2, [1,2])) == []

    @test @_([1,2] |> length) == 2
    @test @_([1,2,3,4] |> filter(_>2, _)) == [3,4]
    @test @_([1,2,3,4] |> filter(_>2, _) |> length) == 2

    @test @_(map(_.a == 0, [(a=1, b=2), (a=0, b=2)])) == [false, true]
    @test @_(findall(2*_ in (4,6), [1,2,3])) == [2,3]
end
