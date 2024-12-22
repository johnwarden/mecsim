# List available recipes in the order in which they appear in this file
_default:
    @just --list --unsorted

instantiate:
    julia --project -e 'using Pkg; Pkg.instantiate()'

sim +args="":
    time julia --project sim.jl {{args}}