%% Copyright (c) 2016-2026 Guilherme Andrade
%%
%% Permission is hereby granted, free of charge, to any person obtaining a
%% copy  of this software and associated documentation files (the "Software"),
%% to deal in the Software without restriction, including without limitation
%% the rights to use, copy, modify, merge, publish, distribute, sublicense,
%% and/or sell copies of the Software, and to permit persons to whom the
%% Software is furnished to do so, subject to the following conditions:
%%
%% The above copyright notice and this permission notice shall be included in
%% all copies or substantial portions of the Software.
%%
%% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
%% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
%% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
%% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
%% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
%% FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
%% DEALINGS IN THE SOFTWARE.

-module(erlquad).

-ifdef(E48).
-moduledoc """
A simple Erlang quadtree implementation.

`erlquad` is a straightforward implementation of
[quadtrees](https://en.wikipedia.org/wiki/Quadtree), supporting both
bounding-box outlines and precise coordinates for small enough objects.

It exposes functions for fetching, folding and testing (with a boolean
predicate) particular areas of interest, as well as all contained objects.
Deep-list variants of the fetching functions are also provided for when there
is no need to concatenate the intermediate results.

Buckets have unlimited capacity and depth is fixed on initialization. See the
[README](readme.html) for an overview and examples.
""".
-endif.

-compile([inline, inline_list_funcs]).

%% ------------------------------------------------------------------
%% API Function Exports
%% ------------------------------------------------------------------

-export([
    new/5,
    objects_add/3,
    objects_all/1,
    objects_deep_all/1,
    objects_fold/3,
    objects_any/2,
    area_query/5,
    area_query_deep/5,
    area_query_fold/7,
    area_query_any/6
]).

-ignore_xref([
    new/5,
    objects_add/3,
    objects_all/1,
    objects_deep_all/1,
    objects_fold/3,
    objects_any/2,
    area_query/5,
    area_query_deep/5,
    area_query_fold/7,
    area_query_any/6
]).

%% ------------------------------------------------------------------
%% Macro Definitions
%% ------------------------------------------------------------------

-define(QUADRANT_NONE, 0).
-define(QUADRANT_BOTTOM_LEFT, 1).
-define(QUADRANT_BOTTOM_RIGHT, 2).
-define(QUADRANT_UPPER_LEFT, 3).
-define(QUADRANT_UPPER_RIGHT, 4).

-define(IS_LEAF_NODE(QNode), ((QNode)#erlquad_node.children =:= undefined)).

%% ------------------------------------------------------------------
%% Record Definitions
%% ------------------------------------------------------------------

-record(erlquad_node, {
    split_x :: number(),
    split_y :: number(),
    children :: {erlquad_node(), erlquad_node(), erlquad_node(), erlquad_node()} | undefined,
    bucket = [] :: [term()]
}).
-opaque erlquad_node() :: #erlquad_node{}.
-export_type([erlquad_node/0]).

%% ------------------------------------------------------------------
%% Type Definitions
%% ------------------------------------------------------------------

-type box() :: {Left :: number(), Bottom :: number(), Right :: number(), Top :: number()}.
-export_type([box/0]).

-type coordinates() :: {X :: number(), Y :: number()}.
-export_type([coordinates/0]).

-type outline() :: box() | coordinates().
-export_type([outline/0]).

-type object_outline_fun() :: fun((Object :: term()) -> outline()).
-export_type([object_outline_fun/0]).

-type fold_fun() :: fun((Object :: term(), Acc :: term()) -> NewAcc :: term()).
-export_type([fold_fun/0]).

-type predicate() :: fun((Object :: term()) -> boolean()).
-export_type([predicate/0]).

-type quadrant() ::
    (?QUADRANT_BOTTOM_LEFT
    | ?QUADRANT_BOTTOM_RIGHT
    | ?QUADRANT_UPPER_LEFT
    | ?QUADRANT_UPPER_RIGHT).

%% ------------------------------------------------------------------
%% API Function Definitions
%% ------------------------------------------------------------------

-ifdef(E48).
-doc """
Creates an empty quadtree covering the rectangle delimited by `Left`, `Bottom`,
`Right` and `Top`, recursively subdivided `Depth` levels deep.
""".
-endif.
-spec new(
    Left :: number(),
    Bottom :: number(),
    Right :: number(),
    Top :: number(),
    Depth :: non_neg_integer()
) ->
    erlquad_node().
new(Left, Bottom, Right, Top, Depth) when Depth < 1 ->
    #erlquad_node{
        split_x = range_split(Left, Right),
        split_y = range_split(Bottom, Top)
    };
new(Left, Bottom, Right, Top, Depth) ->
    SplitX = range_split(Left, Right),
    SplitY = range_split(Bottom, Top),
    #erlquad_node{
        split_x = SplitX,
        split_y = SplitY,
        children = {
            new(
                Left,
                Bottom,
                SplitX,
                SplitY,
                % ?QUADRANT_BOTTOM_LEFT
                Depth - 1
            ),
            new(
                SplitX,
                Bottom,
                Right,
                SplitY,
                % ?QUADRANT_BOTTOM_RIGHT
                Depth - 1
            ),
            new(
                Left,
                SplitY,
                SplitX,
                Top,
                % ?QUADRANT_UPPER_LEFT
                Depth - 1
            ),
            new(
                SplitX,
                SplitY,
                Right,
                Top,
                % ?QUADRANT_UPPER_RIGHT
                Depth - 1
            )
        }
    }.

