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

-module(erlquad_SUITE).

-include_lib("common_test/include/ct.hrl").
-include_lib("stdlib/include/assert.hrl").

-export([all/0]).

-export([
    empty_tree/1,
    leaf_tree/1,
    readme_example/1,
    insert_roundtrip/1,
    deep_matches_flat/1,
    fold_and_any_consistency/1,
    area_query_full_box/1,
    area_query_is_subset/1,
    area_query_variants_consistency/1,
    spatial_locality/1
]).

%% Records mirroring the README example.
-record(big_square, {x, y, side}).
-record(tiny_circle, {x, y}).

%% ------------------------------------------------------------------
%% Enumeration
%% ------------------------------------------------------------------

all() ->
    [
        empty_tree,
        leaf_tree,
        readme_example,
        insert_roundtrip,
        deep_matches_flat,
        fold_and_any_consistency,
        area_query_full_box,
        area_query_is_subset,
        area_query_variants_consistency,
        spatial_locality
    ].

%% ------------------------------------------------------------------
%% Test cases
%% ------------------------------------------------------------------

empty_tree(_Config) ->
    Q = erlquad:new(0, 0, 1000, 1000, 3),
    ?assertEqual([], erlquad:objects_all(Q)),
    ?assertEqual([], lists:flatten(erlquad:objects_deep_all(Q))),
    ?assertEqual(0, erlquad:objects_fold(fun(_, Acc) -> Acc + 1 end, 0, Q)),
    ?assertNot(erlquad:objects_any(fun(_) -> true end, Q)),
    ?assertEqual([], erlquad:area_query(0, 0, 1000, 1000, Q)),
    ?assertEqual([], lists:flatten(erlquad:area_query_deep(0, 0, 1000, 1000, Q))),
    ?assertNot(erlquad:area_query_any(fun(_) -> true end, 0, 0, 1000, 1000, Q)).

leaf_tree(_Config) ->
    %% Depth < 1 builds a single leaf node: every object lands in its bucket.
    Q0 = erlquad:new(0, 0, 1000, 1000, 0),
    Objects = [{point, 10, 10}, {point, 900, 900}, {box, 100, 100, 200, 200}],
    Q1 = erlquad:objects_add(Objects, fun outline/1, Q0),
    ?assert(same_multiset(Objects, erlquad:objects_all(Q1))),
    %% A leaf ignores the query box and returns its whole bucket.
    ?assert(same_multiset(Objects, erlquad:area_query(0, 0, 1, 1, Q1))).

