# erlquad

[![Hex.pm](https://img.shields.io/hexpm/v/erlquad.svg?style=flat)](https://hex.pm/packages/erlquad)
[![CI](https://github.com/g-andrade/erlquad/actions/workflows/ci.yml/badge.svg)](https://github.com/g-andrade/erlquad/actions/workflows/ci.yml)
[![Erlang Versions](https://img.shields.io/badge/Supported%20Erlang%2FOTP-24%20to%2029-blue)](https://www.erlang.org)

`erlquad` is a straightforward Erlang implementation of
[quadtrees](https://en.wikipedia.org/wiki/Quadtree): a 2D spatial index that
recursively subdivides a rectangular region into four quadrants, so that objects
can be looked up by location without scanning them all.

It supports both bounding-box outlines and precise coordinates for small enough
objects, and exposes functions for fetching, folding and testing (with a boolean
predicate) either a particular area of interest or the whole tree.

Documentation is available on [HexDocs](https://hexdocs.pm/erlquad/).

## Installation

Add `erlquad` to your `rebar.config` dependencies:

```erlang
{deps, [
    {erlquad, "~> 1.2"}
]}.
```

## Concepts

- A tree covers a fixed rectangle and is subdivided to a **fixed depth**, both
  chosen when you call `new/5`. The tree never grows deeper afterwards; instead,
  each node's bucket has **unlimited capacity**.
- Objects can be **any term**. `erlquad` never inspects them directly — you give
  it functions that read whatever it needs (an outline, a predicate, a fold).
- An object is placed by its **outline**, which is one of:
  - precise **coordinates**, `{X, Y}`; or
  - a **bounding box**, `{Left, Bottom, Right, Top}`.
- An object descends into a quadrant only while it fits entirely inside it; an
  object straddling a node's split lines is kept at that node.
- The `area_query*` functions return a **conservative superset** of the objects
  in the queried area: no match is ever omitted, but objects sharing a node with
  the area may also be returned. Apply your own precise filtering if you need
  exact results.

## Usage

### Representing your objects

The object representation is up to you. This example uses two records, plus a
few little functions that read them — an outline, a predicate, and a fold:

```erlang
-record(big_square, {x :: number(), y :: number(), side :: number()}).
-record(tiny_circle, {x :: number(), y :: number()}).

Objects = [
    #big_square{ x = 1000, y = 750, side = 10 },
    #tiny_circle{ x = 3000, y = 1000 },
    #tiny_circle{ x = 3000, y = 2000 }
],

%% An object's outline: a bounding box for the square, coordinates for a circle.
GetOutline = fun (#tiny_circle{ x = X, y = Y }) ->
                    {X, Y};
                 (#big_square{ x = X, y = Y, side = S }) ->
                    {X - S/2, Y - S/2, X + S/2, Y + S/2}
             end,

IsSquare = fun (#tiny_circle{}) -> false;
               (#big_square{})  -> true
           end,

CountCircles = fun (#tiny_circle{}, N) -> N + 1;
                   (#big_square{}, N)  -> N
               end.
```

### Building and populating a tree

Create an empty tree over a rectangle and a fixed depth, then add the objects:

```erlang
Q0 = erlquad:new(0, 0, 4000, 3000, 3), % Left, Bottom, Right, Top, Depth
Q  = erlquad:objects_add(Objects, GetOutline, Q0).
```

### Fetching every object

```erlang
erlquad:objects_all(Q).
% => [#big_square{...}, #tiny_circle{...}, #tiny_circle{...}]
```

### Querying an area

Pass a `Left, Bottom, Right, Top` rectangle. Remember the result is a
conservative superset (see [Concepts](#concepts)):

```erlang
erlquad:area_query(0, 0, 1999, 2999, Q).    % left half of the world
% => [#big_square{...}]

erlquad:area_query(2000, 0, 3999, 2999, Q). % right half of the world
% => [#tiny_circle{...}, #tiny_circle{...}]
```

### Folding and testing

Instead of materialising a list, fold over the objects or short-circuit with a
predicate — over the whole tree...

```erlang
erlquad:objects_fold(CountCircles, 0, Q). % => 2
erlquad:objects_any(IsSquare, Q).         % => true
```

...or over just an area:

```erlang
erlquad:area_query_fold(CountCircles, 0, 2000, 0, 3999, 1499, Q). % => 1
erlquad:area_query_any(IsSquare, 2000, 1500, 3999, 2999, Q).      % => false
```

### Deep-list variants

Every fetch/query has a `*_deep` counterpart that returns a nested list
mirroring the tree instead of a flat one, skipping the cost of concatenating
intermediate results. Reach for these when a nested list is fine — for instance,
when you are going to fold over the result yourself:

```erlang
erlquad:objects_deep_all(Q).
erlquad:area_query_deep(0, 0, 3999, 2999, Q).
% => nested lists, e.g. [[], [[#big_square{...}, [[], [], ...]], [[[], ...]]]]
```

## API reference

### Building and populating

| Function | Purpose |
|---|---|
| `new/5` | Create an empty tree over a rectangle, subdivided to a fixed depth. |
| `objects_add/3` | Add a list of objects, using an outline function to place each one. |

### Querying the whole tree

| Function | Purpose |
|---|---|
| `objects_all/1` | Every object, as a flat list. |
| `objects_deep_all/1` | Every object, as a nested list mirroring the tree. |
| `objects_fold/3` | Fold a function over every object. |
| `objects_any/2` | Whether a predicate holds for any object. |

### Querying an area

Each takes a `Left, Bottom, Right, Top` rectangle and returns a conservative
superset of the objects within it.

| Function | Purpose |
|---|---|
| `area_query/5` | Candidate objects in the area, as a flat list. |
| `area_query_deep/5` | Candidate objects in the area, as a nested list. |
| `area_query_fold/7` | Fold a function over the candidate objects in the area. |
| `area_query_any/6` | Whether a predicate holds for any candidate object in the area. |

## License

`erlquad` is released under the MIT License. See the [LICENSE](LICENSE) file for
details.
