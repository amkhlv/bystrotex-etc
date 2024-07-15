#lang scribble/base
@(require racket scribble/core scribble/base scribble/html-properties)
@(require "defs.rkt" bystroTeX/common bystroTeX/slides (for-syntax bystroTeX/slides_for-syntax))
@; ---------------------------------------------------------------------------------------------------
@; User definitions:
@(bystro-set-css-dir (build-path 'up 'up "profiles" "writeup"))

@; This controls the single page mode:
@(define singlepage-mode #f)
@(bystro-def-formula "formula-enormula-humongula!")

@; AND HOPEFULLY SOME CONTENT:

@title{BystroTeX}

Mathematical slides
using the @hyperlink["http://docs.racket-lang.org/scribble/"]{@tt{scribble}} markup system

Andrei Mikhailov, IFT UNESP

@bystro-toc[]

@page["Inserting mathematical formulas into html slides" #:tag "MathFormulasInSlides" #:showtitle #t]

We can insert @f{W(\phi)} as an inline formula, or a display formula:
@e[#:label "Lagrangian"]{
{\cal L} = \left(\partial_{\mu}\phi,\partial^{\mu}\phi\right) - 
\left|\left| {\partial W(\phi)\over \partial\phi} \right|\right|^2
}
Or, formula in the box:
@longtbl[#:styless @'(((center) (right))) 
@list[@list[@nested[@redbox["padding:36px;8px;0px;8px;"]{
@f{{\partial\phi\over\partial\sigma} = - {\partial W\over \partial \phi}} 
}] @nested{@label{SolitonEquation}}]]]
If we need, we can also insert @f-4{x^2} shifted down, 
or insert a shifted up and rescaled: @f+3+8{y^2}. @smaller{
@fsize+[-5]
We can also temporarily change the default size of the formulas. For example, this paragraph is
typeset using small font. The formula @f{yx^2} comes out smaller because we changed the default size.
After we restore the default size
@fsize=[]
@f{zx^2} is of the normal size. Some people like colored formulas: 
@bystro-bg[255 200 200] @bystro-fg[0 0 250]
@f{\; l^2 = a^2 + b^2}
@bystro-bg[255 255 255] @bystro-fg[0 0 0]
}

See the @seclink["Syntax"]{syntax part} for more examples.  
}


@tabular[@list[@list[@para{
Besides the math-specific task of inserting formulas, many things can be done using
the @hyperlink["http://docs.racket-lang.org/scribble/"]{well documented} @tt{scribble} environment.
@linebreak[]
For example, one can include pictures, as illustrated. Flying kite could be an allegory for slide presentations.}
@smaller-2{@(image (string->path "snapshots/kite.png") #:scale 0.5)
@hyperlink["http://openclipart.org/detail/67597/child-with-a-kite-by-laobc"]{openclipart.org}}]]]






@page["Jumping to references" #:tag "JumpingReferences" #:showtitle #t]
Remember the formula (@ref{Lagrangian})? Clicking on
(@ref{Lagrangian}) brings you to that formula.

It is also possible to jump to a particular slide, for example 
@seclink["Installation"]{jump to ``Installation''}.

Sometimes you might want to press the ``up'' link, which will bring you to the title page.
The title page has the list of contents, so you can jump to particular slides from there.


@page["Installation and running" #:tag "Installation" #:showtitle #t]

BystroTeX consists of the frontend (Racket) and backend (Node.js) communicating via a ZeroMQ socket.

@subpage[1 "Installation" #:tag "sec:Building"]

After installing @hyperlink["https://racket-lang.org/"]{Racket} and
@hyperlink["https://nodejs.org"]{Node.js}, do:

@verb|{
       git clone https://github.com/amkhlv/bystrotex-etc
       cd bystrotex-etc
       
       raco pkg install yaml
       raco pkg install zeromq
       raco pkg install --link bystroTeX/
       raco pkg install --link truques/
       cd bystroTeX
       raco exe bystrotex.rkt
       mv bystrotex ~/.local/bin/
       cd ..

       }|

@subpage[1 "Running" #:tag "sec:Running"]

First run the server:

@verb|{
    cd latex-to-svg/
    npm i
    node index,js
    }|

Then, in a separate terminal:

@verb|{
       cd examples/bystroTeX_manual
       bystrotex
       }|

The output should be in @tt{slides-manual/}


@page["Basic syntax" #:tag "Syntax" #:showtitle #t]
You might want to read @hyperlink["http://docs.racket-lang.org/scribble/reader.html"]{basic Scribble documentation},
But it should not be necessary, because the syntax should be clear from the source file of these pages. 
More examples can be found @hyperlink["https://github.com/amkhlv/BV"]{here}.

@bystro-local-toc[]

@subpage[1 @elem{Simple formulas} #:tag "sec:SimpleFormulas"]

To insert formula @f{x^2/y^2}, type:
@verb|{@f{x^2/y^2}}|
Curly brackets inside are usually not a problem: for @f{y_{ij}} just type 
@verb|{@f{y_{ij}}}|
it works. If however something goes wrong, you might want to use better protection:
@verb|---{@f|{y_{ij}}| or even @f|-{y_{ij}}-| }---|

@div[comment]{Whether you need to use @tt|{@f|-{...}-|}|, or @tt|{@f{...}}| is enough, depends on 
the structure of parentheses inside your formula. @bold{If parentheses are well-balanced} then
@tt|{@f{...}}| is enough. If not, then better protection is needed. For example, if the formula
is: @f-4|{v = \left\{\begin{array}{l} u \mbox{ if } u \geq 0 \cr -u \mbox{ if } u < 0\end{array}\right.}|,
then you absolutely need to use @tt|{@f|-{...}-|}|, since the @f|{\{}| is unbalanced}

There is also the display-style @tt|--{@e{...}}--| which allows formula labeling using
@tt|--{@e[#:tag "FormulaName"]{...}}--|.


It is also possible to manually align the formulas, for example 
@tt|--{@f+4{x^2}}--| produces @f+4{x^2} and @tt|--{@f-7{x^2}}--| gives @f-7{x^2}.
There is also zoomed @tt|--{@f+0+7{x^2}}--| which gives @f+0+7{x^2} and zoom
with align @tt|--{@f-5+7{x^2}}--| which gives @f-5+7{x^2}.

The command @tt|--{@fsize[20]}--| changes the formula size to 20pt, the command @tt|--{@fsize[]}--|
or equivalently @tt|--{@fsize=[]}--|
returns back to the previous size (but you can not nest them, there is not stack of sizes).
Actually I recommend to use instead the command @tt|--{@fsize+[5]}--| which changes the
size relatively to the base size. This  will scale better if you will have to suddenly
@seclink["FitProjector"]{change the resolution} 3 minutes before your talk. 
To decrease the size, use @tt|--{@fsize+[@-[5]]}--| or equivalently  @tt|--{@(fsize+ (- 5))}--|.
Both @tt|{@fsize[]}| and @tt|{@fsize+[]}| have an optional second argument, which modifies
the vertical base alignment.


@subpage[1 @elem{Multiline formulas} #:tag "sec:MultilineFormulas"]

Example:
@verb|{
@align[r.l
 @list[
@f{{2\over 1 - x^2} = }  @f{1+x+x^2 + \ldots +}
]@list[
"" @f{1-x+x^2- \ldots}
]
]
}|
produces:
@align[r.l
 @list[
@f{{2\over 1 - x^2} = }  @f{1+x+x^2 + \ldots +}
]@list[
"" @f{1-x+x^2- \ldots}
]
]
The only problem is, there is a small alignment defect. To fix it, do this:
@verb|{
@align[r.l
 @list[
@f{{2\over 1 - x^2} = }  @v+[3 @f{1+x+x^2 + \ldots +}]
]@list[
"" @f{1-x+x^2- \ldots}
]
]
}|
@align[r.l
 @list[
@f{{2\over 1 - x^2} = }  @v+[3 @f{1+x+x^2 + \ldots +}]
]@list[
"" @f{1-x+x^2- \ldots}
]
]
Notice that in the first line stands the symbol "r.l" which defines the alignment (right, then left). The "v+" is a padding, 
it serves for vertical adjustment, see the 
@hyperlink["http://planet.racket-lang.org/package-source/amkhlv/bystroTeX.plt/6/3/planet-docs/manual/index.html"]{manual page}.

The numbered version of the same formula will be
@verb|{
@align[r.l.n
 @list[
@f{{2\over 1 - x^2} = }  @v+[3 @f{1+x+x^2 + \ldots +}] ""
]@list[
"" @f{1-x+x^2- \ldots} @label{SumOfGeometricProgressions}
]
]
}|
@align[r.l.n
 @list[
@f{{2\over 1 - x^2} = }  @v+[3 @f{1+x+x^2 + \ldots +}] ""
]@list[
"" @f{1-x+x^2- \ldots} @label{SumOfGeometricProgressions}
]
]
Notice that the alignment symbol is now r.l.n, we added letter n for the number. The function @tt|{@label[]}| is defined in the slides’ header.

@subpage[1 @elem{Fun with Unicode} #:tag "sec:FunWithUnicode"]

To get @f{A\otimes B} just type: @tt|{@f{A⊗B}}|. In other words, we can use the Unicode symbol ⊗ instead of @tt{\otimes} in formulas.


@page["Writing html in scribble" #:tag "InsertingHTML" #:showtitle #t]

This @tt{HTML}:
@(tg img 
     #:attrs ([style "border:0;"]
              [src "http://www.123gifs.eu/free-gifs/flags/flagge-0544.gif"]
              [alt "flagge-0544.gif from 123gifs.eu"])
     "Flag of Brazil")

@verb[#:style @(make-style "comment" '())]|{
<img style="border:0;" src="http://www.123gifs.eu/free-gifs/flags/flagge-0544.gif" alt="flagge-0544.gif from 123gifs.eu">
Flag of Brazil
</img>
}|
should be inserted @hyperlink["http://docs.racket-lang.org/manual@bystroTeX/index.html#%28form._%28%28lib._bystro.Te.X%2Fcommon..rkt%29._tg%29%29"]{as follows}:
@verb[#:style @(make-style "comment" '())]|--{
@(tg img 
     #:attrs ([style "border:0;"]
              [src "http://www.123gifs.eu/free-gifs/flags/flagge-0544.gif"]
              [alt "flagge-0544.gif from 123gifs.eu"])
     "Flag of Brazil")

}--|



@page["Emacs" #:tag "Emacs" #:showtitle #t]

@bystro-local-toc[]

@subpage[1 @elem{Racket mode} #:tag "sec:EmacsRacketMode"]

I use @hyperlink["https://github.com/greghendershott/racket-mode"]{racket-mode}.

I find it useful to disable smart bracket completion, because it does not play well
with typesetting formulas. This requires some lines in my `Emacs` file:

@verb|{
       (define-key racket-mode-map (kbd "]") nil)
       (define-key racket-mode-map (kbd ")") nil)
       (define-key racket-mode-map (kbd "}") nil)
       }|


@subpage[1 @elem{Emacs preview inspired by AUCTeX} #:tag "sec:EmacsPreview"]

The additional library
@hyperlink["https://github.com/amkhlv/amkhlv/blob/master/bystroTeX-preview.el"]{bystroTeX-preview.el} provides some rudimentary preview functionality similar to
@hyperlink["http://www.gnu.org/s/auctex/"]{AUCTeX}.

For example, see
@hyperlink["https://github.com/amkhlv/usr/blob/master/lib/emacs/emacs.el"]{my @tt{.emacs} file}
(search for @tt{racket-mode}).







@page["Using BibTeX" #:tag "BibTeX" #:showtitle #t]
You should then @seclink["Installation"]{have started @tt{latex2svg}} with @tt{-Dbibfile=/path/to/your/file.bib}.
Also, you should add in the headers of your @tt{.scrbl} file:

@verb{(require bystroTeX/bibtex)}

Then you get the commands @tt|-{@cite{...}}-| and @tt|-{@bibliography[]}-|. They work as usual, except for:
@itemlist[#:style 'ordered
@item{you should explicitly put square bracket, @italic{e.g.}: @tt|-{[@cite{AuthorA:1989}]}-|}
@item{if you need several citations together, use: @tt|-{[@cite{AuthorA:1989},@cite{AuthorB:1990}]}-|}
]
This is slightly experimental.





@; ---------------------------------------------------------------------------------------------------
@disconnect[formula-database]
@(bystro-close-connection)
 