-ifdef(E48).
-doc """
Adds `Objects` to the tree, using `GetOutlineFun` to obtain each object's
outline — either precise `t:coordinates/0` or a bounding `t:box/0`.
""".
-endif.
-spec objects_add(
    Objects :: [term()], GetOutlineFun :: object_outline_fun(), QNode :: erlquad_node()
) ->
    erlquad_node().
objects_add(Objects, GetOutlineFun, QNode) ->
    lists:foldl(
        fun(Object, QNodeAcc) ->
            object_add_with_outline(Object, GetOutlineFun(Object), QNodeAcc)
        end,
        QNode,
        Objects
    ).

-ifdef(E48).
-doc """
Returns every object in the tree as a flat list.
""".
-endif.
-spec objects_all(QNode :: erlquad_node()) -> Objects :: [term()].
objects_all(#erlquad_node{bucket = Bucket} = QNode) when ?IS_LEAF_NODE(QNode) ->
    Bucket;
objects_all(#erlquad_node{bucket = Bucket, children = {C1, C2, C3, C4}}) ->
    Bucket ++
        objects_all(C1) ++
        objects_all(C2) ++
        objects_all(C3) ++
        objects_all(C4).

-ifdef(E48).
-doc """
Like `objects_all/1`, but returns a nested list mirroring the tree structure,
avoiding the cost of concatenating the intermediate results.
""".
-endif.
-spec objects_deep_all(QNode :: erlquad_node()) -> ObjectsDeepList :: [term(), ...].
objects_deep_all(#erlquad_node{bucket = Bucket} = QNode) when ?IS_LEAF_NODE(QNode) ->
    Bucket;
objects_deep_all(#erlquad_node{bucket = Bucket, children = {C1, C2, C3, C4}}) ->
    [
        Bucket,
        objects_deep_all(C1),
        objects_deep_all(C2),
        objects_deep_all(C3),
        objects_deep_all(C4)
    ].

-ifdef(E48).
-doc """
Folds `FoldFun` over every object in the tree, starting from `FoldAcc0`.
""".
-endif.
-spec objects_fold(FoldFun :: fold_fun(), FoldAcc0 :: term(), QNode :: erlquad_node()) ->
    FoldAccN :: term().
objects_fold(
    FoldFun,
    FoldAcc0,
    #erlquad_node{bucket = Bucket} = QNode
) when ?IS_LEAF_NODE(QNode) ->
    lists:foldl(FoldFun, FoldAcc0, Bucket);
objects_fold(
    FoldFun,
    FoldAcc0,
    #erlquad_node{bucket = Bucket, children = {C1, C2, C3, C4}}
) ->
    FoldAcc1 = lists:foldl(FoldFun, FoldAcc0, Bucket),
    FoldAcc2 = objects_fold(FoldFun, FoldAcc1, C1),
    FoldAcc3 = objects_fold(FoldFun, FoldAcc2, C2),
    FoldAcc4 = objects_fold(FoldFun, FoldAcc3, C3),
    objects_fold(FoldFun, FoldAcc4, C4).

-ifdef(E48).
-doc """
Returns `true` if `Predicate` holds for any object in the tree, `false`
otherwise.
""".
-endif.
-spec objects_any(Precicate :: predicate(), QNode :: erlquad_node()) -> boolean().
objects_any(
    Predicate,
    #erlquad_node{bucket = Bucket} = QNode
) when ?IS_LEAF_NODE(QNode) ->
    lists:any(Predicate, Bucket);
objects_any(
    Predicate,
    #erlquad_node{bucket = Bucket, children = {C1, C2, C3, C4}}
) ->
    objects_any(Predicate, C1) orelse
        objects_any(Predicate, C2) orelse
        objects_any(Predicate, C3) orelse
        objects_any(Predicate, C4) orelse
        lists:any(Predicate, Bucket).

-ifdef(E48).
-doc """
Returns the objects that may fall within the rectangle delimited by `Left`,
`Bottom`, `Right` and `Top`.

The result is a conservative superset: no matching object is ever omitted, but
objects sharing a tree node with the queried area may also be included, so
callers that need exact results should apply their own filtering.
""".
-endif.
-spec area_query(
    Left :: number(),
    Bottom :: number(),
    Right :: number(),
    Top :: number(),
    QNode :: erlquad_node()
) ->
    Objects :: [term()].
area_query(_Left, _Bottom, _Right, _Top, QNode) when ?IS_LEAF_NODE(QNode) ->
    QNode#erlquad_node.bucket;
area_query(Left, Bottom, Right, Top, QNode) ->
    #erlquad_node{split_x = SplitX, split_y = SplitY} = QNode,
    LowerQuadrant = splits_quadrant(Left, Bottom, SplitX, SplitY),
    HigherQuadrant = splits_quadrant(Right, Top, SplitX, SplitY),
    case {LowerQuadrant, HigherQuadrant} of
        {Quadrant, Quadrant} ->
            QNode#erlquad_node.bucket ++
                area_query(
                    Left,
                    Bottom,
                    Right,
                    Top,
                    element(Quadrant, QNode#erlquad_node.children)
                );
        {?QUADRANT_BOTTOM_LEFT, ?QUADRANT_UPPER_RIGHT} ->
            objects_all(QNode);
        _ ->
            QNode#erlquad_node.bucket ++
                area_query(
                    Left,
                    Bottom,
                    Right,
                    Top,
                    element(LowerQuadrant, QNode#erlquad_node.children)
                ) ++
                area_query(
                    Left,
                    Bottom,
                    Right,
                    Top,
                    element(HigherQuadrant, QNode#erlquad_node.children)
                )
    end.

-ifdef(E48).
-doc """
Like `area_query/5`, but returns a nested list mirroring the tree structure,
avoiding the cost of concatenating the intermediate results.
""".
-endif.
-spec area_query_deep(
    Left :: number(),
    Bottom :: number(),
    Right :: number(),
    Top :: number(),
    QNode :: erlquad_node()
) ->
    DeepObjectList :: [term(), ...].
area_query_deep(_Left, _Bottom, _Right, _Top, QNode) when ?IS_LEAF_NODE(QNode) ->
    QNode#erlquad_node.bucket;
area_query_deep(Left, Bottom, Right, Top, QNode) ->
    #erlquad_node{split_x = SplitX, split_y = SplitY} = QNode,
    LowerQuadrant = splits_quadrant(Left, Bottom, SplitX, SplitY),
    HigherQuadrant = splits_quadrant(Right, Top, SplitX, SplitY),
    case {LowerQuadrant, HigherQuadrant} of
        {Quadrant, Quadrant} ->
            [
                QNode#erlquad_node.bucket,
                area_query_deep(
                    Left,
                    Bottom,
                    Right,
                    Top,
                    element(Quadrant, QNode#erlquad_node.children)
                )
            ];
        {?QUADRANT_BOTTOM_LEFT, ?QUADRANT_UPPER_RIGHT} ->
            objects_deep_all(QNode);
        _ ->
            [
                QNode#erlquad_node.bucket,
                area_query_deep(
                    Left,
                    Bottom,
                    Right,
                    Top,
                    element(LowerQuadrant, QNode#erlquad_node.children)
                ),
                area_query_deep(
                    Left,
                    Bottom,
                    Right,
                    Top,
                    element(HigherQuadrant, QNode#erlquad_node.children)
                )
            ]
    end.

-ifdef(E48).
-doc """
Folds `FoldFun` over the objects that may fall within the rectangle delimited by
`Left`, `Bottom`, `Right` and `Top`, starting from `FoldAcc0`.

As with `area_query/5`, the visited objects are a conservative superset of those
strictly within the area.
""".
-endif.
-spec area_query_fold(
    FoldFun :: fold_fun(),
    FoldAcc0 :: term(),
    Left :: number(),
    Bottom :: number(),
    Right :: number(),
    Top :: number(),
    QNode :: erlquad_node()
) ->
    FoldAccN :: term().
area_query_fold(FoldFun, FoldAcc0, _Left, _Bottom, _Right, _Top, QNode) when ?IS_LEAF_NODE(QNode) ->
    lists:foldl(FoldFun, FoldAcc0, QNode#erlquad_node.bucket);
area_query_fold(FoldFun, FoldAcc0, Left, Bottom, Right, Top, QNode) ->
    #erlquad_node{split_x = SplitX, split_y = SplitY} = QNode,
    LowerQuadrant = splits_quadrant(Left, Bottom, SplitX, SplitY),
    HigherQuadrant = splits_quadrant(Right, Top, SplitX, SplitY),
    case {LowerQuadrant, HigherQuadrant} of
        {Quadrant, Quadrant} ->
            FoldAcc1 = lists:foldl(FoldFun, FoldAcc0, QNode#erlquad_node.bucket),
            area_query_fold(
                FoldFun,
                FoldAcc1,
                Left,
                Bottom,
                Right,
                Top,
                element(Quadrant, QNode#erlquad_node.children)
            );
        {?QUADRANT_BOTTOM_LEFT, ?QUADRANT_UPPER_RIGHT} ->
            objects_fold(FoldFun, FoldAcc0, QNode);
        _ ->
            FoldAcc1 = lists:foldl(FoldFun, FoldAcc0, QNode#erlquad_node.bucket),
            FoldAcc2 = area_query_fold(
                FoldFun,
                FoldAcc1,
                Left,
                Bottom,
                Right,
                Top,
                element(LowerQuadrant, QNode#erlquad_node.children)
            ),
            area_query_fold(
                FoldFun,
                FoldAcc2,
                Left,
                Bottom,
                Right,
                Top,
                element(HigherQuadrant, QNode#erlquad_node.children)
            )
    end.

-ifdef(E48).
-doc """
Returns `true` if `Predicate` holds for any object that may fall within the
rectangle delimited by `Left`, `Bottom`, `Right` and `Top`, `false` otherwise.

As with `area_query/5`, the tested objects are a conservative superset of those
strictly within the area.
""".
-endif.
-spec area_query_any(
    Predicate :: predicate(),
    Left :: number(),
    Bottom :: number(),
    Right :: number(),
    Top :: number(),
    QNode :: erlquad_node()
) ->
    boolean().
area_query_any(AnyFun, _Left, _Bottom, _Right, _Top, QNode) when ?IS_LEAF_NODE(QNode) ->
    lists:any(AnyFun, QNode#erlquad_node.bucket);
area_query_any(AnyFun, Left, Bottom, Right, Top, QNode) ->
    #erlquad_node{split_x = SplitX, split_y = SplitY} = QNode,
    LowerQuadrant = splits_quadrant(Left, Bottom, SplitX, SplitY),
    HigherQuadrant = splits_quadrant(Right, Top, SplitX, SplitY),
    case {LowerQuadrant, HigherQuadrant} of
        {Quadrant, Quadrant} ->
            area_query_any(
                AnyFun,
                Left,
                Bottom,
                Right,
                Top,
                element(Quadrant, QNode#erlquad_node.children)
            ) orelse
                lists:any(AnyFun, QNode#erlquad_node.bucket);
        {?QUADRANT_BOTTOM_LEFT, ?QUADRANT_UPPER_RIGHT} ->
            objects_any(AnyFun, QNode);
        _ ->
            area_query_any(
                AnyFun,
                Left,
                Bottom,
                Right,
                Top,
                element(LowerQuadrant, QNode#erlquad_node.children)
            ) orelse
                area_query_any(
                    AnyFun,
                    Left,
                    Bottom,
                    Right,
                    Top,
                    element(HigherQuadrant, QNode#erlquad_node.children)
                ) orelse
                lists:any(AnyFun, QNode#erlquad_node.bucket)
    end.

%% ------------------------------------------------------------------
%% Internal Function Definitions
%% ------------------------------------------------------------------

-spec object_add_with_outline(Object :: term(), Outline :: outline(), QNode :: erlquad_node()) ->
    erlquad_node().
object_add_with_outline(Object, Outline, QNode) ->
    case maybe_get_outline_quadrant(Outline, QNode) of
        ?QUADRANT_NONE ->
            Bucket = QNode#erlquad_node.bucket,
            UpdatedBucket = [Object | Bucket],
            QNode#erlquad_node{bucket = UpdatedBucket};
        Quadrant ->
            Children = QNode#erlquad_node.children,
            Child = element(Quadrant, Children),
            UpdatedChild = object_add_with_outline(Object, Outline, Child),
            UpdatedChildren = setelement(Quadrant, Children, UpdatedChild),
            QNode#erlquad_node{children = UpdatedChildren}
    end.

-spec maybe_get_outline_quadrant(outline(), erlquad_node()) -> quadrant() | ?QUADRANT_NONE.
maybe_get_outline_quadrant(_Outline, QNode) when ?IS_LEAF_NODE(QNode) ->
    % Leaf node, we're at the and of the line
    ?QUADRANT_NONE;
maybe_get_outline_quadrant(
    {X, Y},
    #erlquad_node{split_x = SplitX, split_y = SplitY}
) ->
    % Precise coordinates
    splits_quadrant(X, Y, SplitX, SplitY);
maybe_get_outline_quadrant(
    {Left, Bottom, Right, Top},
    #erlquad_node{split_x = SplitX, split_y = SplitY}
) ->
    % Bounding box
    case splits_quadrant(Left, Bottom, SplitX, SplitY) of
        ?QUADRANT_BOTTOM_LEFT = Q ->
            if
                Right >= SplitX ->
                    ?QUADRANT_NONE;
                Top >= SplitY ->
                    ?QUADRANT_NONE;
                true ->
                    Q
            end;
        ?QUADRANT_BOTTOM_RIGHT = Q ->
            if
                Right < SplitX ->
                    ?QUADRANT_NONE;
                Top >= SplitY ->
                    ?QUADRANT_NONE;
                true ->
                    Q
            end;
        ?QUADRANT_UPPER_LEFT = Q ->
            if
                Right >= SplitX ->
                    ?QUADRANT_NONE;
                Top < SplitY ->
                    ?QUADRANT_NONE;
                true ->
                    Q
            end;
        ?QUADRANT_UPPER_RIGHT ->
            ?QUADRANT_UPPER_RIGHT
    end.

-spec splits_quadrant(number(), number(), number(), number()) ->
    quadrant().
splits_quadrant(X, Y, SplitX, SplitY) ->
    if
        X < SplitX ->
            if
                Y < SplitY ->
                    ?QUADRANT_BOTTOM_LEFT;
                true ->
                    ?QUADRANT_UPPER_LEFT
            end;
        Y < SplitY ->
            ?QUADRANT_BOTTOM_RIGHT;
        true ->
            ?QUADRANT_UPPER_RIGHT
    end.

-spec range_split(number(), number()) -> float().
range_split(Min, Max) when Max >= Min ->
    Min + ((Max - Min) / 2).
