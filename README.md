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

First run the server:

    cd latex-to-svg/
    node index.js

Then, in a separate terminal:

    cd examples/bystroTeX_manual
    bystrotex

The output should be in `slides-manual/`. It is a short manual. It is also
[available online](https://amkhlv.github.io/bystrotex-manual/)

## documentation

To open docs in the browser:

    raco docs bystrotex







 
    


