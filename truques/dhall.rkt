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

(require yaml scribble/srcdoc scribble/core scribble/base (for-doc scribble/base scribble/manual))

(provide
 (contract-out
  [dhall
   (->i
    ([code (listof string?)])
    (
     #:dir [dir (or/c path-string? #f)]
     #:output [output-type (or/c 'json 'yaml 'type 'dhall)]
     #:yaml-printer [yaml-printer
                     (output-type)
                     (or/c #f (-> yaml? block?))]
     )
    #:pre/name
    (output-type yaml-printer)
    "cant use yaml-printer since output type is not yaml"
    (unless ((unsupplied-arg? yaml-printer) . or . (eq? output-type 'yaml)) (not yaml-printer))
    [result block?])]))

(define  (dhall
          #:dir [workdir #f]
          #:output [output 'yaml]
          #:yaml-printer [yaml-printer #f]
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
               (case output
                 ['yaml "dhall-to-yaml"]
                 ['json "dhall-to-json"]
                 ['dhall "dhall"]
                 ['type "dhall"]
                 )
               ) 
             ,@(if (eq? output 'type) '("type") '())
             )
           )
          ])
      (for ([line code]) (display line in))
      (close-output-port in)
      (display (port->string err) (current-error-port))
      (close-input-port err)
      (define result
        (if yaml-printer
            (let ([yml (read-yaml out)]) (yaml-printer yml))
            (verbatim  (port->string out)))
        )
      (close-input-port out)
      result
      )))


