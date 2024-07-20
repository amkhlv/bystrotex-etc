#lang racket

#|
Copyright 2024 Andrei Mikhailov

This file is part of truques.

bystroTeX is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

bystroTeX is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with bystroTeX.  If not, see <http://www.gnu.org/licenses/>.
|#


(require racket/base)
;(require bystroTeX/common)
;(require scribble/core scribble/base scribble/html-properties scribble/decode)

(require yaml json scribble/srcdoc scribble/core scribble/base (for-doc scribble/base scribble/manual))

(provide
 (contract-out
  [multiconf
   (->i
    (
     #:input [input-type (or/c 'dhall 'ncl)]
     )
    (
     [code (listof string?)]
     #:file [file (or/c path-string? #f)]
     #:dir [dir (or/c path-string? #f)]
     #:output [output-type (or/c 'json 'yaml 'type 'dhall 'toml)]
     #:yaml-printer [yaml-printer
                     (or/c #f (-> yaml? block?))]
     #:json-printer [json-printer
                     (or/c #f (-> jsexpr? block?))]
     )
    #:pre/name
    (output-type yaml-printer)
    "cant use yaml-printer since output type is not yaml"
    (unless ((unsupplied-arg? yaml-printer) . or . (eq? output-type 'yaml)) (not yaml-printer))
    #:pre/name
    (output-type json-printer)
    "cant use yaml-printer since output type is not yaml"
    (unless ((unsupplied-arg? json-printer) . or . (eq? output-type 'json)) (not json-printer))
    #:pre/name
    (input-type output-type)
    "invalid output type"
    (cond
      [(eq? input-type 'dhall)
       (or (member output-type '(json yaml type dhall)) (unsupplied-arg? output-type))]
      [(eq? input-type 'ncl)
       (or (member output-type '(json yaml toml)) (unsupplied-arg? output-type))]
      [else #t])
    [result block?])]))

(define  (multiconf
          #:input input-type
          #:file [file #f]
          #:dir [workdir #f]
          #:output [output-type 'yaml]
          #:yaml-printer [yaml-printer #f]
          #:json-printer [json-printer #f]
          .
          code)
  (parameterize
      ([current-directory (workdir . or . (current-directory))])
    (let-values
        ([(proc out in err)
          (apply
           subprocess
           `(
             #f
             #f
             #f
             ,(find-executable-path
               (case input-type
                 ['dhall
                  (case output-type
                    ['yaml "dhall-to-yaml"]
                    ['json "dhall-to-json"]
                    ['dhall "dhall"]
                    ['type "dhall"]
                    )
                  ]
                 ['ncl "nickel"]
                 )
               )
             ,@(if (eq? input-type 'ncl)
                   `("export"
                     "--format"
                     ,(symbol->string output-type)
                     ,@(if file `(,file) '())
                     )
                   '())
             ,@(cond
                 [(eq? output-type 'type) '("type")]
                 [else '()]
                 )
             )
           )
          ])
      (unless file (for ([line code]) (display line in)))
      (close-output-port in)
      (display (port->string err) (current-error-port))
      (close-input-port err)
      (define result
        (cond
          [yaml-printer
           (let ([yml (read-yaml out)]) (yaml-printer yml))]
          [json-printer
           (let ([jsn (read-json out)]) (json-printer jsn))]
          [else
           (verbatim  (port->string out))]
          )
        )
      (close-input-port out)
      result
      )))


