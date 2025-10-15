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


(require racket/base scribble/srcdoc scribble/core scribble/base
         (for-doc scribble/base scribble/manual))
(require bystroTeX/common)

(require "xml.rkt" xml/path xml/xexpr)

(provide
 (proc-doc
  pdq-tags (->i
             ([p path-string?])
             ()
             [result (listof string?)])
  ()))
(define (pdq-tags p)
  (let ([x (file->xexpr p)])
    (se-path*/list '(tag) x)))


