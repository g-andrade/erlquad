

# erlquad #

Copyright (c) 2016 Guilherme Andrade

__Version:__ 1.1.0

__Authors:__ Guilherme Andrade ([`erlquad(at)gandrade(dot)net`](mailto:erlquad(at)gandrade(dot)net)).

`erlquad`: A simple Erlang quadtree implementation
---------

`erlquad` is a straightforward Erlang implementation of [quadtrees](https://en.wikipedia.org/wiki/Quadtree), supporting both bounding-box outlines as well as precise coordinates for small enough objects.

It exposes functions for fetching, folding and any'ing (with boolean predicate) particular areas of interest as well as all contained objects. 'Deeplist' versions of fetching methods are also included for when there's no need to concatenate the final results and thus avoid the overhead of doing so.

```erlang

Object1 = #big_square{ x = 1000, y = 750,  side = 10 },
Object2 = #tiny_circle{ x = 3000, y = 1000 },
Object3 = #tiny_circle{ x = 3000, y = 2000 },

GetOutline = fun (#tiny_circle{ x = X, y = Y }) ->
                    {X, Y};
                 (#big_square{ x = X, y = Y, side = S }) ->
                    {X - S/2, Y - S/2, X + S/2, Y + S/2}
             end,

IsSquare = fun (#tiny_circle{}) -> false;
               (#big_square{})  -> true
           end,

CountCirclesFold = fun (#tiny_circle{}, Acc) -> Acc + 1;
                       (#big_square{}, Acc)  -> Acc
                   end,

Q1 = erlquad:new(0, 0, 4000, 3000, 3), % Left, Bottom, Right, Top, Depth
Q2 = erlquad:objects_add([Object1, Object2, Object3], GetOutline, Q1),

erlquad:area_query(0, 0, 1999, 2999, Q2),       % [#big_square{...}]
erlquad:area_query(2000, 0, 3999, 2999, Q2),    % [#tiny_circle{...}, #tiny_circle{...}]
erlquad:area_query(0, 0, 3999, 2999, Q2),       % [#big_square{...}, #tiny_circle{...}, #tiny_circle{...}]

erlquad:area_query_deep(0, 0, 3999, 2999, Q2),  % [[], [[#big_square{...}, [[], [], ...]], [[[], ...[]]]]]

erlquad:area_query_any(IsSquare, 0, 0, 1999, 1499, Q2),       % true
erlquad:area_query_any(IsSquare, 2000, 1500, 3999, 2999, Q2), % false

erlquad:area_query_fold(CountCirclesFold, 0, 2000, 0, 3999, 2999, Q2), % 2
erlquad:area_query_fold(CountCirclesFold, 0, 2000, 0, 3999, 1499, Q2), % 1
erlquad:area_query_fold(CountCirclesFold, 0, 2000, 0, 3999, 749, Q2),  % 0

erlquad:objects_any(IsSquare, Q2), % true

erlquad:objects_fold(CountCirclesFold, 0, Q2), % 2

erlquad:objects_all(Q2), % [#big_square{...}, #tiny_circle{...}, #tiny_circle{...}]

erlquad:objects_deep_all(Q2), % [[], [[#big_square{...}, [[], [], ...]], [[[], ...[]]]]]

```
Define 'COMPILE_NATIVE_ERLQUAD' (e.g. "rebar compile -DCOMPILE_NATIVE_ERLQUAD") for HiPE compilation.


## Modules ##


<table width="100%" border="0" summary="list of modules">
<tr><td><a href="erlquad.md" class="module">erlquad</a></td></tr></table>

