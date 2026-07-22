# bystrotex-etc
A tool for writing HTML with LaTeX formulas

## Installation

### Nix flake

Build both `bystrotex` and `b2l` with:

```sh
nix build .#bystrotex
```

Both executables are installed in `result/bin`. They can also be run directly:

```sh
nix run .#bystrotex -- --help
nix run .#b2l -- --help
```

The flake includes the BystroTeX collection and the Racket `zeromq` package. It
wraps the programs with the native ZeroMQ library path and also supplies
Racket's `scribble` executable for generated documents. Linked user packages
remain available through Racket's normal user collection paths.

To build BystroTeX with exactly the same Racket version as a NixOS system,
call the package expression from that system's package set:

```nix
environment.systemPackages = [
  (pkgs.callPackage /home/andrei/a/git/bystrotex-etc { })
];
```

### Manual Racket installation

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
`~/.config/bystrotex.bib`. Then run both backend services as your ordinary
user. Podman downloads the image from Docker Hub automatically if it is not
already available locally:

```sh
mkdir -p "$HOME/.local/run/bystrotex"
rm -f "$HOME/.local/run/bystrotex/bystrotex.ipc" \
      "$HOME/.local/run/bystrotex/rust-extras.ipc"

podman run --rm \
  --name bystrotex-backend \
  --userns=keep-id \
  --user "$(id -u):$(id -g)" \
  --mount "type=bind,src=$HOME/.local/run/bystrotex,target=/run/bystrotex" \
  --mount "type=bind,src=$HOME/.config/bystrotex.bib,target=/config/bystrotex.bib,ro=true" \
  docker.io/andreimikhailov/bystrotex-backend:latest
```

The Racket clients connect to `bystrotex.ipc` and `rust-extras.ipc` in the
mounted `~/.local/run/bystrotex` directory. The bibliography is mounted
read-only. If it is stored elsewhere, replace
`$HOME/.config/bystrotex.bib` with its absolute path.

On a system with SELinux enabled, the socket-directory mount may need
`relabel=shared`:

```sh
--mount "type=bind,src=$HOME/.local/run/bystrotex,target=/run/bystrotex,relabel=shared"
```

Alternatively, build the image locally from the root of this repository:

```sh
podman build -t localhost/bystrotex-backend:latest .
```

Then use `localhost/bystrotex-backend:latest` instead of the Docker Hub image
in the `podman run` command above. Rebuild the local image after changing the
backend or its dependencies.

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







 
    
