

# erlzquad #

Copyright (c) 2016 Guilherme Andrade

__Version:__ 1.0.0

__Authors:__ Guilherme Andrade ([`erlzquad(at)gandrade(dot)net`](mailto:erlzquad(at)gandrade(dot)net)).

`erlzquad`: An Erlang quadtree implementation with Z-order curve indexing

---------


### <a name="What_is_it?">What is it?</a> ###


`erlzquad` is an Erlang implementation of [quadtrees](https://en.wikipedia.org/wiki/Quadtree) which makes use of a [Z-order curve](https://en.wikipedia.org/wiki/Z-order_curve) as a way to speed up adding objects in bulk as well as querying arbitrary areas.

* Objects can be anything; a bounding-box -fetching function, which receives an object and returns a 4-tuple `{Left, Bottom, Right, Top}` is therefore a mandatory argument when adding;
* Coordinates are, for now, restricted to non-negative values that start on {0, 0} and may go up to the specified width and height;
* Explicit Z-index calculation code is included for levels up to 8 (inclusive); from that point on we recurse and the whole thing becomes slower than a turtle.

```erlang

Object = #square{id = 'a square', x = 1000, y = 750, side = 10},
GetBox = fun(#square{x = X, y = Y, side = S}) -> {X - S/2, Y - S/2, X + S/2, Y + S/2} end,

Q1 = erlzquad:new_qtree(4000, 3000, 1),
Q2 = erlzquad:add_objects([Object], GetBox, Q1),
Results1 = erlzquad:query_area(0, 0, 2000, 1500, Q2), % 1 result:  [#square{...}]
Results2 = erlzquad:query_area(2000, 1500, 0, 0, Q2).  % 0 results: []

```


### <a name="Concerning_native_compilation_(HiPE)">Concerning native compilation (HiPE)</a> ###

Define 'COMPILE_NATIVE_ERLZQUAD' (e.g. "rebar compile -DCOMPILE_NATIVE_ERLZQUAD") for LOLSPEED™ in case that's your thing.


## Modules ##


<table width="100%" border="0" summary="list of modules">
<tr><td><a href="https://github.com/g-andrade/erlzquad/blob/master/doc/erlzquad.md" class="module">erlzquad</a></td></tr></table>

