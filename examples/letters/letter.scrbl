#lang scribble/base
@(require racket scribble/core scribble/base scribble/html-properties)
@(require "defs.rkt" bystroTeX/common bystroTeX/slides (for-syntax bystroTeX/slides_for-syntax))
@; ---------------------------------------------------------------------------------------------------
@; User definitions:
@(bystro-set-css-dir (build-path 'same "css"))

@(define singlepage-mode #t)
@(bystro-def-formula "formula-enormula-humongula!")

@(require  truques/truques truques/tailwind)

@(define dst (bystro-get-cl-argument "dest"))
@(define to-whom (bystro-get-cl-argument "to_whom"))
@(define address (bystro-get-cl-argument "address"))

@(tw-init)

@tg[div #:attrs ([class "m-20"])]{
@tg[table #:attrs ([border "0"] [width "100%"])
@tg[tr 
    @tg[td #:attrs ([style "text-align:left;"]) 
        @tg[table 
            (for/list ([x (string-split address "\n")]) 
              (tg tr (tg td x)))]
       ]
    @tg[td #:attrs ([style "text-align:right;"])
        @hyperlink["http://www.example.com/"]{Independent Researcher}
        @linebreak[]
        "Remote University"
        @linebreak[]
        @hyperlink["mailto:example@example.com"]|{example@example.com}|
        ]]]

@linebreak[]@linebreak[]

@tg[p #:attrs ([class "text-2xl"])]{Dear @(elem to-whom)! }

@linebreak[]@linebreak[]

please read the enclosed text presenting my idea about the interpretation of the Higgs boson as a wormhole in graphene-lattice.

}
@; ---------------------------------------------------------------------------------------------------
@(bystro-close-connection)
@disconnect[formula-database]

  
