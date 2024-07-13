#lang scribble/base
@(require racket scribble/core scribble/base scribble/html-properties)
@(require "defs.rkt" bystroTeX/common bystroTeX/slides (for-syntax bystroTeX/slides_for-syntax))
@; ---------------------------------------------------------------------------------------------------
@; User definitions:
@(bystro-set-css-dir (build-path 'same "css"))

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


@page["Installation Part I" #:tag "Installation" #:showtitle #t]
BystroTeX consists of the frontend (Racket) and backend (Java). The Java part works
like a server. It is actually an HTTP server. It listens on some port on the @tt{localhost}.
We will start with @bold{setting up this server}.

@bystro-local-toc[]

@subpage[1 @elem{Install JDK, SBT and Git} #:tag "sec:JDKEtc"]

To install the server, you will need to install the following things on your computer: 

@itemlist[#:style 'ordered
@item{Java with @hyperlink["https://en.wikipedia.org/wiki/Java_Development_Kit"]{JDK}}
@item{@hyperlink["https://en.wikipedia.org/wiki/Git"]{git}}
          @item{@hyperlink["https://en.wikipedia.org/wiki/SBT_(software)"]{SBT}
                          (it is best installed @italic{via}
                              @hyperlink["https://get-coursier.io/docs/cli-installation"]{Coursier},
                              @tt{cs update cs} then @tt{cs install sbt})}
]

@subpage[1 @elem{Build things} #:tag "sec:Building"]

Now execute the following commands:

@smaller{@tt{git clone https://github.com/amkhlv/LaTeX2SVGServer}}

@smaller{@tt{cd LaTeX2SVGServer}}

@smaller{@tt{sbt assembly}}


This will take some time, as various libraries will have to be downloaded (and saved in @tt{~/.ivy2} and @tt{~/.sbt}).

After that, the following JAR file will appear:

@tt{latex2svgserver.jar}

@subpage[1 @elem{Run} #:tag "sec:Run"]

Our Java server will communicate to the Racket frontend some initial settings 
(including the anti-@hyperlink["https://www.owasp.org/index.php/Cross-Site_Request_Forgery_(CSRF)"]{CSRF} token) 
by writing them into an @tt{XML} file. You have to decide how it should name this file and where to put it.
Suppose that you decided to call it @tt{bystroConf.xml}, and choosen some directory where it will be:

@smaller{@tt{/path/to/bystroConf.xml}}

Under this assumption, start the server by typing the following command:

@tt|{java -DbystroFile=/path/to/bystroConf.xml -Dbibfile=/path/to/yourBibTeXfile.bib -Dhttp.port=11111 -Dhttp.address=127.0.0.1 -jar latex2svgserver.jar}|

(Yes, you need to supply a BibTeX file. It may be empty.)

@comment{
The port number @tt{11111} is also up to you to choose. The frontend will know it because it will be written (among other things) to @tt{/path/to/bystroConf.xml}
}

Now the server is running. 

@comment{
Notice that we specified the option @smaller{@tt{-Dhttp.address=127.0.0.1}}. Therefore the server
is only listening on a local interface (the ``loopback''); 
@hyperlink["http://stackoverflow.com/questions/30658161/server-listens-on-127-0-0-1-do-i-need-firewall"]{it is not possible to connect to it from the outside}.
However, it would be still 
@hyperlink["https://blog.jetbrains.com/blog/2016/05/11/security-update-for-intellij-based-ides-v2016-1-and-older-versions/"]{possible to attack it} 
from a running browser by 
@hyperlink["https://www.owasp.org/index.php/Cross-Site_Request_Forgery_(CSRF)"]{CSRF}.
Our defense is token and custom header. Should CSRF somehow succeed in spite of these measures, 
actually exploiting it would require a vulnerability in 
@hyperlink["https://github.com/opencollab/jlatexmath"]{JLaTeXMath}.
}


@page["Installation Part II" #:tag "Installation2" #:showtitle #t]

Now comes the frontend.

@table-of-contents[]

@subpage[1 @elem{Installing Racket} #:tag "sec:InstallRacket"]

You should start with installing @hyperlink["http://racket-lang.org/"]{@tt{Racket}} on your computer.
For example, on @tt{Debian} you should issue this command @bold{@clr["red"]{as root:}}
@verb{
aptitude install racket
}
This command will install the @tt{Racket} environment on your computer. Now we are ready to
install @tt{bystroTeX}.

@itemlist[
@item{@bold{For Windows users}: @smaller{You will have to manually install the @tt{dll} for the @tt{sqlite3}, please consult the Google}}
]

@subpage[1 @elem{Installing the BystroTeX library} #:tag "sec:BystroLib"]

@bold{@clr["red"]{As a normal user}} (i.e. @bold{@clr["red"]{not}} root), exectute:

@verb|{
git clone https://github.com/amkhlv/amkhlv
cd amkhlv
raco pkg install --link bystroTeX/
}|

@comment{
Now you should be able to read the documentation manual in @tt{bystroTeX/doc/manual/index.html}, but it is not very useful. It is better to just follow examples.
}

@subpage[1 @elem{Installing the BystroTeX executable} #:tag "sec:installing-the-executable"]

@verb|{
cd bystroTeX/
raco exe bystrotex.rkt
}|

This should create the executable file called @tt{bystrotex}. You should copy it to some location on your executable path (maybe @tt{/usr/local/bin/}).

@subpage[1 @elem{Building sample slides} #:tag "sec:BuildingExample"]

Now @spn[attn]{Now go to the sample folder}:

@verb{cd ../examples}

Remember your @tt{/path/to/bystroConf.xml} ? For sample slides to build, you need to symlink it to here:

@verb{ln -s /path/to/bystroConf.xml ./}

@comment{
         Generally speaking, the location of the server configuration file
         is kept in the @tt{bystro-conf} struct which is
         defined in the header of the @tt{.scrbl} file.
         }

Now let us go to the sample slides directory:

@verb{cd bystroTeX_manual}

and proceed to the @seclink["SamplePresentation"]{next slide}...



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
 
