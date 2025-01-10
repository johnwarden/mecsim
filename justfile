# List available recipes in the order in which they appear in this file
_default:
    @just --list --unsorted

instantiate:
    julia --project -e 'using Pkg; Pkg.instantiate()'

sim +args="":
    time julia --project Main.jl {{args}}

commit-output:
    cp -r output/local/* output/
    git add output
    git commit -m "Update output"