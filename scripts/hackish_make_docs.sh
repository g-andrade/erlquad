#!/usr/bin/env bash

# sigh.....
rebar3 as generate_documentation compile
mkdir -p _build/generate_documentation/lib/erlquad/doc/
cp -p overview.edoc _build/generate_documentation/lib/erlquad/doc/
erl -pa _build/generate_documentation/lib/*/ebin -noshell -run edoc_run application "erlquad"
erl -pa _build/generate_documentation/lib/*/ebin -noshell -run edoc_run application "erlquad" '[{doclet, edown_doclet}, {top_level_readme, {"README.md", "https://github.com/g-andrade/erlquad", "master"}}]'
rm -rf doc
mv _build/generate_documentation/lib/erlquad/doc ./
sed -i -e 's/^\(---------\)$/\n\1/g' README.md