readme_example(_Config) ->
    Object1 = #big_square{x = 1000, y = 750, side = 10},
    Object2 = #tiny_circle{x = 3000, y = 1000},
    Object3 = #tiny_circle{x = 3000, y = 2000},
    GetOutline =
        fun
            (#tiny_circle{x = X, y = Y}) ->
                {X, Y};
            (#big_square{x = X, y = Y, side = S}) ->
                {X - S / 2, Y - S / 2, X + S / 2, Y + S / 2}
        end,
    IsSquare =
        fun
            (#tiny_circle{}) -> false;
            (#big_square{}) -> true
        end,
    CountCircles =
        fun
            (#tiny_circle{}, Acc) -> Acc + 1;
            (#big_square{}, Acc) -> Acc
        end,
    Objects = [Object1, Object2, Object3],
    Q1 = erlquad:new(0, 0, 4000, 3000, 3),
    Q2 = erlquad:objects_add(Objects, GetOutline, Q1),

    %% Every inserted object is retrievable.
    ?assert(same_multiset(Objects, erlquad:objects_all(Q2))),
    %% Querying the whole world returns everything.
    ?assert(same_multiset(Objects, erlquad:area_query(0, 0, 4000, 3000, Q2))),
    %% Fold/any over the whole tree.
    ?assertEqual(2, erlquad:objects_fold(CountCircles, 0, Q2)),
    ?assert(erlquad:objects_any(IsSquare, Q2)),
    %% The left half holds the square but neither circle.
    LeftHalf = erlquad:area_query(0, 0, 1999, 2999, Q2),
    ?assert(lists:member(Object1, LeftHalf)),
    ?assertNot(lists:member(Object2, LeftHalf)),
    ?assertNot(lists:member(Object3, LeftHalf)).

insert_roundtrip(_Config) ->
    seed(),
    lists:foreach(
        fun(_) ->
            {Q, Objects} = random_tree(),
            %% Nothing is lost or duplicated on the way in and back out.
            ?assert(same_multiset(Objects, erlquad:objects_all(Q)))
        end,
        lists:seq(1, 50)
    ).

deep_matches_flat(_Config) ->
    seed(),
    lists:foreach(
        fun(_) ->
            {Q, _Objects} = random_tree(),
            ?assert(
                same_multiset(
                    erlquad:objects_all(Q),
                    lists:flatten(erlquad:objects_deep_all(Q))
                )
            ),
            {L, B, R, T} = random_box(),
            ?assert(
                same_multiset(
                    erlquad:area_query(L, B, R, T, Q),
                    lists:flatten(erlquad:area_query_deep(L, B, R, T, Q))
                )
            )
        end,
        lists:seq(1, 50)
    ).

fold_and_any_consistency(_Config) ->
    seed(),
    IsBox = fun(Obj) -> element(1, Obj) =:= box end,
    Collect = fun(Obj, Acc) -> [Obj | Acc] end,
    lists:foreach(
        fun(_) ->
            {Q, _Objects} = random_tree(),
            All = erlquad:objects_all(Q),
            %% fold visits exactly the objects objects_all reports.
            ?assert(same_multiset(All, erlquad:objects_fold(Collect, [], Q))),
            %% any agrees with a plain lists:any over the same objects.
            ?assertEqual(
                lists:any(IsBox, All),
                erlquad:objects_any(IsBox, Q)
            )
        end,
        lists:seq(1, 50)
    ).

area_query_full_box(_Config) ->
    seed(),
    lists:foreach(
        fun(_) ->
            {Q, Objects} = random_tree(),
            %% Querying the exact root bounds must return every object.
            {L, B, R, T} = world(),
            ?assert(same_multiset(Objects, erlquad:area_query(L, B, R, T, Q)))
        end,
        lists:seq(1, 50)
    ).

area_query_is_subset(_Config) ->
    seed(),
    lists:foreach(
        fun(_) ->
            {Q, _Objects} = random_tree(),
            {L, B, R, T} = random_box(),
            All = erlquad:objects_all(Q),
            Queried = erlquad:area_query(L, B, R, T, Q),
            %% A query never invents objects that were not inserted.
            ?assert(is_sub_multiset(Queried, All))
        end,
        lists:seq(1, 100)
    ).

area_query_variants_consistency(_Config) ->
    seed(),
    IsBox = fun(Obj) -> element(1, Obj) =:= box end,
    Collect = fun(Obj, Acc) -> [Obj | Acc] end,
    lists:foreach(
        fun(_) ->
            {Q, _Objects} = random_tree(),
            {L, B, R, T} = random_box(),
            Queried = erlquad:area_query(L, B, R, T, Q),
            ?assert(same_multiset(Queried, erlquad:area_query_fold(Collect, [], L, B, R, T, Q))),
            ?assertEqual(
                lists:any(IsBox, Queried),
                erlquad:area_query_any(IsBox, L, B, R, T, Q)
            )
        end,
        lists:seq(1, 50)
    ).

spatial_locality(_Config) ->
    %% Two points in opposite corners: a tight query around one must find it and
    %% exclude the other (they live in disjoint top-level quadrants).
    Q0 = erlquad:new(0, 0, 1000, 1000, 4),
    P1 = {point, 100, 100},
    P2 = {point, 900, 900},
    Q = erlquad:objects_add([P1, P2], fun outline/1, Q0),

    BottomLeft = erlquad:area_query(50, 50, 150, 150, Q),
    ?assert(lists:member(P1, BottomLeft)),
    ?assertNot(lists:member(P2, BottomLeft)),

    TopRight = erlquad:area_query(850, 850, 950, 950, Q),
    ?assert(lists:member(P2, TopRight)),
    ?assertNot(lists:member(P1, TopRight)).

%% ------------------------------------------------------------------
%% Helpers
%% ------------------------------------------------------------------

%% Outline function for the tagged tuples used by the randomised cases.
outline({point, X, Y}) -> {X, Y};
outline({box, L, B, R, T}) -> {L, B, R, T}.

world() -> {0, 0, 1000, 1000}.

random_tree() ->
    {L, B, R, T} = world(),
    Q0 = erlquad:new(L, B, R, T, 4),
    Objects = [random_object() || _ <- lists:seq(1, 40)],
    {erlquad:objects_add(Objects, fun outline/1, Q0), Objects}.

random_object() ->
    case rand:uniform(2) of
        1 ->
            {point, rand:uniform(1000), rand:uniform(1000)};
        2 ->
            L = rand:uniform(900),
            B = rand:uniform(900),
            {box, L, B, L + rand:uniform(100), B + rand:uniform(100)}
    end.

random_box() ->
    L = rand:uniform(1000),
    B = rand:uniform(1000),
    {L, B, L + rand:uniform(500), B + rand:uniform(500)}.

%% Deterministic seed so failures reproduce.
seed() ->
    _ = rand:seed(exsss, {1, 2, 3}),
    ok.

same_multiset(A, B) ->
    lists:sort(A) =:= lists:sort(B).

%% Every element of Sub (with multiplicity) appears in Super.
is_sub_multiset(Sub, Super) ->
    same_multiset(Super, Sub ++ (Super -- Sub)).
