# bystrotex-etc
A tool for writing HTML with LaTeX formulas

## Installation

Make sure that `~/.local/bin` is in `PATH`

    git clone https://github.com/amkhlv/bystrotex-etc
    cd bystrotex-etc
    
    raco pkg install --link bystroTeX/
    raco pkg install --link truques/
    raco setup
    
    cd bystroTeX
    raco exe bystrotex.rkt
    mv bystrotex ~/.local/bin/
    cd ..

## building example pages

First ensure that your bibliography is available at
`~/.config/bystrotex.bib`. Then build the combined Node and Rust backend
container (this only needs to be repeated after changing the backend or its
dependencies):

    podman build -t localhost/bystrotex-backend:latest .

Then run both backend services as your ordinary user:

    shell-scripts/run-backend-container.sh

The launcher shares only `~/.local/run/bystrotex` with the container, so the
Racket clients connect to `bystrotex.ipc` and `rust-extras.ipc` in that
directory. It also mounts the bibliography read-only. Set `BYSTROTEX_BIB_PATH`
if the bibliography is stored elsewhere.

To run the SVG backend without a container instead, use:

    cd latex-to-svg/
    npm ci
    node index.js

The Rust backend can be run natively from `Rust/BibTeX` with `cargo run`.

Then, in a separate terminal:

    cd examples/bystroTeX_manual
    bystrotex

The output should be in `slides-manual/`. It is a short manual. It is also
[available online](https://amkhlv.github.io/bystrotex-manual/)

## documentation

To open docs in the browser:

    raco docs bystrotex







 
    
