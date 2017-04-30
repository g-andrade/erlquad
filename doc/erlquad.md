

# Module erlquad #
* [Data Types](#types)
* [Function Index](#index)
* [Function Details](#functions)

<a name="types"></a>

## Data Types ##




### <a name="type-box">box()</a> ###


<pre><code>
box() = {Left::number(), Bottom::number(), Right::number(), Top::number()}
</code></pre>




### <a name="type-coordinates">coordinates()</a> ###


<pre><code>
coordinates() = {X::number(), Y::number()}
</code></pre>




### <a name="type-erlquad_node">erlquad_node()</a> ###


<pre><code>
erlquad_node() = #erlquad_node{split_x = number(), split_y = number(), children = {<a href="#type-erlquad_node">erlquad_node()</a>, <a href="#type-erlquad_node">erlquad_node()</a>, <a href="#type-erlquad_node">erlquad_node()</a>, <a href="#type-erlquad_node">erlquad_node()</a>} | undefined, bucket = [term()]}
</code></pre>




### <a name="type-fold_fun">fold_fun()</a> ###


<pre><code>
fold_fun() = fun((Object::term(), Acc::term()) -&gt; NewAcc::term())
</code></pre>




### <a name="type-object_outline_fun">object_outline_fun()</a> ###


<pre><code>
object_outline_fun() = fun((Object::term()) -&gt; <a href="#type-outline">outline()</a>)
</code></pre>




### <a name="type-outline">outline()</a> ###


<pre><code>
outline() = <a href="#type-box">box()</a> | <a href="#type-coordinates">coordinates()</a>
</code></pre>




### <a name="type-predicate">predicate()</a> ###


<pre><code>
predicate() = fun((Object::term()) -&gt; boolean())
</code></pre>

<a name="index"></a>

## Function Index ##


<table width="100%" border="1" cellspacing="0" cellpadding="2" summary="function index"><tr><td valign="top"><a href="#area_query-5">area_query/5</a></td><td></td></tr><tr><td valign="top"><a href="#area_query_any-6">area_query_any/6</a></td><td></td></tr><tr><td valign="top"><a href="#area_query_deep-5">area_query_deep/5</a></td><td></td></tr><tr><td valign="top"><a href="#area_query_fold-7">area_query_fold/7</a></td><td></td></tr><tr><td valign="top"><a href="#new-5">new/5</a></td><td></td></tr><tr><td valign="top"><a href="#objects_add-3">objects_add/3</a></td><td></td></tr><tr><td valign="top"><a href="#objects_all-1">objects_all/1</a></td><td></td></tr><tr><td valign="top"><a href="#objects_any-2">objects_any/2</a></td><td></td></tr><tr><td valign="top"><a href="#objects_deep_all-1">objects_deep_all/1</a></td><td></td></tr><tr><td valign="top"><a href="#objects_fold-3">objects_fold/3</a></td><td></td></tr></table>


<a name="functions"></a>

## Function Details ##

<a name="area_query-5"></a>

### area_query/5 ###

<pre><code>
area_query(Left::number(), Bottom::number(), Right::number(), Top::number(), QNode::<a href="#type-erlquad_node">erlquad_node()</a>) -&gt; Objects::[term()]
</code></pre>
<br />

<a name="area_query_any-6"></a>

### area_query_any/6 ###

<pre><code>
area_query_any(Predicate::<a href="#type-predicate">predicate()</a>, Left::number(), Bottom::number(), Right::number(), Top::number(), QNode::<a href="#type-erlquad_node">erlquad_node()</a>) -&gt; boolean()
</code></pre>
<br />

<a name="area_query_deep-5"></a>

### area_query_deep/5 ###

<pre><code>
area_query_deep(Left::number(), Bottom::number(), Right::number(), Top::number(), QNode::<a href="#type-erlquad_node">erlquad_node()</a>) -&gt; DeepObjectList::[term(), ...]
</code></pre>
<br />

<a name="area_query_fold-7"></a>

### area_query_fold/7 ###

<pre><code>
area_query_fold(FoldFun::<a href="#type-fold_fun">fold_fun()</a>, FoldAcc0::term(), Left::number(), Bottom::number(), Right::number(), Top::number(), QNode::<a href="#type-erlquad_node">erlquad_node()</a>) -&gt; FoldAccN::term()
</code></pre>
<br />

<a name="new-5"></a>

### new/5 ###

<pre><code>
new(Left::number(), Bottom::number(), Right::number(), Top::number(), Depth::non_neg_integer()) -&gt; <a href="#type-erlquad_node">erlquad_node()</a>
</code></pre>
<br />

<a name="objects_add-3"></a>

### objects_add/3 ###

<pre><code>
objects_add(Objects::[term()], GetOutlineFun::<a href="#type-object_outline_fun">object_outline_fun()</a>, QNode::<a href="#type-erlquad_node">erlquad_node()</a>) -&gt; <a href="#type-erlquad_node">erlquad_node()</a>
</code></pre>
<br />

<a name="objects_all-1"></a>

### objects_all/1 ###

<pre><code>
objects_all(QNode::<a href="#type-erlquad_node">erlquad_node()</a>) -&gt; Objects::[term()]
</code></pre>
<br />

<a name="objects_any-2"></a>

### objects_any/2 ###

<pre><code>
objects_any(Precicate::<a href="#type-predicate">predicate()</a>, QNode::<a href="#type-erlquad_node">erlquad_node()</a>) -&gt; boolean()
</code></pre>
<br />

<a name="objects_deep_all-1"></a>

### objects_deep_all/1 ###

<pre><code>
objects_deep_all(QNode::<a href="#type-erlquad_node">erlquad_node()</a>) -&gt; ObjectsDeepList::[term(), ...]
</code></pre>
<br />

<a name="objects_fold-3"></a>

### objects_fold/3 ###

<pre><code>
objects_fold(FoldFun::<a href="#type-fold_fun">fold_fun()</a>, FoldAcc0::term(), QNode::<a href="#type-erlquad_node">erlquad_node()</a>) -&gt; FoldAccN::term()
</code></pre>
<br />

