# erlquad

[![Hex.pm](https://img.shields.io/hexpm/v/erlquad.svg?style=flat)](https://hex.pm/packages/erlquad)
[![CI](https://github.com/g-andrade/erlquad/actions/workflows/ci.yml/badge.svg)](https://github.com/g-andrade/erlquad/actions/workflows/ci.yml)
[![Erlang Versions](https://img.shields.io/badge/Supported%20Erlang%2FOTP-24%20to%2029-blue)](https://www.erlang.org)

`erlquad` is a straightforward Erlang implementation of
[quadtrees](https://en.wikipedia.org/wiki/Quadtree), supporting both
bounding-box outlines as well as precise coordinates for small enough objects.

It exposes functions for fetching, folding and testing (with a boolean
predicate) particular areas of interest as well as all contained objects.
Deep-list versions of the fetching functions are also included for when there's
no need to concatenate the intermediate results.

Buckets have unlimited capacity and depth is fixed on initialization.

Documentation is available on [HexDocs](https://hexdocs.pm/erlquad/).

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

The `area_query*` functions return a conservative superset of the objects within
the queried area: no match is ever omitted, but objects sharing a tree node with
the area may also be returned, so apply your own precise filtering if you need
exact results.

## License

`erlquad` is released under the MIT License. See the [LICENSE](LICENSE) file for
details.

