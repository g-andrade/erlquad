# erlquad

Erlang/OTP library implementing a [quadtree](https://en.wikipedia.org/wiki/Quadtree):
a 2D spatial index that recursively subdivides a rectangular region into four
quadrants. Objects are placed by their outline — either precise coordinates
(`{X, Y}`) or a bounding box (`{Left, Bottom, Right, Top}`) — and can be
fetched, folded or tested (with a boolean predicate) over a queried area or over
the whole tree. It is a pure functional data structure: no processes, no
supervision tree, no application callback module.

## Build, test, check

```bash
make compile         # rebar3 compile
make test            # eunit + CT + coverage
make check           # check-fast + check-slow
make check-fast      # format check (erlfmt) + xref + dead code (hank) + lint (elvis)
make check-slow      # dialyzer
make format          # auto-format sources with erlfmt
make eunit           # unit tests only
make ct              # common_test suite + coverage
make dialyzer        # type analysis
make doc             # download ex_doc escript -> tmp/, render EEP-48 docs to doc/
make shell           # rebar3 shell with the app loaded
```

All checks run sequentially (`.NOTPARALLEL`). CI runs `make check-fast`,
`make test` and `make check-slow` on OTP 24-29 (ubuntu-22.04).

## Compiler flags

`warn_export_vars`, `warn_missing_spec`, `warn_unused_import` and
`warnings_as_errors` are always on — every exported function needs a `-spec`.
The `test` and `shell` profiles relax `warn_missing_spec`/`warnings_as_errors`.

## Architecture

Everything lives in the single module `erlquad` (`src/erlquad.erl`).

- A tree is a nest of `#erlquad_node{}` records. Each node stores its split
  point (`split_x`, `split_y`), a `bucket` of objects that straddle those
  splits (and therefore cannot descend further), and either `undefined`
  children (a leaf) or a `{BottomLeft, BottomRight, UpperLeft, UpperRight}`
  tuple of child nodes. The four quadrants are addressed by the
  `?QUADRANT_*` macros (1..4), matching `element/2` positions in that tuple.
- `new/5` builds the full, empty tree to a fixed `Depth`; buckets have
  unlimited capacity but depth never grows after construction.
- `objects_add/3` pushes each object as deep as it fits: a point descends to a
  leaf; a bounding box stops at the shallowest node whose splits it crosses
  (`maybe_get_outline_quadrant/2`).
- The `area_query*` functions descend only into quadrants overlapping the query
  rectangle and return the buckets found along the way. The result is a
  **conservative superset**: it never omits a matching object but may include
  others sharing a node, so callers do their own precise filtering.
- The `erlquad_node/0` type is **opaque** — it is the handle callers pass
  around and should not be inspected from outside the module.

### Key modules

| Module | Role |
|---|---|
| `erlquad` | The whole public API and the tree implementation |

## Code conventions

- Code is formatted with `erlfmt`; run `make format` before committing. The
  bulk reformat commit is listed in `.git-blame-ignore-revs`.
- Documentation is **EEP-48 native**: `-moduledoc`/`-doc` attributes, each
  guarded by `-ifdef(E48). ... -endif.` (the `E48` macro is defined only on
  OTP 27+ via `rebar.config`). `make doc` runs `rebar3 edoc` (using the
  top-level `edoc_opts` chunk doclet, which writes to
  `_build/docs/lib/erlquad/`) and renders the chunks with the ex_doc escript.
  Every exported function is public API, so nothing is hidden — but if a
  private module or function is ever added, hide it with `-moduledoc false` /
  `-doc false`, **not** legacy `%% @private` comments, which ex_doc does not
  honor. There are no `@private` tags in `src/`.
- Lint exceptions live in `elvis.config` and are documented inline: for
  `src/`, `no_if_expression` and `dont_repeat_yourself` are disabled (`if` is
  the clearest form for the numeric quadrant/split comparisons, and the four
  `area_query/*` variants intentionally share a traversal skeleton, kept as
  separate inlined functions for performance); test rules `no_debug_call` and
  `dont_repeat_yourself` are relaxed.

## Tests

`test/erlquad_SUITE.erl` is the single Common Test suite. Alongside
deterministic cases (empty/leaf trees, the README example, spatial locality) it
checks randomised invariants over generated trees: insert/retrieve round-trip,
deep-list vs flat equivalence, fold/any consistency with `objects_all`, full-box
query completeness, the query subset property, and agreement between the
`area_query` fold/any/deep variants. The randomised cases seed `rand`
deterministically so failures reproduce.

## OTP version support

Supported OTP 24-29 (declared `minimum_otp_vsn` is lower, but 24+ is what's
tested). `rebar.config.script` removes the `erlfmt`, `rebar3_hank` and
`rebar3_lint` plugins on OTP ≤ 25 (incompatible there), removes `erlfmt` on
OTP ≤ 26 (its parser chokes on `-doc` triple-quoted strings), and works around
`rebar3_hank` on OTP 29.

## Releasing

`make publish` runs `rebar3 hex publish --doc-dir=doc` (builds docs first).
Versioning follows SemVer; history is in `CHANGELOG.md` (Keep a Changelog).
